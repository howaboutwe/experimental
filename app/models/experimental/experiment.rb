module Experimental
  class Experiment < ActiveRecord::Base
    extend Population::Filter

    attr_accessible :name, :num_buckets, :notes, :population


    validates_presence_of :name, :num_buckets
    validates_numericality_of :num_buckets, :greater_than_or_equal_to => 1
    validates_numericality_of :winning_bucket,
      :greater_than_or_equal_to => 0,
      :less_than => :num_buckets,
      :if => :ended?
    validate :has_valid_dates

    def self.in_code
      where(:removed_at => nil)
    end

    def self.in_progress
      where('removed_at is null and end_date is null').
        order('start_date desc').
        order(:name)
    end

    def self.ended_or_removed
      where('removed_at is not null or end_date is not null').
        order(:removed_at).
        order('end_date desc')
    end

    def self.last_updated_at
      maximum(:updated_at)
    end

    def self.[](experiment_name)
      Experimental.source[experiment_name.to_s]
    end

    def bucket(subject)
      if ended? || removed?
        winning_bucket
      elsif Experimental.overrides.include?(subject, name)
        Experimental.overrides[subject, name]
      else
        bucket_number(subject)
      end
    end

    def in?(subject)
      if removed?
        false
      elsif Experimental.overrides.include?(subject, name)
        !!Experimental.overrides[subject, name]
      else
        population_filter.in?(subject, self)
      end
    end

    def end(winning_num)
      self.winning_bucket = winning_num
      self.end_date = Time.now
      save
    end

    def restart
      return unless ended?

      self.winning_bucket = nil
      self.start_date = Time.now
      self.end_date = nil
      self.removed_at = nil

      save
    end

    def remove
      result = false

      unless removed?
        result = update_attributes(
          { removed_at: Time.now }, without_protection: true
        )
      end

      result
    end

    def removed?
      !removed_at.nil?
    end

    def ended?
      !end_date.nil? && Time.now > end_date
    end

    def active?
      !removed? && !ended?
    end

    def self.available
      where(removed_at: nil)
    end

    def self.active
      available.where(['end_date IS NULL OR ? <= end_date', Time.now])
    end

    def to_sql_formula(subject_table = "users")
      "CONV(SUBSTR(SHA1(CONCAT(\"#{name}\",#{subject_table}.id)),1,8),16,10) % #{num_buckets}"
    end

    def bucket_number(subject)
      top_8 = Digest::SHA1.hexdigest("#{name}#{subject.experiment_seed_value}")[0..7]
      top_8.to_i(16) % num_buckets
    end

    private

    def has_valid_dates
      %w(start_date end_date).each do |attribute|
        value = read_attribute_before_type_cast(attribute)
        begin
          value.try(:to_time)
        rescue ArgumentError
          errors.add(attribute, "is not a valid date")
        end
      end
    end

    def population_filter
      @population_filter ||= self.class.find_population(population)
    end
  end
end
