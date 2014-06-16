# Experimental [![Build Status](https://travis-ci.org/howaboutwe/experimental.png?branch=master)](https://travis-ci.org/howaboutwe/experimental)

Experimental is an Split testing framework for Rails.  
It was written with a few goals in mind:
* Split the users in a non-predictable pattern (i.e. half of the users won't always
be in all experiments)
* Keep experiments and their start and end dates in the database
* Have a clear developer workflow, so that tests in the code are
  started in the database when the code goes out and tests that should
be removed make the site explode
* Allow admins to end experiments and set a winner
* Cache the experiments

## Installation

`rails g experimental`

### Subject

For the class you'd like to be the subject of experiments, include the
Experimental::Subject module in a model with an id and timestamps
```ruby
class User < ActiveRecord::Base
  include Experimental::Subject
  # ...
end
```

## Usage

### Create an experiment

In `config/experimental.yml`, add the name, num_buckets, and notes of the
experiment under in_code:
```yaml
in_code:
-
  name: :price_experiment
  num_buckets: 2
  notes: |
    0: $22
    1: $19.99

```
Then run `rake experimental:sync`

### Using the experiment

To see if a user is in the experiment population AND in a bucket:
```ruby
# checks if the user is in the my_experiment population
# and if they are in bucket 0
user.in_bucket?(:my_experiment, 0)
```

To see if a user is in the experiment population **ONLY**
```ruby
user.in_experiment?(:my_experiment)
user.not_in_experiment?(:my_experiment) # inverse
```

To see which bucket of an experiment a user is in:
```ruby
user.experiment_bucket(:my_experiment)
```

### Ending an experiment

You can end an experiment by setting the end_date.  In the admin
interface, there is a dropdown to set the end date. When ending an
experiment *you must set a winning bucket*

*Ending an experiment means that all users will be given the winning
bucket*

### Removing an experiment

A removed experiment is an experiment that is not referenced
anywhere in code.  In fact, the framework will throw an exception
if you reference an experiment that is not in code.

Removing an experiment from `config/experimental.yml` and running `rake
experimental:sync` will remove the experiment and expire the cache.

```yaml
removed:
-
  name: :price_experiment
```
Then run `rake experimental:sync`

## Testing

In your test suite, you typically want to have an neutral starting state across
all your tests. For experiments, this means all subjects are out of all
experiments. You then opt a particular subject into a particular bucket for any
experiment as your test requires.

Experimental ships with support to do this in a number of popular test
frameworks. Setup instructions for each framework are in the following sections.

Once set up, you can then force a subject into a bucket for an experiment as
follows:

```ruby
set_experimental_bucket(subject, :my_experiment, 1)
```

If you set the bucket (1 in the above example) to `nil`, this means set the
subject to be out of the experiment (the default state).

### Minitest
```ruby
require 'experimental/test/unit'

class MyTest < Test::Unit::TestCase
  include Experimental::Test::Unit
  ...
end
```

Note that if you define a `setup` method, then you must remember to call
`super` (always good practice in general).

### RSpec
```ruby
require 'experimental/test/rspec'

RSpec.configure do |config|
  config.include Experimental::Test::RSpec
end
```

### Cucumber
```ruby
require 'experimental/test/cucumber'
```

## Developer Workflow

Experiments *can* be defined in `config/experimental.yml`
Running the rake task `rake experimental:sync` will load those
experiments under 'in_code' into the database and set removed_at
timestamp for those under 'removed'

You will likely want to automate the running of `rake
experimental:sync` by adding to your deploy file.

### Capistrano
In `config/deploy.rb`:

Create a namespace to run the task:
```ruby
namespace :database do
  desc "Sync experiments"
  task :sync_from_app, roles: :db, only: { primary: true } do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec rake experimental:sync"
  end
end
```

Include that in the deploy:default task:
```ruby
namespace :deploy do
  #...
  task :default do
    begin
      update_code
      migrate
      database.sync_from_app
      restart
    #...
    end
  end
end
```

### Admin created experiments

The purpose of Admin created experiments are for experiments
that will flow through to another system, such as an email provider.
They likely start with a known string and are dynamically sent in
code.
Otherwise, Admin created experiments will do nothing as there is no
code attached to them. 
