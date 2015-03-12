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
        "#{@completed.length}/#{@estimated}/#{@interrupted.length}"
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

class BurndownChart

    HTML = <<-EOS
        <html>
        <head>
        <script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
        <script src="http://code.highcharts.com/highcharts.js"></script>
        <script>
            $(function () {
                $('#container').highcharts(%{chart_config});
            });
        </script>
        </head>
        <body>
        <div id="container" style="min-width: 310px; height: 400px; margin: 0 auto"></div>
        </body>
        </html>
    EOS

    def highcharts_json(chart_name, labels, guide, actuals)
        {
            title: {
                text: chart_name,
                x: -20
            },
            xAxis: {
                categories: labels,
            },
            yAxis: {
                min: 0,
                title: {
                    text: 'Todos'
                },
            },
            tooltip: {
                shared: true,
            },
            legend: {
                layout: 'vertical',
                align: 'right',
                verticalAlign: 'middle',
                borderWidth: 0,
            },
            series: [
                {
                    name: 'Guide',
                    data: guide,
                },
                {
                    name: 'Actual',
                    data: actuals,
                },
            ],
            plotOptions: {
                series: {
                    marker: {enabled: false},
                }
            }
        }
    end

    def by_date(todos, start_date, end_date)
        results = {}
        day = start_date
        today = Date.today
        while (day <= end_date)
            if day <= end_date
                if not day.saturday? and not day.sunday?
                    for todo in todos
                        results[day] = [] if results[day] == nil
                        results[day] << todo if todo.created_date <= day and (not todo.completed_date or todo.completed_date > day)
                    end
                end
            else
                results[day] = nil
            end
            day = day + 1
        end
        results
    end

    def plot chart_name, todos, start_date, end_date
        todos_by_date = by_date(todos, start_date, end_date).sort
        high_count = 0
        per_day = 0
        days_to_go = todos_by_date.length
        labels, actuals, guide = todos_by_date.collect do |day, todos|
            remaining = todos.length
            if remaining > high_count
                high_count = remaining
                per_day = remaining / days_to_go.to_f
            end
            guide = per_day * days_to_go
            days_to_go -= 1
            remaining = nil if day > Date.today
            [day, remaining, guide]
        end.transpose
        chart_config = highcharts_json(chart_name, labels, guide, actuals)
        return HTML % { chart_config: JSON.dump(chart_config) }
    end

end

module PomodoroClient

    @@tmux_win = `tmux display-message -p '#I'`.chop

    begin
        require 'terminal-notifier'
        @@notifications = true
    rescue LoadError
        $stderr.puts "\nWARNING: terminal-notifier gem not found, no notifications will be posted\n\n"
        @@notifications = false
    end

    def pf
        @@pf || reload( true )
    end

    def reload silent = false
        @@pf = Focus::FocusParser.local
        _restore_active silent
        _reset_title
        @@pf
    end
    alias_method :r, :reload

    def _restore_active silent
        last_id = Pomodoro.active_id
        focuson( pf.list.detect{|i|i.id == last_id}, silent ) if last_id
    end

    def print_summary item = nil
        item = active unless item
        puts
        puts "*** #{item.name} ***"
        puts "    #{pomo item}"
        puts
        puts "[#{item.parent.name}]"
        #kp: todo: be good to add project? to Item
        container = item.class == Focus::Action ? item.parent : item
        container.list.actions.each do |a|
            pomodoro_status = pomo( a ).to_short_s
            print (item.id == a.id ? " --> " : "  *  ")
            print "[#{pomodoro_status}]  "
            ap(a)
        end
        puts
    end
    alias_method :w, :print_summary

    def active
        @@active || raise( "No active action; set via 'workon <action>'" )
    end
    alias_method :a, :active

    def pomo item = nil
        item = active unless item
        Pomodoro.obtain!( item.id )
    end

    def project
        active.parent
    end
    alias_method :pr, :project

    def focus_projects
        pf.list.active.projects.not.single_action.full_names
    end
    alias_method :fp, :focus_projects

    def _resolve_focus_item input, base_choices
        case input
        when Enumerable
            pick( nil, input )
        when Regexp
            base_choices.call.with_name( input )
        when Focus::Item
            input
        else
            pick( input, base_choices.call )
        end
    end

    def _ensure_present item
        raise RuntimeError.new( "No item matched, got '#{item}'" ) unless item.is_a? Focus::Item
    end

    def focuson input=nil, silent=false
        action = _resolve_focus_item( input , lambda{ pf.list.active.actions })
        _ensure_present action
        @@active = action
        Pomodoro.active_id = action.id
        _update_prompt
        print_summary unless silent
    end
    alias_method :focus, :focuson

    def show input=nil
        _resolve_focus_item( input, lambda { pf.list } )
    end


    def due
        puts "Items due within 3 days"
        pf.list.due.each{ |i| print "  *  " ; ap( i )}
        nil
    end

    def overdue
        overdue = pf.list.overdue.to_a
        unless overdue.empty?
            puts "Overdue items"
            overdue.each{ |i| print "  *  " ; ap( i )}
        end
        nil
    end

    def estimate estimate_or_item
        if estimate_or_item.is_a? Focus::Item
            estimate_or_item.list.active.actions.each{ |a| ap(a) ; _get_estimate a }
        else
            pomo.estimate = estimate
            print_summary
            _update_prompt
        end
    end
    alias_method :est, :estimate

    def _get_estimate item=nil
        item = _resolve_focus_item( input, lambda{ pf.list } ) unless item
        print "Estimate? "
        input = $stdin.gets.chop.to_i
        pomo( item ).estimate = input unless input.blank?
        _update_prompt
        puts
    end

    def start input=nil
        focuson input if input
        _get_estimate( active ) unless pomo.estimated?
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
        item = input ? _resolve_focus_item( input, lambda { pf.list } ) : active
        _ensure_present item
        item_id = item.id
        active_id = active.id
        puts "Toggling status of #{item}"
        `osascript script/Omnifocus/toggle-completed.scpt #{item_id}`
        reload true
        overdue
    end

    def pick initial_filter, choices=pf.list
        found = _selecta( choices.full_names, initial_filter )
        pf.list.detect{ |i| i.full_name.strip == found} if found
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
    alias_method :take, :rest

    def _update_prompt
        Pry.config.prompt_name = "#{active.name.truncate(25, :separator => ' ')} [#{pomo.to_short_s}]  "
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
        nil
    end

    def _tick minute, length
        title = length == 25 ? 'Focus' : 'Rest'
        _tmux_title "#{title}[#{minute}]"
        print "#{minute}/#{length} "
        60.times{ sleep(1) && print('.') }
        puts
    end


    def mis
        show /^MIS$/
    end


    def burndown start_date=nil, end_date=nil
        todos = project.list.actions
        start_date = project.start_date unless start_date
        end_date = project.due_date unless end_date
        if not (start_date and end_date)
            missing = []
            missing << 'start date' unless start_date
            missing << 'due date' unless end_date
            "Please provide missing #{missing.join('/')}"
        else
            html = BurndownChart.new.plot project.name, todos, start_date.to_date, end_date.to_date
            File.open('/tmp/burndown.html', 'w') { |f| f.write(html) }
            `open /tmp/burndown.html`
        end
    end

end

module TreeNavigation

    def right move=1
        index = active.parent.kids.find_index self
        parent.kids[index + move]
    end

    def left move=1
        right( move * -1 )
    end

    def up
        parent
    end

    def down
        kids[0]
    end

    alias_method :h, :left
    alias_method :l, :right
    alias_method :k, :up
    alias_method :j, :down

end

class PryTreeNavigation < Pry::ClassCommand

    match 'cn'
    group 'context'
    description 'Like cd but moves around the Focus tree'

    banner <<-'BANNER'
        Usage: cn [options] [--help]

        Set new focus tree node as Pry context. `cn /` takes you to root, `cn ..`
        takes you up a level, `cn -` might toggle last two nodes.
    BANNER

    def process
        puts pf
        state.old_stack ||= []
        stack, state.old_stack = context_from(arg_string, _pry_, state.old_stack)
        _pry_.binding_stack = stack if stack
    end

    def context_from(arg_string, _pry_, old_stack)
        # copied/ adapted from context_from_object_path, see that impl for comments

        path      = arg_string.split(/\//).delete_if { |a| a =~ /\A\s+\z/ }
        puts "**#{path}**"
        stack     = _pry_.binding_stack.dup
        state_old_stack = old_stack

        if path.empty?
          state_old_stack = stack.dup unless old_stack.empty?
          stack = [stack.first]
        end

        path.each_with_index do |context, i|
          begin
            case context.chomp
            when ""
              state_old_stack = stack.dup
              stack = [stack.first]
            when "::"
              state_old_stack = stack.dup
              stack.push(TOPLEVEL_BINDING)
            when "."
              next
            when "<"
                puts "left"
                stack.push(Pry.binding_for(left))
            when ">"
                stack.push(Pry.binding_for(right))
            when ".."
              unless stack.size == 1
                # Don't rewrite old_stack if we're in complex expression
                # (e.g.: `cd 1/2/3/../4).
                state_old_stack = stack.dup if path.first == ".."
                stack.pop
              end
            when "-"
              unless old_stack.empty?
                # Interchange current stack and old stack with each other.
                stack, state_old_stack = state_old_stack, stack
              end
            else
              state_old_stack = stack.dup if i == 0
              stack.push(Pry.binding_for(stack.last.eval(context)))
            end

          rescue ::Pry::RescuableException => e
            # Restore old stack to its initial values.
            state_old_stack = old_stack

            msg = [
              "Bad object path: #{arg_string}.",
              "Failed trying to resolve: #{context}.",
              e.inspect
            ].join(' ')

            ::Pry::CommandError.new(msg).tap do |err|
              err.set_backtrace e.backtrace
              raise err
            end
          end
        end
        return stack, state_old_stack
    end

end
Pry::Commands.add_command(PryTreeNavigation)


include PomodoroClient
include TreeNavigation
puts
reload
puts
puts
due
puts
puts
puts "{FocusRepl started, access portfolio via pf, set active action via focuson}"
puts
