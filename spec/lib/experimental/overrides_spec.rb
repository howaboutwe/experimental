require 'spec_helper'

TestSubject = ImmutableStruct.new(:experiment_seed_value)

describe Experimental::Overrides do
  let(:overrides) { Experimental::Overrides.new }
  let(:subject) { TestSubject.new(experiment_seed_value: 1) }

  describe "#include?" do
    it "is false if the given subject has not been overriden in the named experiment" do
      overrides.include?(subject, :my_experiment).should be_falsey
    end

    it "is true if the given subject has been overriden in the named experiment" do
      overrides[subject, :my_experiment] = 1
      overrides.include?(subject, :my_experiment).should be_truthy
    end

    it "is true even if the override was set to nil (meaning not in experiment)" do
      overrides[subject, :my_experiment] = nil
      overrides.include?(subject, :my_experiment).should be_truthy
    end

    it "is true if a default is set" do
      overrides.set_default(1)
      overrides.include?(subject, :my_experiment).should be_truthy
    end

    it "is true even if the default is set to nil" do
      overrides.set_default(nil)
      overrides.include?(subject, :my_experiment).should be_truthy
    end
  end

  describe "#[]" do
    it "returns nil if no override or default has been set" do
      overrides[subject, :my_experiment] = nil
      overrides[subject, :my_experiment].should be_nil
    end

    it "returns the default if present and no override has been set" do
      overrides.set_default(1)
      overrides[subject, :my_experiment].should == 1
    end

    it "returns the bucket number if a bucket was set" do
      overrides[subject, :my_experiment] = 1
      overrides[subject, :my_experiment].should == 1
    end

    it "returns the bucket number, even if nil and a non-nil default is set" do
      overrides.set_default(1)
      overrides[subject, :my_experiment] = nil
      overrides[subject, :my_experiment].should be_nil
    end

    it "favors an explicit bucket over the default" do
      overrides.set_default(1)
      overrides[subject, :my_experiment] = 2
      overrides[subject, :my_experiment].should == 2
    end
  end

  describe "#reset" do
    it "clears the overrides" do
      overrides[subject, :my_experiment] = 1
      overrides.include?(subject, :my_experiment).should be_truthy

      overrides.reset
      overrides.include?(subject, :my_experiment).should be_falsey
    end
  end
end
