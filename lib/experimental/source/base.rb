module Experimental
  module Source
    class Base
      # Return the experiment with the given name (Symbol or String)
      def [](name)
        raise NotImplementedError, 'abstract'
      end

      # Return all non-removed experiments.
      def available
        raise NotImplementedError, 'abstract'
      end
    end
  end
end
