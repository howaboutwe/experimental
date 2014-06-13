module Experimental
  module Population
    class NewUsers
      def self.in?(subject, experiment)
        subject.created_at >= experiment.start_date
      end
    end
  end
end
