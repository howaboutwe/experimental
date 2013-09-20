module Experimental
  module Source
    class Cache < Base
      # A cache source provides in memory caching around another source.
      #
      # If a +:ttl+ option is passed, experiments will only be cached for that
      # many seconds, otherwise it is cached forever.
      def initialize(source, options = {})
        @source = source
        @ttl = options[:ttl]
        @last_update = nil
        @cache = {}
      end

      attr_reader :source, :ttl

      def [](name)
        refresh if dirty?
        cache[name]
      end

      def active
        refresh if dirty?
        cache.values
      end

      private

      attr_accessor :cache, :last_update

      def dirty?
        return true if last_update.nil?
        ttl ? (Time.now.to_f - last_update > ttl) : false
      end

      def refresh
        cache.clear
        source.active.each do |experiment|
          cache[experiment.name] = experiment
        end
        self.last_update = Time.now.to_f
      end
    end
  end
end
