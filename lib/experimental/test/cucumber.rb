require 'experimental/test'

Experimental::Test.initialize
Before { Experimental::Test.setup }
World(Experimental::Test)
