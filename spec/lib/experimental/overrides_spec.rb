require 'spec_helper'

describe Experimental::Overrides do
  let(:overrides) { Experimental::Overrides.new }
  let(:subject) { Object.new }

  describe "#include?" do
    it "is false if the given subject has not been overriden in the named experiment" do
      overrides.include?(subject, :my_experiment).should be_false
    end

    it "is true if the given subject has been overriden in the named experiment" do
      overrides[subject, :my_experiment] = 1
      overrides.include?(subject, :my_experiment).should be_true
    end

    it "is true even if the override was set to nil (meaning not in experiment)" do
      overrides[subject, :my_experiment] = nil
      overrides.include?(subject, :my_experiment).should be_true
    end
  end

  describe "#[]" do
    it "returns nil if no override has been set" do
      overrides[subject, :my_experiment] = nil
      overrides[subject, :my_experiment].should be_nil
    end

    it "returns the bucket number if a bucket was set" do
      overrides[subject, :my_experiment] = 1
      overrides[subject, :my_experiment].should == 1
    end
  end

  describe "#reset" do
    it "clears the overrides" do
      overrides[subject, :my_experiment] = 1
      overrides.include?(subject, :my_experiment).should be_true

      overrides.reset
      overrides.include?(subject, :my_experiment).should be_false
    end
  end
end
