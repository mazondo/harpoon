require "logger"
require "colorize"

module Harpoon
  class Logger < Logger
    SEVS = %w(DEBUG INFO WARN ERROR FATAL SUGGEST PASS FAIL)
    CHECKMARK = "\u2713"
    ARROW = "\u279C"

    def format_severity(severity)
      SEVS[severity] || 'ANY'
    end

    def suggest(message, progname = nil, &block)
      add(5, message, progname, &block)
    end

    def pass(message, progname = nil, &block)
      add(6, message, progname, &block)
    end

    def fail(message, progname = nil, &block)
      add(7, message, progname, &block)
    end

    def format_message(severity, datetime, progname, msg)
      case severity.to_s.downcase
      when "debug"
        "DEBUG: #{msg}\n"
      when "info"
        "#{ARROW} #{msg}\n".colorize(:gray)
      when "warn"
        "#{msg}\n".colorize(:yellow)
      when "error"
        "#{msg}\n".colorize(:orange)
      when "fatal"
        "#{msg}\n".colorize(:red)
      when "pass"
        "#{CHECKMARK} - #{msg}\n".colorize(:green)
      when "fail"
        "X - #{msg}\n".colorize(:red)
      when "suggest"
        "! - #{msg}\n".colorize(:blue)
      else
        "#{severity} - #{msg}\n"
      end
    end

  end
end
