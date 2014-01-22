require 'focus'
require 'active_support/core_ext'
require 'pstore'

class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end

  def mean
    sum / size
  end
end


class Pomodoro

    @@store = PStore.new('pomodoro.pstore')

    def initialize omni_id
        @id = omni_id
        @estimated = 0
        @completed = 0
        @interupted = 0
    end

    def estimate= value
        @estimated = value
        save!
    end

    def complete!
        @completed += 1
        save!
    end

    def interrupt!
        @interupted += 1
        save!
    end

    def save!
        @@store.transaction do
            @@store[@id] = self
        end
    end

    def self.obtain! omni_id
        @@store.transaction(true) { @@store[omni_id] } || new( omni_id )
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

module Focus
    class Item

        def pomo
            Pomodoro.obtain!( @id )
        end

    end
end


def go action
    pomodoro = action.pomo
    puts pomodoro.inspect
    begin
        (0..25).each do | min |
            puts
            puts "#{min}/25: #{action.name}"
            tmux_title "GTD #{min}/25"
            60.times{ sleep(1) && print('.') }
        end
        pomodoro.complete!
        tmux_title 'Ding!!'
        $stdin.gets
    rescue Interrupt
        pomodoro.interrupt!
        puts "Doh!!"
    end
    tmux_title 'GTD'
end

reload
puts "Access portfolio via pf"
$tmux_win = `tmux display-message -p '#I'`.chop
tmux_title 'GTD'
