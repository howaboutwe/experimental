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
        all_experiments = Experimental::Experiment.in_code
        active_experiments = create_or_update_active_experiments

        if active_experiments.present?
          active_ids = active_experiments.map(&:id)
          remove(all_experiments.where('id NOT IN (?)', active_ids))
        else
          remove(all_experiments)
        end
      end

      logger.info "Done."
    end

    private

    def create_or_update_active_experiments
      Experimental.experiment_data.map do |name, attributes|
        experiment = Experimental::Experiment.where(name: name).
          first_or_initialize

        reset_attributes(experiment, attributes)

        logger.info "  * #{experiment.id ? 'updating' : 'creating'} #{name}"

        experiment.tap(&:save!)
      end
    end

    def reset_attributes(experiment, attributes)
      set_new_start_date(experiment, attributes)
      defaults = {'num_buckets' => nil, 'notes' => nil, 'population' => nil}
      experiment.assign_attributes(defaults.merge(attributes))
    end

    def remove(experiments)
      experiments.find_each do |experiment|
        next if experiment.admin?
        logger.info "  * removing #{experiment.name}"
        experiment.remove
      end
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
