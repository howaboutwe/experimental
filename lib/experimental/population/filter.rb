module Experimental
  module Population
    module Filter
      def self.extended(base)
        base.reset_population_filters
      end

      def find_population(name)
        if name.blank?
          Experimental::Population::Default
        else
          filter_classes[name.to_s]
        end
      end

      def register_population_filter(name, filter_class)
        filter_classes[name.to_s] = filter_class
      end

      def reset_population_filters
        filter_classes.clear
        register_population_filter(:new_users, NewUsers)
        register_population_filter(:default, Default)
      end

      private

      def filter_classes
        @filter_classes ||= {}
      end
    end
  end
end
