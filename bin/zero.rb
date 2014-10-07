#!/usr/bin/env ruby

def _init_tmux_and_notifications
    @@tmux_win = `tmux display-message -p '#I'`.chop
    begin
        require 'terminal-notifier'
        @@notifications = true
    rescue LoadError
        $stderr.puts "\nWARNING: terminal-notifier gem not found, no notifications will be posted\n\n"
        @@notifications = false
    end
end

def _term_notify title, message
    if @@notifications
        TerminalNotifier.notify(message, :title => title, :sender => 'com.apple.Terminal', :activate => 'com.apple.Terminal')
    end
    @@notifications
end

def _notify msg, submsg
    _term_notify msg, submsg
end


def inbox_count
    script = <<-END
        tell application "Mail"
            set output  to (count of (messages of inbox))
        end tell
    END
    `echo '#{script}' | osascript`.to_i
end

def _tmux_title title
    `tmux rename-window -t #{@@tmux_win} "#{title}"`
end

def report_progress minute, length, start_count
    current_count = inbox_count.to_f
    handled = start_count - current_count
    rate = (handled / minute.to_f)
    remaining_time = length - minute
    projected_end_count = (start_count - (rate * remaining_time)).to_i
    if rate > 0
        projected_time_to_zero = (current_count / rate).to_i
    else
        projected_time_to_zero = '-'
    end
    actual = "[#{minute}] #{handled.to_i},#{current_count.to_i} ! #{rate.to_i}/min"
    projected = "~ #{projected_end_count}, #{projected_time_to_zero} mins"
    _tmux_title "#{actual} #{projected}"
    _notify actual, projected # if minute % 5 == 0
    puts "#{actual} #{projected}"
end

def _tick minute, length, start_count
    report_progress minute, length, start_count
    60.times{ sleep(1) && print('.') }
    puts
end

def go length=25
    minute = 0
    start_count = inbox_count
    interrupted = false
    begin
        length.times do | x |
            minute = x + 1
            begin
                _tick minute, length, start_count
                interrupted = false
            rescue Interrupt
                break if interrupted
                interrupted = true
            end
        end
    rescue Interrupt
    end
    report_progress minute, length, start_count
    _tmux_title ""
end


_init_tmux_and_notifications
go
