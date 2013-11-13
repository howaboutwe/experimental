module Experimental
  module Source
    class ActiveRecord < Base
      def [](name)
        Experiment.find_by_name(name)
      end

      def available
        Experiment.available.all
      end
    end
  end
end
