module Experimental
  module RspecHelpers
    extend ActiveSupport::Concern

    def is_in_experiment(val = true, name = nil, obj = nil)
      obj ||= user
      name ||= experiment_name

      obj.should_receive(:in_experiment?).any_number_of_times.
        with(name).and_return(val)
    end

    def is_not_in_experiment(name = nil, obj = nil)
      obj ||= user
      name ||= experiment_name

      is_in_experiment(false, name, obj)
    end

    def has_experiment_bucket(bucket, name = nil, obj = nil)
      obj ||= user
      name ||= experiment_name

      obj.should_receive(:experiment_bucket).any_number_of_times.
        with(name).and_return(bucket)
    end
  end

  module ClassMethods
    shared_context "in experiment" do
      before do
        is_in_experiment
      end
    end

    shared_context "not in experiment" do
      before do
        is_not_in_experiment
      end
    end

    shared_context "in experiment bucket 1" do
      include_context "in experiment"
      before do
        has_experiment_bucket(1)
      end
    end

    shared_context "in experiment bucket 0" do
      include_context "in experiment"
      before do
        has_experiment_bucket(0)
      end
    end
  end
end
