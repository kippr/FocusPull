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

def tmux_title title
    `tmux rename-window -t #{$tmux_win} "#{title}"`
end

def go action
    (0..25).each do | min |
        puts
        puts "#{min}/25: #{action.name}"
        tmux_title "GTD #{min}/25"
        60.times{ sleep(1) && print('.') }
    end
    tmux_title 'Ding!!'
    $stdin.gets
    tmux_title 'GTD'
    read
end

reload
puts "Access portfolio via pf"
$tmux_win = `tmux display-message -p '#I'`.chop
tmux_title 'GTD'
