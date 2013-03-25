require "spec_helper"

describe Experimental::Population::Filter do
  describe ".find_population" do
    it "returns the filter class matching the given" do
      Experimental::Experiment.find_population(:new_users).should == Experimental::Population::NewUsers
    end

    it "returns the default if nil is given" do
      Experimental::Experiment.find_population(nil).should == Experimental::Population::Default
    end

    it "returns the default if a blank string is given" do
      Experimental::Experiment.find_population(' ').should == Experimental::Population::Default
    end

    it "returns a custom population filter registered with the given name" do
      filter_class = Class.new
      Experimental::Experiment.register_population_filter(:custom, filter_class)
      begin
        Experimental::Experiment.find_population(:custom).should equal(filter_class)
      ensure
        Experimental::Experiment.reset_population_filters
      end
    end

    it "returns nil if an unregistered name is given" do
      Experimental::Experiment.find_population('unregistered').should be_nil
    end
  end
end
