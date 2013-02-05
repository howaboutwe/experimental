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

  collection_action :set_winner, method: :post do
    experiments_set_winner
  end

  #collection_action :inactive do
    #experiments_inactive
    #render template: 'admin/experiments/index'
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
