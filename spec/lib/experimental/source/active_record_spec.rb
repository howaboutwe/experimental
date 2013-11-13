require 'spec_helper'

describe Experimental::Source::ActiveRecord do
  let(:source) { Experimental::Source::ActiveRecord.new }

  describe "#[]" do
    it "returns the experiment with the given name" do
      experiment = FactoryGirl.create(:experiment, name: 'e')
      source['e'].should == experiment
    end

    it "accepts symbol names" do
      experiment = FactoryGirl.create(:experiment, name: 'e')
      source[:e].should == experiment
    end

    it "returns nil if no such experiment exists" do
      source['e'].should be_nil
    end
  end

  describe ".available" do
    it "returns all non-removed experiments" do
      experiment = FactoryGirl.create(:experiment, removed_at: nil, end_date: nil)
      source.available.should == [experiment]
    end

    it "includes ended experiments" do
      experiment = FactoryGirl.create(:ended_experiment)
      source.available.should == [experiment]
    end

    it "excludes removed experiments" do
      experiment = FactoryGirl.create(:experiment, :removed)
      source.available.should == []
    end
  end
end
