require 'rails'
require 'experimental/engine'

module Experimental
  autoload :VERSION, 'experimental/version'
  autoload :ControllerActions, 'experimental/controller_actions'
  autoload :Loader, 'experimental/loader'
  autoload :Overrides, 'experimental/overrides'
  autoload :Source, 'experimental/source'
  autoload :Test, 'experimental/test'

  class << self
    def configure(configuration)
      source = Source::ActiveRecord.new
      if (ttl = configuration['cache_for'])
        source = Source::Cache.new(source, ttl: ttl)
      end
      self.experiment_data = configuration['experiments']
      self.source = source
    end

    def register_population_filter(name, filter_class)
      Experiment.register_population_filter(name, filter_class)
    end

    def source=(source)
      Thread.current[:experimental_source] = source
    end

    def source
      Thread.current[:experimental_source] ||= Source::ActiveRecord.new
    end

    def experiment_data=(data)
      Thread.current[:experimental_data] = data
    end

    def experiment_data
      Thread.current[:experimental_data] ||= {}
    end

    def reset
      self.source = nil
      self.experiment_data = nil
      Experiment.reset_population_filters
    end
  end

  def self.overrides
    Thread.current[:experimental_overrides] ||= Overrides.new
  end
end
