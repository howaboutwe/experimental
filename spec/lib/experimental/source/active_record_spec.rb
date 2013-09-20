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

  describe ".active" do
    it "returns all active experiments" do
      experiment = FactoryGirl.create(:experiment, removed_at: nil, end_date: nil)
      source.active.should == [experiment]
    end

    it "includes experiments that will end in the future" do
      experiment = FactoryGirl.create(:experiment, removed_at: nil, end_date: Time.now.utc + 1.second)
      source.active.should == [experiment]
    end

    it "excludes ended experiments" do
      experiment = FactoryGirl.create(:ended_experiment)
      source.active.should == []
    end

    it "excludes removed experiments" do
      experiment = FactoryGirl.create(:experiment, :removed)
      source.active.should == []
    end
  end
end
