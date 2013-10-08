# Experimental
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

### Routes

```ruby
resources :experiments, only: [:index, :new, :create] do
  collection do
    get :inactive
      post :set_winner
    end
  end

  namespace :singles_admin do
    resources :experiments, only: [:index, :new, :create] do
      collection do
        get :inactive
        post :set_winner
      end
    end
  end
end
```

### Admin Frontend

#### Create your own admin controller:
```ruby
class Admin::ExperimentsController < ApplicationController
  include Experimental::ControllerActions

  alias_method :index, :experiments_index
  alias_method :new, :experiments_new
  alias_method :set_winner, :experiments_set_winner

  def create
    if experiments_create
      redirect_to admin_experiments_path
    else
      render :new
    end
  end

  def base_resource_name
    "singles_admin_experiment"
  end
end
```

#### Using ActiveAdmin:

`rails g active_admin:resource Experiment`

```ruby
require 'experimental/controller_actions'

ActiveAdmin.register Experimental::Experiment, as: "Experiment" do
  actions :index, :new, :create
  filter :name

  controller do
    class_eval do
      include Experimental::ControllerActions
    end

    def base_resource_name
      "admin_experiment"
    end

    def create
      if experiments_create
        redirect_to admin_experiments_path
      else
        render :new
      end
    end

    def new
      experiments_new
    end
  end

  # collection_actions force active_admin to create a route
  collection_action :set_winner, method: :post do
    experiments_set_winner
  end

  # can do this instead of the ended_or_removed scope below
  # you will need to add a link to inactive_admins_experiments_path
  #  in your view
  collection_action :inactive do
    experiments_inactive
    render template: 'admin/experiments/index'
  end

  scope :in_progress, :default => true do |experiments|
    experiments.in_progress
  end

  scope :ended_or_removed do |experiments|
    @include_inactive = true
    experiments.ended_or_removed
  end

  index do
    render template: 'admin/experiments/index'
  end

  form partial: 'new'
end
```

#### Views

create an index and new view in appropriate view folder, i.e.

`app/views/admin/experiments/index.html.erb`

```erb
<%= render partial: 'experimental/links' %>
<%= render partial: 'experimental/index' %>
```

`app/views/admin/experiments/new.html.erb`

```erb
<%= render partial: 'experimental/links' %>
<%= render partial: 'experimental/new' %>
```

*Note: ActiveAdmin users will not need to include the links
  partials*

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

In `config/experiments.yml`, add the name, num_buckets, and notes of the
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
Then run `rake experiments:sync`

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

Removing an experiment from `config/experiments.yml` and running `rake experiments:sync` will
remove the experiment and expire the cache.

```yaml
removed:
-
  name: :price_experiment
```
Then run `rake experiments:sync`

## Testing

### Setup
in `spec_helper.rb` (after inclusion of ActiveSupport)

```ruby
require 'experimental/rspec_helpers'
```

*You may want to force experiments off for all tests by default*
```ruby
config.before(:each) do
  User.any_instance.stub(:in_experiment?).and_return(false)
end
```

### Testing experiments

Include the Rspec helpers in your spec class or spec_helper
```ruby
include Experimental::RspecHelpers
```

Shared contexts are available for in_experiment? and in_bucket?
```ruby
include_context "in experiment"
include_context "not in experiment"

include_context "in experiment bucket 0"
include_context "in experiment bucket 1"
```

Helper methods are also available:

**is_in_experiment**
```ruby
# first param is true for in experiment, false for not in experiment
# second param is the experiment name
# third param is the subject object
is_in_experiment(true, :my_experiment, my_subject)

# if user and experiment_name are defined, you can do
let(:experiment_name) { :my_experiment }
let(:user) { User.new }
is_in_experiment # true if in experiment
is_in_experiment(false) # true if NOT in experiment
```

**is_not_in_experiment**
```ruby
# first param is name of experiment
# second param is subject object
is_not_in_experiment(:my_experiment, my_subject)

# if user and experiment_name are defined, you can do
let(:experiment_name) { :my_experiment }
let(:user) { User.new }
is_not_in_experiment
```

**has_experiment_bucket**
```ruby
has_experiment_bucket(1, :my_experiment, my_subject)

# if user and experiment_name are defined, you can do
let(:experiment_name) { :my_experiment }
let(:user) { User.new }
has_experiment_bucket(1)
```

## Developer Workflow

Experiments *can* be defined in config/experiments.yml
Running the rake task `rake experiments:sync` will load those
experiments under 'in_code' into the database and set removed_at
timestamp for those under 'removed'

You will likely want to automate the running of `rake
experiments:sync` by adding to your deploy file.

### Capistrano
In `config/deploy.rb`:

Create a namespace to run the task:
```ruby
namespace :database do
  desc "Sync experiments"
  task :sync_from_app, roles: :db, only: { primary: true } do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec rake experiments:sync"
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
