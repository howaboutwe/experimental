module Experimental
  module Population
    module Filter
      def find_population(name)
        p = nil
        klass = name.to_s.camelize
        if name && Experimental::Population.const_defined?(klass)
          p = Experimental::Population.const_get klass
        end
        p || Experimental::Population::Default
      end
    end
  end
end
