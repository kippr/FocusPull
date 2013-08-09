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


def reload
    @@pf = Focus::FocusParser.local
end

def pf
    @@pf
end

def pfl
    pf.list
end

reload
puts "Access portfolio via pf"
