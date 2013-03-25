require "spec_helper"

describe Experimental::Population::Filter do
  describe ".find_population" do
    it "returns the filter class matching the given" do
      Experimental::Experiment.find_population(:new_users).should == Experimental::Population::NewUsers
    end

    it "returns the default if nil is given" do
      Experimental::Experiment.find_population(nil).should == Experimental::Population::Default
    end
  end
end
