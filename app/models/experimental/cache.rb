module Experimental
  class Cache
    cattr_accessor :interval
    cattr_reader :last_check
    cattr_reader :last_update
    cattr_reader :experiments
    cattr_accessor :cache_race_condition_ttl
    @@cache_race_condition_ttl = 10
    cattr_accessor :cache_key

    class << self
      def get(name)
        unless within_interval?
          if need_update?(last_cached_update)
            @@experiments = experiments_to_hash(Experiment.in_code)
            @@last_update = Time.now
          end
        end
        experiments[name.to_sym]
      end

      def [](name)
        get(name)
      end

      def interval
        @@interval ||= 5.minutes
      end

      def last_check
        @@last_check ||=
          Time.now - interval - 1.minute
      end

      def last_update
        @@last_update ||= last_cached_update
      end

      def cache_key
        @@cache_key ||= "experiments_last_update"
      end

      def within_interval?
        (Time.now - last_check) < interval
      end

      def need_update?(last_cached_update_time)
        experiments.nil? || last_update < last_cached_update_time
      end

      def experiments_to_hash(experiments)
        HashWithIndifferentAccess.new.tap do |h|
          experiments.each { |e| h[e.name.to_sym] = e }
        end
      end

      def last_cached_update
        # setting a default to 1 minute ago will force all servers to update
        Rails.cache.fetch(cache_key, :race_condition_ttl => cache_race_condition_ttl ) do
          Experiment.last_updated_at || 1.minute.ago
        end
      end

      def expire_last_updated
        Rails.cache.delete(cache_key)
      end
    end
  end
end
