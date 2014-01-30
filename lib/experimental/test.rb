module Experimental
  # Test helpers for applications that use Experimental.
  #
  # For popular test frameworks, simply require the appropriate
  # experimental/test/*.rb file. If those doesn't cover you, check one of those
  # to see how to hook up your favorite framework.
  module Test
    # Call this once to initialize Experimental for your test suite.
    #
    # Calling it again isn't harmful, just unnecessary.
    def self.initialize
      return if @initialized
      @initial_source = Experimental.source
      Experimental.source = Experimental::Source::Configuration.new
      @initialized = true
    end

    # Call this before each test. It provides a deterministic default: all
    # subjects are out of all experiments. Opt subjects into experiments using
    # #set_experimental_bucket.
    def self.setup
      Experimental.overrides.reset
      Experimental.overrides.set_default(nil)
    end

    def self.teardown
      Experimental.source = @initial_source
      @initialized = false
    end

    # Force the given subject into the given +bucket+ of the given +experiment+.
    #
    # If +bucket+ is nil, exclude the user from the experiment.
    def set_experimental_bucket(subject, experiment_name, bucket)
      Experimental.overrides[subject, experiment_name] = bucket
    end
  end
end
