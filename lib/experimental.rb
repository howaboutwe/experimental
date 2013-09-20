require 'rails'
require 'experimental/engine'

module Experimental
  autoload :VERSION, 'experimental/version'
  autoload :ControllerActions, 'experimental/controller_actions'
  autoload :Source, 'experimental/source'

  class << self
    def configure(configuration)
      source = Source::ActiveRecord.new
      if (ttl = configuration['cache_for'])
        source = Source::Cache.new(source, ttl: ttl)
      end
      Experimental.source = source
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

    def reset
      Thread.current[:experimental_source] = nil
      Experiment.reset_population_filters
    end
  end
end
