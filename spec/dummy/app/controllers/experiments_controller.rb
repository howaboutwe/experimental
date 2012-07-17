require 'experimental/controller_actions'

class ExperimentsController < ApplicationController
  include Experimental::ControllerActions

  alias_method :index, :experiments_index
  alias_method :new, :experiments_new
  alias_method :set_winner, :experiments_set_winner

  def create
    if experiments_create
      redirect_to experiments_path
    else
      render :new
    end
  end
end
