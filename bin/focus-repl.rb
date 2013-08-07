require 'focus'
require 'active_support/core_ext'

class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end

  def mean 
    sum / size
  end
end

@@root = Focus::FocusParser.local
