require 'rails'
require 'experimental/engine'

module Experimental
  autoload :VERSION, 'experimental/version'
  autoload :ControllerActions, 'experimental/controller_actions'

  def self.register_population_filter(name, filter_class)
    Experiment.register_population_filter(name, filter_class)
  end
end
