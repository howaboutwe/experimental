module Experimental
  class Experiment < ActiveRecord::Base
    extend Population::Filter

    cattr_accessor :use_cache
    @@use_cache = true

    attr_accessible :name, :num_buckets, :notes, :population

    validates_presence_of :name, :num_buckets
    validates_numericality_of :num_buckets, :greater_than_or_equal_to => 2
    validates_numericality_of :winning_bucket,
      :greater_than_or_equal_to => 0,
      :less_than => :num_buckets,
      :if => :ended?

    after_create :expire_cache

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
      if use_cache
        Cache.get(experiment_name)
      else
        find_by_name(experiment_name.to_s)
      end
    end

    def self.expire_cache
      Cache.expire_last_updated if use_cache
    end

    def expire_cache
      Experiment.expire_cache
    end

    def bucket(subject)
      (ended? || removed?) ? winning_bucket : bucket_number(subject)
    end

    def in?(subject)
      return false if removed?
      population_filter.in?(subject, self)
    end

    def end(winning_num)
      self.winning_bucket = winning_num
      self.end_date = Time.now
      result = save

      Experiment.expire_cache if result

      result
    end

    def restart
      return unless ended?

      self.winning_bucket = nil
      self.end_date = nil

      save
    end

    def remove
      result = false

      unless removed?
        result = update_attributes(
          { removed_at: Time.now }, without_protection: true
        )
        expire_cache if result
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

    def self.active
      where(['removed_at IS NULL AND (end_date IS NULL OR ? <= end_date)', Time.now])
    end

    def to_sql_formula(subject_table = "users")
      "CONV(SUBSTR(SHA1(CONCAT(\"#{name}\",#{subject_table}.id)),1,8),16,10) % #{num_buckets}"
    end

    def bucket_number(subject)
      top_8 = Digest::SHA1.hexdigest("#{name}#{subject.id}")[0..7]
      top_8.to_i(16) % num_buckets
    end

    private

    def population_filter
      @population_filter ||= self.class.find_population(population)
    end
  end
end
