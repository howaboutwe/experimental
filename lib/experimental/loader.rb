require 'logger'

module Experimental
  class Loader
    def initialize(options = {})
      @logger = options[:logger] || Logger.new('/dev/null')
    end

    attr_reader :logger

    def sync
      logger.info "Synchronizing experiments..."

      Experimental::Experiment.transaction do
        scope = Experimental::Experiment.in_code
        active_ids = updated_active_experiments.map(&:id)
        active_ids.empty? or
          scope = scope.where('id NOT IN (?)', active_ids)

        remove_experiments(scope)
      end

      logger.info "Done."
    end

    private

    def updated_active_experiments
      Experimental.experiment_data.map do |name, attributes|
        experiment = Experimental::Experiment.where(name: name).
          first_or_initialize

        nullify_attributes(experiment, attributes)

        logger.info "  * #{experiment.id ? 'updating' : 'creating'} #{name}"

        experiment.tap(&:save!)
      end
    end

    def remove_experiments(scope)
      scope.find_each do |experiment|
        next if experiment.admin?
        logger.info "  * removing #{experiment.name}"
        experiment.remove
      end
    end

    def nullify_attributes(experiment, attributes)
      set_new_start_date(experiment, attributes)
      defaults = {'num_buckets' => nil, 'notes' => nil, 'population' => nil}
      experiment.assign_attributes(defaults.merge(attributes))
    end

    def set_new_start_date(experiment, attributes)
      if (unstarted = attributes.delete('unstarted'))
        experiment.start_date = nil
      else
        experiment.start_date ||= Time.current
      end
    end
  end
end
