require 'spec_helper'

describe Experimental::Loader do
  before { Experimental.reset }
  after { Experimental.reset }

  before { Timecop.freeze(Time.utc(2001, 2, 3, 4, 5, 6)) }
  after { Timecop.return }

  let(:log) { StringIO.new }
  let(:loader) { Experimental::Loader.new(logger: Logger.new(log)) }

  context "when a new experiment is configured" do
    before { Experimental.experiment_data = {'aa' => {'num_buckets' => 5}} }

    it "creates the experiment with the given attributes" do
      loader.sync
      experiments = Experimental::Experiment.all
      experiments.map(&:name).should == ['aa']
      experiments.map(&:num_buckets).should == [5]
    end

    it "starts the experiment by default" do
      loader.sync
      experiment = Experimental::Experiment.all.first
      experiment.should be_started
      experiment.start_date.should == Time.now.utc
    end

    it "creates an unstarted experiment if unstarted is set" do
      Experimental.experiment_data['aa']['unstarted'] = true
      loader.sync
      experiment = Experimental::Experiment.all.first
      experiment.should_not be_started
    end

    it "logs it" do
      loader.sync
      log.string.should include('creating aa')
    end
  end

  context "when the attributes of an existing experiment have changed" do
    let!(:experiment) do
      FactoryGirl.create(:experiment, name: 'aa', num_buckets: 5, population: 'a')
    end

    before do
      Experimental.experiment_data = {'aa' => {'num_buckets' => 4}}
    end

    it "updates the experiment" do
      loader.sync
      experiments = Experimental::Experiment.all
      experiments.map(&:name).should == ['aa']
      experiments.map(&:num_buckets).should == [4]
      experiments.map(&:population).should == [nil]
    end

    it "does not update the start time if it's already started" do
      original_start_date = 1.day.ago
      experiment.update_attribute(:start_date, original_start_date)

      loader.sync

      experiment = Experimental::Experiment.all.first
      experiment.should be_started
      experiment.start_date.should == original_start_date
    end

    it "starts the experiment by default if necessary" do
      experiment.unstart
      loader.sync
      experiment = Experimental::Experiment.all.first
      experiment.should be_started
      experiment.start_date.should == Time.current
    end

    it "creates an unstarted experiment if unstarted is set" do
      Experimental.experiment_data['aa']['unstarted'] = true
      loader.sync
      experiment = Experimental::Experiment.all.first
      experiment.should_not be_started
    end

    it "logs it" do
      loader.sync
      log.string.should include('updating aa')
    end
  end

  context "when an experiment has been removed from the configuration" do
    before { FactoryGirl.create(:experiment, name: 'aa', num_buckets: 5) }

    it "marks the experiment as removed" do
      loader.sync
      experiments = Experimental::Experiment.all
      experiments.map(&:name).should == ['aa']
      experiments.map(&:removed?).should == [true]
    end

    it "logs it" do
      loader.sync
      log.string.should include('removing aa')
    end

    it "does not update already-removed experiments" do
      removed = FactoryGirl.create(:experiment, :removed)
      original_attributes = removed.attributes
      Timecop.travel(1.day.from_now) do
        loader.sync
      end
      removed.reload
      removed.attributes.should == original_attributes
    end
  end
end
