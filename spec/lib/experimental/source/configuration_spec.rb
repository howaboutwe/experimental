require 'spec_helper'

describe Experimental::Source::Configuration do
  let(:a) { {'num_buckets' => 2} }
  let(:b) { {'num_buckets' => 3} }
  let(:source) { Experimental::Source::Configuration.new }

  before { Experimental.experiment_data = {'a' => a, 'b' => b} }
  after { Experimental.reset }

  describe "#[]" do
    it "returns the experiment with the given name" do
      source['a'].name.should == 'a'
    end

    it "accepts symbol names" do
      source[:a].name.should == 'a'
    end

    it "returns nil if no such experiment exists" do
      source['x'].should be_nil
    end
  end

  describe ".available" do
    it "returns all available experiments" do
      source.available.map(&:name).should == ['a', 'b']
      source.available.map(&:num_buckets).should == [2, 3]
    end
  end
end
