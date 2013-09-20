FactoryGirl.define do
  factory :experiment, class: Experimental::Experiment do
    name "test"
    population :default
    num_buckets 2
    start_date nil
    end_date nil
    removed_at nil

    factory :random_experiment do
      sequence(:name) { |n| "test#{n}" }
    end

    factory :new_users_experiment do
      population :new_users
      num_buckets 3
      start_date 1.day.ago
    end

    factory :ended_experiment do
      end_date 1.day.ago
      winning_bucket 0
    end

    trait :removed do
      removed_at { Time.now }
    end
  end

  factory :user do

  end
end
