require 'spec_helper'

shared_context "set up in_code experiments" do
  let!(:test_exp_existing) {
    FactoryGirl.create(
      :experiment,
      exp_hash[:in_code][0].merge({ start_date: 1.month.ago })
  )}
  let!(:test_exp_new) { Experimental::Experiment.new }

  before do
    Experimental::Experiment.stub!(:find_by_name).
      with(test_exp1_name).
      and_return(test_exp_existing)

    Experimental::Experiment.stub!(:find_by_name).
      with(test_exp2_name).
      and_return(nil)

    Experimental::Experiment.stub!(:find_by_name).with(:removed_exp).
      and_return(FactoryGirl.create(:experiment))
  end
end

shared_examples_for "syncing new and existing experiments" do
  describe "new/active" do
    include_context "set up in_code experiments"

    it "should update attributes for existing (first) one" do
      test_exp_existing.should_receive(:update_attributes!).with(
        exp_hash[:in_code][0], update_attrs)
      Experimental::Loader.sync
    end

    describe "new (second) experiment" do
      before do
        stub_time
        @attrs = exp_hash[:in_code][1].merge({ start_date: @time })
      end

      it "should call new" do
        Experimental::Experiment.should_receive(:new).and_return(test_exp_new)
        Experimental::Loader.sync
      end

      it "should call update_attributes!" do
        Experimental::Experiment.stub!(:new).and_return(test_exp_new)
        test_exp_new.should_receive(:update_attributes!).with(
          @attrs, update_attrs)
        Experimental::Loader.sync
      end
    end
  end
end

describe Experimental::Loader do
  let(:test_exp1_name) { :test_exp1 }
  let(:test_exp2_name) { :test_exp2 }
  let(:exp_hash) {
    {
      in_code: [
        { name: test_exp1_name, num_buckets: 3, population: :default, notes: "0 is default; 1 is some new thing; 2 is another new thing" },
        { name: test_exp2_name, num_buckets: 2, population: :new_users, notes:  "0 is a, 1 is b" }
      ],
        removed: [
          { name: :removed_exp, num_buckets: 2, notes: "0 is default, 1 is new" }
      ]
    }
  }

  let(:update_attrs) { { without_protection: true } }

  def stub_yaml(h = exp_hash)
    YAML.stub!(:load_file).and_return(h)
  end

  def stub_time
    @time = Time.now
    Time.stub(:now).and_return(@time)
  end

  describe ".sync" do
    context "when good yaml" do
      before do
        stub_yaml
      end

      it_behaves_like "syncing new and existing experiments"

      context "when removing experiments" do
        include_context "set up in_code experiments"

        before do
          @e = FactoryGirl.create(:experiment, exp_hash[:removed][0])
          Experimental::Experiment.stub!(:find_by_name).
            with(:removed_exp).
            and_return(@e)
        end

        context "when removed not set" do
          before do
            stub_time
            @e.stub!(:removed_at).and_return(nil)
          end

          it "should remove the experiment" do
            @e.should_receive(:remove)
            Experimental::Loader.sync
          end
        end

        context "when removed already set" do
          before do
            @e.stub!(:removed_at).and_return(1.month.ago)
          end

          it "should not set the removed_at date" do
            @e.should_not_receive(:remove)
            Experimental::Loader.sync
          end
        end
      end
    end

    context "when bad yaml" do
      let(:bad_exp_hash) { HashWithIndifferentAccess.new.deep_merge(exp_hash) }

      context "when trying to set things you shouldn't" do
        let(:bad_start) { Time.now }

        before do
          bad_exp_hash[:in_code].map! do |e|
            e.merge(
              start_date: bad_start,
              end_date: Time.now.next_month,
              winning_bucket: 3
            )
          end
          stub_yaml(bad_exp_hash)
        end

        it "doesn't alter exp_hash" do
          exp_hash[:in_code][0].has_key?(:start_date).should be_false
        end

        it_behaves_like "syncing new and existing experiments"

        it "doesn't set the start or end date or winning bucket" do
            Experimental::Loader.sync

            last_exp = Experimental::Experiment.in_code.last
            last_exp.start_date.should > bad_start
            last_exp.end_date.should be_nil
            last_exp.winning_bucket.should be_nil
        end
      end
    end
  end
end
