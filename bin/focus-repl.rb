require 'focus'
require 'active_support/core_ext'
require 'pstore'

require_relative '../../forks/selecta/selecta'


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
        @estimated = '-'
        @completed = []
        @interrupted = []
    end

    def estimate= value
        @estimated = value
        save!
    end

    def complete!
        @completed << Time.now
        save!
    end

    def interrupt!
        @interrupted << Time.now
        save!
    end

    def save!
        @@store.transaction do
            @@store[@id] = self
        end
    end

    def to_short_s
        "#{@completed.length}/#{@estimated}"
    end

    def to_s
        "Estimate: #{@estimated}; Completed: #{@completed.length}; Interuptions: #{@interrupted.length}"
    end

    def self.obtain! omni_id
        @@store.transaction(true) { @@store[omni_id] } || new( omni_id )
    end

end


module PomodoroClient

    attr_accessor :pf

    begin
        require 'terminal-notifier'
        @@notifications = true
    rescue LoadError
        $stderr.puts "\nWARNING: terminal-notifier gem not found, no notifications will be posted\n\n"
        @@notifications = false
    end

    @@tmux_win = `tmux display-message -p '#I'`.chop

    def reload
        @pf = Focus::FocusParser.local
        _reset_title
    end
    alias_method :r, :reload

    def print_summary
        puts
        puts "*** #{active.name} ***"
        puts "    #{pomo}"
        puts
        puts "[#{active.parent.name}]"
        active.parent.list.active.actions.each do |a|
            if active == a
                puts " --> #{a.name.truncate(80)}" if active == a
            else
                puts "  *  #{a.name.truncate(80)}" unless active == a
            end
        end
        puts
    end
    alias_method :w, :print_summary

    def active
        @active || raise( "No active action; set via 'workon <action>'" )
    end

    def pomo
        Pomodoro.obtain!( active.id )
    end

    def _resolve_focus_action input
        case input
        when Enumerable
            pick( input )
        when Regexp
            pf.list.active.action( input )
        when Focus::Item
            input
        else
            pick( pf.list.active.actions, input )
        end
    end

    def focuson input=nil
        action = _resolve_focus_action( input )
        raise( "No action given" ) unless action.is_a? Focus::Item
        @active = action
        _update_prompt
        print_summary
    end
    alias_method :focus, :focuson

    def estimate estimate
        pomo.estimate = estimate
        print_summary
        _update_prompt
    end
    alias_method :est, :estimate

    def start
        begin
            25.times{| minute | _tick minute, 25}
        rescue Interrupt
            pomo.interrupt!
            _notify_interrupted
        else
            pomo.complete!
            _notify_completed
            rest
        end
        _update_prompt
        _reset_title
    end

    def pick choices, initial_filter=nil
        found = _selecta( choices.full_names, initial_filter )
        pf.list.detect{ |i| i.full_name == found} if found
    end

    def _selecta choices, initial_filter
        options = {search: initial_filter || ''}
        selecta = Selecta.new
        search = Screen.with_screen do |screen, tty|
            config = Configuration.from_inputs(choices, options, screen.height)
            Selecta.new.run_in_screen(config, screen, tty)
        end.selected_choice
    end

    def rest length = nil
        length = 5 unless length
        begin
            length.times{| minute | _tick minute, length}
        rescue Interrupt
        else
            _notify_rested
        end
        _reset_title
    end

    def _update_prompt
        Pry.config.prompt_name = "#{active.name.truncate(25, :separator => ' ')} [#{pomo.to_short_s}]"
    end

    def _tmux_title title
        `tmux rename-window -t #{@@tmux_win} "#{title}"`
    end

    def _term_notify title, message
        if @@notifications
            TerminalNotifier.notify(message, :title => title, :sender => 'com.apple.Terminal', :activate => 'com.apple.Terminal')
        end
        @@notifications
    end

    def _notify_completed
        _term_notify "Pomodoro complete", "#{active.name} [#{pomo.to_short_s}]"
    end

    def _notify_interrupted
        _term_notify "Pomodoro interupted", "#{active.name} [#{pomo.to_short_s}]"
    end

    def _notify_rested
        _term_notify "Break over!", "Get back to work slacker"
    end

    def _reset_title
        _tmux_title 'Plan'
    end

    def _tick minute, length
        title = length == 25 ? 'Focus' : 'Rest'
        _tmux_title "#{title}[#{minute}]"
        print "#{minute}/#{length} "
        60.times{ sleep(1) && print('.') }
        puts
    end

end



extend PomodoroClient
reload
puts "FocusRepl started, access portfolio via pf, set active action via focuson"
