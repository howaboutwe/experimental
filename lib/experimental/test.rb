module Experimental
  module Test
    def self.included(base)
      base.before do
        Experimental.source = Experimental::Source::Configuration.new
        Experimental.overrides.reset
      end

      base.after do
        Experimental.overrides.reset
      end
    end

    # Force the given subject into the given +bucket+ of the given +experiment+.
    #
    # If +bucket+ is nil, exclude the user from the experiment.
    def set_experimental_bucket(subject, experiment_name, bucket)
      Experimental.overrides[subject, experiment_name] = bucket
    end
  end
end
