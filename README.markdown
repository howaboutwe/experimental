## Experimental

```rails g experimental```

# Routes

````
    resources :experiments, :only => [:index, :new, :create] do
      collection do
        get :inactive
        post :set_winner
      end
    end
````

````
    namespace :singles_admin do
      resources :experiments, :only => [:index, :new, :create] do
        collection do
          get :inactive
          post :set_winner
        end
      end
    end
````

# Admin Frontend

Create admin controllers:
````
    class Admin::ExperimentsController < ApplicationController
      include Experimental::RspecHelpers

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

      ...
    end
````

ActiveAdmin:

``` rails g active_admin:resource Experiment```

````
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
      #collection_action :inactive do
      #  experiments_inactive
      #  render template: 'admin/experiments/index'
      #end

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

      form :partial => 'new'
    end

````

Views



create an index and new view in appropriate view folder, i.e.

``` app/views/admin/experiments/index.html.erb ```
````
    <%= render partial: 'experimental/links' %>
    <%= render partial: 'experimental/index' %>
````

``` app/views/admin/experiments/new.html.erb ```
````
    <%= render partial: 'experimental/links' %>
    <%= render partial: 'experimental/new' %>
````


#Testing

in ```spec_helper.rb```

````
    require 'experimental/rspec_helpers'
    ....
    config.before(:each) do
      User.any_instance.stub(:in_experiment?).and_return(false)
    end
````

Testing experiments:
````
    include Experimental::RspecHelpers
````

To run experiments on a model, the model just needs an id and
timestamps:
````
    class User < ActiveRecord::Base
      include Experimental::Subject
    end
````
