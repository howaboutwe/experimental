require 'experimental/controller_actions'

class SinglesAdmin::ExperimentsController < ApplicationController
  include Experimental::ControllerActions

  alias_method :index, :experiments_index
  alias_method :new, :experiments_new
  alias_method :set_winner, :experiments_set_winner

  def create
    if experiments_create
      redirect_to singles_admin_experiments_path
    else
      render :new
    end
  end


  def base_resource_name
    "singles_admin_experiment"
  end
end
