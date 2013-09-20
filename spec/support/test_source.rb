module Support
  class TestSource
    attr_accessor :experiments

    def initialize
      @experiments = {}
    end

    def add(experiment)
      @experiments[experiment.name] = experiment
    end

    def [](name)
      experiments[name]
    end

    def active
      experiments.values
    end
  end
end
