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
        active = Experimental.experiment_data.map do |name, attributes|
          experiment = Experimental::Experiment.find_or_initialize_by_name(name)
          logger.info "  * #{experiment.id ? 'updating' : 'creating'} #{name}"
          experiment.assign_attributes(attributes)
          experiment.start_date ||= Time.now
          experiment.tap(&:save!)
        end

        scope = Experimental::Experiment.in_code
        scope = scope.where('id NOT IN (?)', active.map(&:id)) unless active.empty?
        scope.find_each do |experiment|
          next if experiment.admin?
          logger.info "  * removing #{experiment.name}"
          experiment.remove
        end
      end

      logger.info "Done."
    end
  end
end
