module Experimental
  VERSION = [0, 1, 1]

  class << VERSION
    include Comparable

    def to_s
      join('.')
    end
  end
end
