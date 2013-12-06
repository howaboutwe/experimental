require 'spec_helper'

describe Experimental::Loader do
  before { Experimental.reset }
  after { Experimental.reset }

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

    it "logs it" do
      loader.sync
      log.string.should include('creating aa')
    end
  end

  context "when the attributes of an existing experiment have changed" do
    before do
      FactoryGirl.create(:experiment, name: 'aa', num_buckets: 5, population: 'a')
      Experimental.experiment_data = {'aa' => {'num_buckets' => 4}}
    end

    it "updates the experiment" do
      loader.sync
      experiments = Experimental::Experiment.all
      experiments.map(&:name).should == ['aa']
      experiments.map(&:num_buckets).should == [4]
      experiments.map(&:population).should == [nil]
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
