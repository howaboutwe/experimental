require "spec_helper"

describe User do
  include Experimental::RspecHelpers

  let!(:user) { FactoryGirl.create(:user) }
  let!(:experiment_name) { "exp" }
  let!(:experiment_name2) { "exp2" }

  context "when in experiment 1" do
    include_context "in experiment"

    it "doesn't raise an error" do
      expect {
        user.in_experiment?(experiment_name)
      }.to_not raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  context "when in experiment 2" do
    before do
      is_in_experiment(true, experiment_name2)
    end

    it "doesn't raise an error" do
      expect {
        user.in_experiment?(experiment_name2)
      }.to_not raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  context "when not in experiment 1" do
    include_context "in experiment"

    it "doesn't raise an error" do
      expect {
        user.in_experiment?(experiment_name)
      }.to_not raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  context "when not in experiment 2" do
    before do
      is_not_in_experiment(true, experiment_name2)
    end

    it "doesn't raise an error" do
      expect {
        user.in_experiment?(experiment_name2)
      }.to_not raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  context "when in bucket 1" do
    include_context "in experiment bucket 1"

    it "doesn't raise an error" do
      expect {
        user.in_experiment?(experiment_name)
      }.to_not raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  context "when in bucket 0" do
    include_context "in experiment bucket 0"

    it "doesn't raise an error" do
      expect {
        user.in_experiment?(experiment_name)
      }.to_not raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

end
