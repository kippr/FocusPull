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

def _notify msg
    _term_notify msg, msg
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

def _tick minute, length, start_count
    current_count = inbox_count.to_f
    handled = start_count - current_count
    rate = (handled / minute.to_f).to_i
    remaining = length - minute
    projected = start_count - (rate * remaining)
    msg = "[#{minute}] #{handled.to_i},#{current_count.to_i} ! #{rate}/min ~ #{projected}"
    _tmux_title msg
    _notify msg
    print msg
    60.times{ sleep(1) && print('.') }
    puts
end

def go length=25
    begin
        start_count = inbox_count
        length.times{| minute | _tick minute + 1, length, start_count }
    rescue Interrupt
    else
        end_count = inbox_count
    end
end


_init_tmux_and_notifications
go
