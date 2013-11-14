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
      Experimental.source = Experimental::Source::Configuration.new
      @initialized = true
    end

    # Call this before each test.
    def self.setup
      Experimental.overrides.reset
    end

    # Force the given subject into the given +bucket+ of the given +experiment+.
    #
    # If +bucket+ is nil, exclude the user from the experiment.
    def set_experimental_bucket(subject, experiment_name, bucket)
      Experimental.overrides[subject, experiment_name] = bucket
    end
  end
end
