require 'rails'
require 'experimental/engine'

module Experimental
  autoload :Experiment, 'experimental/experiment'
  autoload :Loader, 'experimental/loader'
  autoload :Overrides, 'experimental/overrides'
  autoload :Population, 'experimental/population'
  autoload :Source, 'experimental/source'
  autoload :Subject, 'experimental/subject'
  autoload :Test, 'experimental/test'
  autoload :VERSION, 'experimental/version'

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
      @experimental_source = source
    end

    def source
      @experimental_source ||= Source::ActiveRecord.new
    end

    def experiment_data=(data)
      @experimental_data = data
    end

    def experiment_data
      @experimental_data ||= {}
    end

    def reset
      self.source = nil
      self.experiment_data = nil
      Experiment.reset_population_filters
    end

    def overrides
      @experimental_overrides ||= Overrides.new
    end
  end
end

require 'experimental/railtie' if defined?(Rails)
