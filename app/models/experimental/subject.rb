module Experimental
  module Subject
    def in_experiment?(name)
      Experimental.source[name].try { |e| e.in?(self) }
    end

    def not_in_experiment?(name)
      !in_experiment?(name)
    end

    def experiment_bucket(name)
      Experimental.source[name].try { |e| e.in?(self) ? e.bucket(self) : nil }
    end

    def in_bucket?(name, bucket)
      in_experiment?(name) && experiment_bucket(name) == bucket
    end

    def method_missing(meth, *args, &block)
      name = meth.to_s.chop
      existing_experiment_for_predicate?(meth) or
        return super

      in_bucket?(name, 1)
    end

    def respond_to_missing?(meth, include_private = false)
      existing_experiment_for_predicate?(meth) || super
    end

    def existing_experiment_for_predicate?(meth)
      meth.to_s.end_with?('?') &&
        Experimental::Experiment.find_by_name(meth.to_s.chop)
    end
  end
end
