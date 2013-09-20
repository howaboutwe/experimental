require 'spec_helper'

describe Experimental do
  before { Experimental.reset }
  after { Experimental.reset }

  describe ".register_population_filter" do
    it "registers the given population filter class" do
      klass = Class.new
      Experimental.register_population_filter(:custom, klass)
      Experimental::Experiment.find_population(:custom).should equal(klass)
    end
  end

  describe ".configure" do
    it "wraps the source in a cache with the given ttl if 'cache_for' is given" do
      Experimental.configure('cache_for' => 300)
      Experimental.source.should be_a(Experimental::Source::Cache)
      Experimental.source.source.should be_a(Experimental::Source::ActiveRecord)
      Experimental.source.ttl.should == 300
    end
  end
end
