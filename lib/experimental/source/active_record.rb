module Experimental
  module Source
    class ActiveRecord < Base
      def [](name)
        Experiment.find_by_name(name)
      end

      def active
        Experiment.active.all
      end
    end
  end
end
