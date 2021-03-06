class User < ActiveRecord::Base
  include Experimental::Subject
end

module Experimental::Population
  class OldUsers
    def self.in?(subject, experiment)
      subject.created_at < experiment.start_date
    end
  end
end
