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
  end
end
