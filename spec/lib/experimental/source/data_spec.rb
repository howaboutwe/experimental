require 'spec_helper'

describe Experimental::Source::Data do
  let(:a) { {'name' => 'a', 'num_buckets' => 2} }
  let(:b) { {'name' => 'b', 'num_buckets' => 2} }
  let(:source) { Experimental::Source::Data.new([a, b]) }

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

  describe ".active" do
    it "returns all active experiments" do
      source.active.map(&:name).should == ['a', 'b']
    end
  end
end
