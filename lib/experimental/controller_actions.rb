require 'ostruct'

module Experimental
  module ControllerActions
    extend ActiveSupport::Concern

    included do
      class_eval do
        attr_writer :base_resource_name

        respond_to :json, :only => [:set_winner]

        before_filter :set_experimental_path_names
      end
    end

    def base_resource_name
      @base_resource_name ||= "experiment"
    end

    def set_experimental_path_names
      @experimental_path_names = OpenStruct.new
      plural_path = "#{base_resource_name.pluralize}_path"

      @experimental_path_names.index = self.send(plural_path.to_sym)
      if self.respond_to?("inactive_#{plural_path}".to_sym)
        @experimental_path_names.inactive = self.send("inactive_#{plural_path}".to_sym)
      end
      @experimental_path_names.new = self.send("new_#{base_resource_name}_path".to_sym)
      @experimental_path_names.set_winner = self.send("set_winner_#{plural_path}".to_sym)
    end

    def experimental_path_names
      set_experimental_path_names if @experimental_path_names.nil?
      @experimental_path_names
    end

    def experiments_index
      @h1 = "In-progress Experiments"
      @include_inactive = false
      @experiments = Experiment.in_progress
    end

    def experiments_new
      @experiment = Experiment.new
    end

    def experiments_create
      @experiment = Experiment.new(params[:experimental_experiment])
      @experiment.start_date = Time.now

      if @experiment.save
        flash[:notice] = "Experiment was successfully created."
        return true
      else
        flash.now[:error] = "There was an error!"
        return false
      end
    end

    def experiments_inactive
      @h1 = "Ended or Removed Experiments"
      @include_inactive = true
      @experiments = Experiment.ended_or_removed
    end

    def create
      if experiments_create
        redirect_to experimental_path_names.index
      else
        render :new
      end
    end

    def inactive
      experiments_inactive
      render :index
    end

    def experiments_set_winner
      exp = Experiment.find params[:id]
      if exp.end(params[:bucket_id])
        render json: nil, status: :ok
      else
        render json: nil, status: :error
      end
    end
  end
end
