module Experimental
  class Overrides
    def initialize
      @overrides ||= Hash.new do |experiment_overrides, experiment_name|
        experiment_overrides[experiment_name] = {}
      end
    end

    def include?(subject, experiment_name)
      experiment_name = experiment_name.to_s
      @overrides.key?(experiment_name) && @overrides[experiment_name].key?(subject)
    end

    def [](subject, experiment_name)
      experiment_name = experiment_name.to_s
      @overrides[experiment_name][subject]
    end

    def []=(subject, experiment_name, bucket)
      experiment_name = experiment_name.to_s
      @overrides[experiment_name][subject] = bucket
    end

    def reset
      @overrides.clear
    end
  end
end
