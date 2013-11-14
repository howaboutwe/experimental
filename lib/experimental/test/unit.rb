module Experimental
  module Test
    module Unit
      include Test

      def self.included(base)
        Test.initialize
      end

      def setup
        Test.setup
        super
      end
    end
  end
end
