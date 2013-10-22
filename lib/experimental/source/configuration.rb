module Experimental
  module Source
    class Configuration < Base
      def initialize
        @experiments = {}
        Experimental.experiment_data.each do |name, attributes|
          experiment = Experiment.new(attributes) { |e| e.name = name }
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
