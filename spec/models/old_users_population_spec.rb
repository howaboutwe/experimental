require "spec_helper"

describe User do
  include Experimental::RspecHelpers

  let!(:exp) {
    Experimental::Experiment.new do |e|
      e.name = :exp
      e.num_buckets = 2
      e.population = :old_users
      e.start_date = Time.now
    end
  }

  before { Experimental::Experiment.register_population_filter :old_users, Experimental::Population::OldUsers }
  after { Experimental::Experiment.reset_population_filters }

  it "can find the population" do
    Experimental::Experiment.find_population(:old_users).should == Experimental::Population::OldUsers
  end

  it "includes users created before the experiment" do
    user = FactoryGirl.create(:user, created_at: 5.days.ago)
    exp.should be_in(user)
  end

  it "doesn't include users created after the experiment" do
    user = FactoryGirl.create(:user, created_at: Time.now.next_month)
    exp.should_not be_in(user)
  end
end
