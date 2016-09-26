module Experimental
  class Overrides
    def initialize
      @overrides ||= Hash.new do |experiment_overrides, experiment_name|
        experiment_overrides[experiment_name] = {}
      end
      @default_set = false
    end

    def set_default(value)
      @default_set = true
      @default = value
    end

    def include?(subject, experiment_name)
      return true if @default_set
      experiment_name = experiment_name.to_s
      @overrides.key?(experiment_name) && @overrides[experiment_name].key?(subject.experiment_seed_value)
    end

    def [](subject, experiment_name)
      experiment_name = experiment_name.to_s
      if @overrides[experiment_name].key?(subject.experiment_seed_value)
        @overrides[experiment_name][subject.experiment_seed_value]
      else
        @default
      end
    end

    def []=(subject, experiment_name, bucket)
      experiment_name = experiment_name.to_s
      @overrides[experiment_name][subject.experiment_seed_value] = bucket
    end

    def reset
      @overrides.clear
      @default_set = false
      @default = nil
    end
  end
end
