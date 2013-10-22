module Experimental
  module Source
    class Base
      # Return the experiment with the given name (Symbol or String)
      def [](name)
        raise NotImplementedError, 'abstract'
      end

      # Return all active experiments.
      def active
        raise NotImplementedError, 'abstract'
      end
    end
  end
end
