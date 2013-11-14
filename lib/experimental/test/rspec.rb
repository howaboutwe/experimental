module Experimental
  module Test
    module RSpec
      include Test

      def self.included(base)
        Test.initialize
        base.before(:each) { Test.setup }
      end
    end
  end
end
