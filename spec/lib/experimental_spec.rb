require 'spec_helper'

describe Experimental do
  describe ".register_population_filter" do
    after { Experimental::Experiment.reset_population_filters }

    it "registers the given population filter class" do
      klass = Class.new
      Experimental.register_population_filter(:custom, klass)
      Experimental::Experiment.find_population(:custom).should equal(klass)
    end
  end
end
