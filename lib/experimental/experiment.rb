module Experimental
  class Experiment < ActiveRecord::Base
    extend Population::Filter

    if ActiveRecord::VERSION::MAJOR < 4 || defined?(ProtectedAttributes)
      attr_accessible :name, :num_buckets, :notes, :population
    end

    validates_presence_of :name, :num_buckets
    validates_numericality_of :num_buckets, :greater_than_or_equal_to => 1
    validates_numericality_of :winning_bucket,
      :greater_than_or_equal_to => 0,
      :less_than => :num_buckets,
      :if => :ended?
    validate :validate_dates

    def self.in_code
      where(:removed_at => nil)
    end

    def self.unstarted
      where(start_date: nil)
    end

    def self.in_progress
      where('start_date is not null and end_date is null and removed_at is null').
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
      elsif started?
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

    def unstart
      self.start_date = nil
      self.end_date = nil
      self.removed_at = nil
      self.winning_bucket = nil
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
        result = update_attribute(:removed_at, Time.now)
      end

      result
    end

    def removed?
      !removed_at.nil?
    end

    def started?
      start_date.present? && start_date <= Time.now
    end

    def ended?
      !end_date.nil? && Time.now > end_date
    end

    def active?
      !removed? && started? && !ended?
    end

    def self.available
      where(removed_at: nil)
    end

    def self.active
      now = Time.now
      available.where('start_date < ? AND end_date IS NULL OR ? <= end_date', now, now)
    end

    def to_mysql_formula(subject_table = "users")
      "CONV(SUBSTR(MD5(CONCAT(\"#{name}\",#{subject_table}.id)),1,8),16,10) % #{num_buckets}"
    end

    def to_postgres_formula(subject_table = "users")
      "('x'||substr(md5('#{name}'||#{subject_table}.id),1,8))::bit(32)::bigint % #{num_buckets}"
    end

    def bucket_number(subject)
      top_8 = Digest::MD5.hexdigest("#{name}#{subject.experiment_seed_value}")[0..7]
      top_8.to_i(16) % num_buckets
    end

    private

    def validate_dates
      validate_date 'start_date'
      validate_date 'end_date'
    end

    def validate_date(attribute)
        value = read_attribute_before_type_cast(attribute)
        return if value.blank?
        begin
          return if value.to_time
        rescue ArgumentError
        end
        errors.add(attribute, "is not a valid date")
    end

    def population_filter
      @population_filter ||= self.class.find_population(population)
    end
  end
end
