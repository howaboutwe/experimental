module Experimental
  class Loader
    cattr_accessor :file_path
    @@file_path = 'config/experiments.yml'

    @@whitelisted_attributes = [:name, :num_buckets, :notes, :population]

    class << self
      def sync(verbose = false)
        puts "Loading experiments ..." if verbose
        experiments = load_experiments

        #new/active
        experiments.in_code.each do |exp|
          exp = exp.with_indifferent_access
          name = exp[:name]
          puts "\tUpdating #{name} ..." if verbose

          exp = whitelisted_attrs(exp)
          e = Experimental::Experiment.find_by_name(name) || Experimental::Experiment.new

          puts "\t\tcreating ..." if verbose && e.id.nil?
          puts "\t\tupdating ..." if verbose && !e.id.nil?

          exp.merge!({ start_date: Time.now }) if e.start_date.nil?
          e.update_attributes!(exp, without_protection: true)
        end unless experiments.in_code.nil?

        #removed
        experiments.removed.each do |exp|
          name = exp.with_indifferent_access[:name]
          puts "\tRemoving #{name} ..." if verbose

          exp = whitelisted_attrs(exp)
          e = Experimental::Experiment.find_by_name(name)

          if e && e.removed_at.nil?
            puts "\t\t#{name} exists, removing ..." if verbose
            result = e.remove
            puts "\t\t\t#{result}" if verbose
          else
            puts "\t\t#{name} doesn't exist!" if verbose
          end
        end unless experiments.removed.nil?

        puts "Done syncing experiments!" if verbose
      end

      private

      def load_experiments
        OpenStruct.new YAML.load_file(File.join(Rails.root, file_path))
      end

      def whitelisted_attrs(exp)
        attributes = {}
        @@whitelisted_attributes.each do |name|
          attributes[name.to_sym] = exp[name]
        end
        attributes
      end
    end
  end
end
