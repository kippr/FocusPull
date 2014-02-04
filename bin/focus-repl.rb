require 'focus'
require 'active_support/core_ext'
require 'pstore'
require "awesome_print"
AwesomePrint.pry!

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

    def self.active_id
        @@store.transaction(true) { @@store['active'] }
    end

    def self.active_id= active_id
        @@store.transaction do
            @@store['active'] = active_id
        end
    end

    def initialize omni_id
        @id = omni_id
        @estimated = '-'
        @completed = []
        @interrupted = []
    end

    def estimated?
        @estimated.is_a? Fixnum
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

module AwesomePrint
    module Focus

        def self.included(base)
            base.send :alias_method, :cast_without_focus, :cast
            base.send :alias_method, :cast, :cast_with_focus
        end

        def cast_with_focus(object, type)
            cast = cast_without_focus(object, type)
            return cast if !defined?(::Focus)

            if object.is_a?(::Focus::Project)
                cast = :focus_project
            elsif object.is_a?(::Focus::Action)
                cast = :focus_action
            elsif object.is_a?(::Focus::Item)
                cast = :focus_item
            elsif object.is_a?(::Focus::List)
                cast = :focus_list
            end
            cast
        end

        def _color_key(object)
            class_key = object.class.name.split('::').last
            status_key = object.status
            "#{class_key}_#{status_key}".downcase.to_sym
        end

        def awesome_focus_project(object)
            out = []
            # kp: todo: color ancestors
            out << colorize(object.full_name, _color_key(object))
            out += _show( object )
            out.join("\n")
        end

        def _show object
            out = []
            indented do
                for item in object.children
                    out << "#{indent} - #{@inspector.awesome(item)}"
                    out += _show( item)
                end
            end
            out
        end

        def awesome_focus_action(object)
            colorize(object.name, _color_key(object))
        end

        def awesome_focus_item(object)
            colorize(object.name, _color_key(object))
        end

        def awesome_focus_list(object)
            @inspector.awesome(object.to_a)
        end

    end
end
AwesomePrint::Formatter.send(:include, AwesomePrint::Focus)

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
        _restore_active
        _reset_title
    end
    alias_method :r, :reload

    def _restore_active
        last_id = Pomodoro.active_id
        focuson pf.list.detect{|i|i.id == last_id} if last_id
    end

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
    alias_method :a, :active

    def pomo
        Pomodoro.obtain!( active.id )
    end

    def project
        active.parent
    end
    alias_method :pr, :project

    def _resolve_focus_item input, base_choices
        case input
        when Enumerable
            pick( input )
        when Regexp
            base_choices.call.with_name( input )
        when Focus::Item
            input
        else
            pick( base_choices.call, input )
        end
    end

    def focuson input=nil, silent=false
        action = _resolve_focus_item( input , lambda{ pf.list.active.actions })
        raise( "No action given" ) unless action.is_a? Focus::Item
        @active = action
        Pomodoro.active_id = action.id
        _update_prompt
        print_summary unless silent
    end
    alias_method :focus, :focuson

    def show input=nil
        _resolve_focus_item( input, lambda { pf.list } )
    end

    def estimate estimate
        pomo.estimate = estimate
        print_summary
        _update_prompt
    end
    alias_method :est, :estimate

    def start input=nil
        focuson input if input
        unless pomo.estimated?
            print "Estimate? "
            input = $stdin.gets.chop.to_i
            pomo.estimate = input unless input.blank?
            puts
        end
        begin
            25.times{| minute | _tick minute, 25}
        rescue Interrupt
            pomo.interrupt!
            _notify_interrupted
        else
            pomo.complete!
            _notify_completed
            print_summary
            rest
        end
        _update_prompt
        _reset_title
    end
    alias_method :go, :start

    def done input=nil
        focuson( _resolve_focus_item( input, lambda { pf.list } ), true ) if input
        item_id = active.id
        puts "Toggling status of #{active}"
        `osascript script/Omnifocus/toggle-completed.scpt #{item_id}`
        reload
        new_item = pf.list.detect{ |i| i.id == item_id }
        focuson( new_item, true ) if new_item
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
