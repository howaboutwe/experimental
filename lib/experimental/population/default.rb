# This class will filter the population of an experiment
# Override in? to filter the population
# Called by Experiment.in?
module Experimental
  module Population
    class Default
      def self.in?(obj, experiment)
        true
      end
    end
  end
end
