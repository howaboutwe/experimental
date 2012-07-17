require 'spec_helper'

shared_context "get experiment after" do
  after do
    cache.get(experiment_name)
  end
end

shared_context "get experiment before" do
  before do
    @experiment = cache.get(experiment_name)
  end
end

shared_context "stub current time" do
  before do
    @time = Time.now
    Time.stub(:now).and_return(@time)
  end
end

shared_examples_for "correct experiment" do
  it "should return an experiment" do
    @experiment.is_a?(Experimental::Experiment).should be_true
  end

  it "should return the correct experiment" do
    @experiment.name.should == experiment_name
  end
end

shared_examples_for "gets the correct experiment" do
  describe "gets the correct experiment" do
    include_context "get experiment before"
    it_behaves_like "correct experiment"
  end
end

shared_examples_for "gets cache key" do
  it "should get the cache key" do
    cache_should_receive_fetch
  end
end

shared_examples_for "doesn't get experiments from db" do
  it "should not get all experiments" do
    Experimental::Experiment.should_not_receive(:in_code)
  end
end

describe Experimental::Cache do
  let(:cache) { Experimental::Cache }
  let(:experiment_name) { "name" }
  let(:cache_key) { Experimental::Cache.cache_key }

  def stub_interval(val = false)
    cache.stub!(:within_interval?).and_return(val)
  end

  def stub_update(val = false)
    cache.stub!(:need_update?).and_return(val)
  end

  def cache_should_receive_fetch(return_val = nil)
    Rails.cache.should_receive(:fetch).
      with(cache_key, { :race_condition_ttl => 10}).
      tap { |o| o.and_return(return_val) unless return_val.nil? }
  end

  describe "setting up state" do
    describe "interval" do
      after do
        cache.interval = nil
      end

      it "should default to 5 minutes" do
        cache.interval = nil
        cache.interval.should == 5.minutes
      end

      it "should return value set externally" do
        cache.interval = 1.minute
        cache.interval.should == 1.minute
      end
    end

    describe "within interval" do
      it "should initially return false" do
        cache.within_interval?.should be_false
      end

      it "should return false if it's set greater than interval" do
        cache.stub!(:last_check).and_return(6.minutes.ago)
        cache.within_interval?.should be_false
      end

      it "should return true if it's in the interval" do
        cache.stub!(:last_check).and_return(2.minutes.ago)
        cache.within_interval?.should be_true
      end
    end

    describe "need update?" do
      describe "last_update is nil" do
        include_context "stub current time"

        before do
          cache.stub!(:experiments).and_return({})
        end

        it "should initially return true" do
          cache.need_update?(@time).should be_true
        end

        it "should set last_update to time" do
          (cache.last_update - @time).should <= 0
        end
      end

      describe "experiment is nil" do
        before do
          Experimental::Cache.stub(:experiments).and_return(nil)
          cache.stub!(:last_update).and_return(Time.now.next_month)
        end

        it "should initially return true" do
          cache.need_update?(Time.now).should be_true
        end
      end

      describe "normal behavior" do
        before do
          cache.stub!(:experiments).and_return({})
          @time = Time.now
        end

        it "should return false if last update is equal to the new update time" do
          cache.stub!(:last_update).and_return(@time)
          cache.need_update?(@time).should be_false
        end

        it "should return false if last update is after the new update time" do
          cache.stub!(:last_update).and_return(Time.now.next_month)
          cache.need_update?(@time).should be_false
        end

        it "should return true if last update is prior to the new update time" do
          cache.stub!(:last_update).and_return(10.minutes.ago)
          cache.need_update?(@time).should be_true
        end
      end
    end

    describe "last check" do
      include_context "stub current time"

      it "should initially be 1 minute less the interval" do
        (cache.last_check - (@time - 6.minutes)).should <= 0
      end
    end
  end

  describe "converting experiment to hash" do
    before do
      Experimental::Experiment.create name: experiment_name, num_buckets: 2
      Experimental::Experiment.create name: "#{experiment_name}_1", num_buckets: 2
      @experiments = cache.experiments_to_hash(Experimental::Experiment.all)
    end

    it "should return a hash" do
      @experiments.is_a?(Hash).should be_true
    end

    it "should have 2 items" do
      @experiments.size.should == 2
    end

    describe "experiment" do
      before do
        @experiment = @experiments[experiment_name]
      end

      it_behaves_like "correct experiment"
    end
  end

  describe "getting from cache" do
    before do
      cache.stub!(:experiments_to_hash).and_return({
        "#{experiment_name}".to_sym =>
          FactoryGirl.create(:experiment, name: experiment_name)
      })
    end

    describe "using [] to access" do
      before do
        stub_interval
        stub_update(true)
        @experiment = cache[experiment_name]
      end

      it_behaves_like "correct experiment"
    end

    describe "interval has passed" do
      before do
        stub_interval
      end

      describe "update is needed" do
        before do
          stub_update(true)
        end

        it_behaves_like "gets the correct experiment"

        describe "calling methods" do
          include_context "get experiment after"
          it_behaves_like "gets cache key"

          it "should get all experiments" do
            Experimental::Experiment.should_receive(:in_code)
          end

          it "should convert experiments to a hash" do
            cache.should_receive(:experiments_to_hash)
          end
        end
      end

      describe "update is not needed" do
        before do
          stub_update
        end

        it_behaves_like "gets the correct experiment"

        describe "calling methods" do
          include_context "get experiment after"
          it_behaves_like "gets cache key"
          it_behaves_like "doesn't get experiments from db"
        end
      end
    end

    describe "within interval" do
      before do
        stub_interval(true)
      end

      it_behaves_like "gets the correct experiment"

      describe "calling methods" do
        include_context "get experiment after"

        it "should not get the cache key" do
          Rails.cache.should_not_receive(:fetch).with(cache_key)
        end

        it_behaves_like "doesn't get experiments from db"
      end
    end

    describe "expire last updated" do
      it "should call delete on Rails cache" do
        Rails.cache.should_receive(:delete).with(cache_key)
        cache.expire_last_updated
      end
    end
  end
end
