module Experimental
  module Source
    class Data < Base
      def initialize(experiment_data)
        @experiments = {}
        experiment_data.each do |attributes|
          experiment = Experiment.new(attributes)
          @experiments[experiment.name] = experiment
        end
      end

      def [](name)
        @experiments[name.to_s]
      end

      def active
        @experiments.values
      end
    end
  end
end
