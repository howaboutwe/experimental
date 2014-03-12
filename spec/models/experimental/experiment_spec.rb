require 'spec_helper'

shared_examples_for "user should be in experiment" do
  it "should say the user is in the experiment" do
    experiment.in?(u).should be_true
  end
end

shared_examples_for "user should not be in experiment" do
  it "should say the user is not in the experiment" do
    experiment.in?(u).should be_false
  end
end

shared_examples_for "user should be in bucket 0(a)" do
   it "should put the user in the 0(a) bucket" do
     experiment.bucket(u).should == 0
   end
end

shared_examples_for "user should be in bucket 1(b)" do
   it "should put the user in the 1(b) bucket" do
     experiment.bucket(u).should == 1
   end
end

shared_examples_for "user should be in bucket 2(c)" do
   it "should put the user in the 2(c) bucket" do
     experiment.bucket(u).should == 2
   end
end

shared_examples_for "first user" do
  describe "first user" do
    let(:u) { FactoryGirl.create(:user, user_options.merge(id: 1)) }
    it_behaves_like "user should be in bucket 0(a)"
    it_behaves_like "user should be in experiment"
  end
end

shared_examples_for "second user" do
  describe "second user" do
    let(:u) { FactoryGirl.create(:user, id: 2) }
    it_behaves_like "user should be in bucket 1(b)"
    it_behaves_like "user should be in experiment"
  end
end

shared_examples_for "third user" do
  describe "third user" do
    let(:u) { FactoryGirl.create(:user, id: 3) }
    it_behaves_like "user should be in bucket 2(c)"
    it_behaves_like "user should be in experiment"
  end
end

describe Experimental::Experiment do
  let(:user) { FactoryGirl.create(:user) }
  let(:experiment) { FactoryGirl.create(:experiment) }

  def stub_sha1(result, name = "test", id = nil)
    id ||= result+1
    Digest::SHA1.stub!(:hexdigest).with("#{name}#{id}").and_return(result.to_s)
  end

  def set_winning_bucket_and_check_validity(bucket_val, valid)
    e.winning_bucket = bucket_val
    e.valid?.should == valid
  end

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:num_buckets) }

  it { should validate_numericality_of(:num_buckets) }
  it { should_not allow_value(-1).for(:num_buckets) }
  it { should_not allow_value(0).for(:num_buckets) }
  it { should allow_value(1).for(:num_buckets) }
  [:start_date,:end_date].each do |attr|
    it { should_not allow_value('bad').for(attr) }
    it { should allow_value('2014-01-01 10:00:00').for(attr) }
    it { should allow_value(Time.now).for(attr) }
  end

  describe "scopes" do
    let(:exp_not_removed) { FactoryGirl.create(:experiment) }
    let(:exp_in_progress) { FactoryGirl.create(:experiment,  name: 'in progress' ) }
    let(:exp_ended) { FactoryGirl.create(:experiment,  name: 'ended', end_date: Date.today, winning_bucket:0) }
    let(:exp_removed) { FactoryGirl.create(:experiment,
                          name: 'removed',
                          winning_bucket:0,
                          end_date: Date.today,
                          removed_at: Date.today) }

    describe "#in_code" do
      it "should return only the not ended experiment" do
        Experimental::Experiment.in_code.should == [exp_not_removed]
      end
    end

    describe "#in_progress" do
      it "should return only the not ended experiment" do
        Experimental::Experiment.in_progress.should == [exp_in_progress]
      end
    end

    describe "#ended_or_removed" do
      it "should return only the not ended experiment" do
        Experimental::Experiment.ended_or_removed.should == [exp_ended, exp_removed]
      end
    end

  end

  describe "#to_sql_formula" do
    it "returns correct sql fragment for users table" do
      Experimental::Experiment.stub(:find, 1).and_return(
        FactoryGirl.create(:experiment, id: 1, name: "experiment", num_buckets: 2)
      )

      Experimental::Experiment.find(1).to_sql_formula.should ==
        "CONV(SUBSTR(SHA1(CONCAT(\"experiment\",users.id)),1,8),16,10) % 2"
    end

    it "returns correct sql fragment for someother table" do
      Experimental::Experiment.stub(:find, 1).and_return(
        FactoryGirl.create(:experiment, id: 1, name: "experiment", num_buckets: 2)
      )

      Experimental::Experiment.find(1).to_sql_formula("someother").should ==
        "CONV(SUBSTR(SHA1(CONCAT(\"experiment\",someother.id)),1,8),16,10) % 2"
    end
  end

  describe "validation of winning bucket" do
    let(:e) { FactoryGirl.build(:experiment) }

    context "when no end date" do
      it { e.should_not validate_numericality_of(:winning_bucket) }
    end

    context "when has end date" do
      before do
        e.end_date = Time.now
      end

      it { e.should validate_numericality_of(:winning_bucket) }

      it "should be invalid if bucket is not set" do
        set_winning_bucket_and_check_validity(nil, false)
      end

      it "should be invalid if bucket is less than 0" do
        set_winning_bucket_and_check_validity(-1, false)
      end

      it "should be valid if is 0" do
        set_winning_bucket_and_check_validity(0, true)
      end

      it "should be valid if bucket is 1" do
        set_winning_bucket_and_check_validity(1, true)
      end

      it "should be invalid if bucket is 2" do
        set_winning_bucket_and_check_validity(2, false)
      end
    end
  end

  describe ".last_updated_at" do
    let!(:first_experiment) do
      FactoryGirl.create(:experiment, name: "first_experiment", updated_at: 1.day.ago)
    end

    let!(:last_experiment) do
      FactoryGirl.create(:experiment, name: "second_experiment", updated_at: Time.now)
    end

    it "is the updated_at timestamp of the most recently updated experiment" do
      Experimental::Experiment.last_updated_at.should == last_experiment.updated_at

      first_experiment.update_attribute(:name, "newname")

      Experimental::Experiment.last_updated_at.should == first_experiment.reload.updated_at
    end
  end

  describe ".[]" do
    let(:experiment) { FactoryGirl.create(:experiment, name: 'exp') }

    before do
      Experimental.source = Support::TestSource.new
      Experimental.source.add(experiment)
    end

    after { Experimental.reset }

    it "fetches the experiment from the configured source" do
      Experimental::Experiment['exp'].should == experiment
    end
  end

  describe "buckets" do
    before do
      stub_sha1(0)
      stub_sha1(1)
      stub_sha1(2)
    end

    context "when population is all" do
      let(:experiment) {
        FactoryGirl.create(:experiment, num_buckets: 3)
      }
      let(:user_options) { {} }

      it_behaves_like "first user"
      it_behaves_like "second user"
      it_behaves_like "third user"
    end

    context "when population is new_users" do
      let(:experiment) { FactoryGirl.create(:new_users_experiment) }
      let(:user_options) { { created_at: Time.now } }

      it_behaves_like "first user"
      it_behaves_like "second user"
      it_behaves_like "third user"

      context "when user is created before start date" do
        let(:u) { FactoryGirl.create(:user, id: 2, created_at: 5.days.ago) }

        it_behaves_like "user should be in bucket 1(b)"
        it_behaves_like "user should not be in experiment"
      end
    end
  end

  describe "winning" do
    let(:u) { FactoryGirl.create(:user, id: 1) }

    describe "default" do
      let(:experiment) { FactoryGirl.create(:ended_experiment) }

      context "when user was in the experiment" do
        before do
          stub_sha1(1, "default", 1)
        end

        it_behaves_like "user should be in bucket 0(a)"
        it_behaves_like "user should be in experiment"
      end

      context "when user is NOT in the experiment" do
        before do
          stub_sha1(0, "default")
        end

        it_behaves_like "user should be in bucket 0(a)"
        it_behaves_like "user should be in experiment"
      end
    end

    describe "b test" do
      let(:experiment) { FactoryGirl.create(:ended_experiment, winning_bucket: 1) }

      describe "when user is in the experiment" do
        before do
          stub_sha1(1, "default", 1)
        end

        it_behaves_like "user should be in bucket 1(b)"
        it_behaves_like "user should be in experiment"
      end

      context "when user is NOT in the experiment" do
        before do
          stub_sha1(0, "default")
        end

        it_behaves_like "user should be in bucket 1(b)"
        it_behaves_like "user should be in experiment"
      end
    end
  end

  describe "#end" do
    context "when the experiment exists" do
      let(:experiment) { FactoryGirl.create(:experiment) }

      context "when the winning bucket number is valid" do
        let(:winning_num) { 0 }

        it "should return true" do
          experiment.end(winning_num).should be_true
        end

        it "should set winning bucket" do
          experiment.end(winning_num)
          experiment.winning_bucket.should == winning_num
        end

        it "should set end date" do
          expect {
            experiment.end(winning_num)
          }.to change{ experiment.end_date }
        end
      end

      context "when the winning bucket number is invalid" do
        let(:winning_num) { 8 }

        it "should return false" do
          experiment.end(winning_num).should be_false
        end
      end
    end

    #This may change depending on how we want to update already ended experiments
    context "when the experiment is already ended" do
      let(:experiment) { FactoryGirl.create(:ended_experiment) }
      let(:winning_num) { 0 }

      it "should return true" do
        experiment.end(winning_num).should be_true
      end

      it "should set winning bucket" do
        experiment.end(winning_num)
        experiment.winning_bucket.should == winning_num
      end

      it "should set end date" do
        expect {
          experiment.end(winning_num)
        }.to change{ experiment.end_date }
      end
    end
  end

  describe "#restart" do
    context "when given an experiment that has already ended" do
      let(:experiment) do
        FactoryGirl.create(:ended_experiment, start_date: "1990-01-01")
      end

      it "sets the winning bucket to nil" do
        experiment.winning_bucket.should_not be_nil
        experiment.restart
        experiment.winning_bucket.should be_nil
      end

      it "sets the start date to the current time" do
        october_22_2023 = 1697998635
        Time.stub(now: Time.at(october_22_2023))

        experiment.start_date.strftime("%m-%d-%Y").should == "01-01-1990"
        experiment.restart
        experiment.start_date.strftime("%m-%d-%Y").should == "10-22-2023"
      end

      it "sets the end date to nil" do
        experiment.should be_ended
        experiment.restart
        experiment.reload.should_not be_ended
      end

      it "sets the removed at to nil" do
        experiment.remove
        experiment.restart
        experiment.should_not be_removed
      end
    end

    context "when given an experiment that has not already ended" do
      let(:experiment) { FactoryGirl.create(:experiment) }

      it "does nothing" do
        old_attributes = experiment.attributes
        experiment.restart.should be_nil
        experiment.attributes.should == old_attributes
      end
    end
  end

  describe "#remove" do
    it "updates without protection" do
      experiment = FactoryGirl.create(:experiment)

      experiment.should_receive(:update_attributes).
        with(hash_including(:removed_at), { without_protection: true}).
        and_return(true)

      experiment.remove.should be_true
    end

    context "the experiment has not been removed" do
      let(:experiment) { FactoryGirl.create(:experiment) }
      it "sets the removed_at timestamp to the current time" do
        expect {
          experiment.remove.should be_true
        }.to change { experiment.removed_at }
      end
    end

    context "the experiment has already been removed" do
      let(:experiment) do
        FactoryGirl.create(:experiment, removed_at: 1.week.ago)
      end

      it "does nothing" do
        expect {
          experiment.remove.should be_false
        }.to_not change { experiment.removed_at }
      end
    end
  end

  describe "#removed?" do
    let(:experiment) { FactoryGirl.build(:experiment) }

    context "the experiment's removed_at timestamp is nil" do
      before { experiment.stub(:removed_at).and_return(nil) }

      it "returns false" do
        experiment.removed?.should be_false
      end
    end

    context "the experiment's removed_at timestamp is not nil" do
      before { experiment.stub(:removed_at).and_return(Time.now) }

      it "returns true" do
        experiment.removed?.should be_true
      end
    end
  end

  describe "#ended?" do
    let(:experiment) { FactoryGirl.build(:experiment) }

    context "the experiment's end_date is nil" do
      before { experiment.stub(:end_date).and_return(nil) }

      it "returns false" do
        experiment.ended?.should be_false
      end
    end

    context "the experiment's end_date is not nil" do
      context "the end_date is in the past" do
        before { experiment.stub(:end_date).and_return(1.day.ago) }

        it "returns true" do
          experiment.ended?.should be_true
        end
      end

      context "the end_date is in the future" do
        before { experiment.stub(:end_date).and_return(1.day.from_now) }

        it "returns false" do
          experiment.ended?.should be_false
        end
      end
    end
  end

  describe ".active and #active?" do
    let(:experiment) { FactoryGirl.create(:experiment) }

    context "the experiment is removed" do
      before { experiment.update_attribute(:removed_at, 1.second.ago) }

      it "is not active" do
        Experimental::Experiment.active.should == []
        experiment.should_not be_active
      end
    end

    context "the experiment is not removed" do
      context "the experiment has no end date" do
        it "is active" do
          Experimental::Experiment.active.should == [experiment]
          experiment.should be_active
        end
      end

      context "the experiment will end in the future" do
        before { experiment.update_attribute(:end_date, 1.second.from_now) }

        it "is active" do
          Experimental::Experiment.active.should == [experiment]
          experiment.should be_active
        end
      end

      context "the experiment has ended" do
        before { experiment.update_attribute(:end_date, 1.second.ago) }

        it "returns false" do
          Experimental::Experiment.active.should == []
          experiment.should_not be_active
        end
      end
    end
  end

  describe "#in?" do
    context "when the experiment has been removed" do
      before { experiment.stub(:removed?).and_return(true) }

      it "does not raise an exception" do
        expect { experiment.in?(user) }.to_not raise_error
      end

      it "is false" do
        experiment.in?(user).should be_false
      end
    end

    context "when the bucket has been forced to a number" do
      before { Experimental.overrides[user, experiment.name] = 2 }
      after { Experimental.overrides.reset }

      it "is true" do
        experiment.in?(user).should be_true
      end
    end

    context "when the bucket has been forced to nil" do
      before { Experimental.overrides[user, experiment.name] = nil }
      after { Experimental.overrides.reset }

      it "is false" do
        experiment.in?(user).should be_false
      end
    end
  end

  describe "#bucket" do
    context "when the experiment has been removed" do
      before { experiment.stub(removed?: true, winning_bucket: 1) }

      it "does not raise an exception" do
        expect { experiment.bucket(user) }.to_not raise_error
      end

      it "returns the winning bucket" do
        experiment.bucket(user).should == experiment.winning_bucket
      end
    end

    context "when the bucket has been forced to a number" do
      before { Experimental.overrides[user, experiment.name] = 2 }
      after { Experimental.overrides.reset }

      it "returns the bucket" do
        experiment.bucket(user).should == 2
      end
    end

    context "when the bucket has been forced to nil" do
      before { Experimental.overrides[user, experiment.name] = nil }
      after { Experimental.overrides.reset }

      it "returns nil" do
        experiment.bucket(user).should be_nil
      end
    end
  end
end
