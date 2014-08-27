require "logger"
require "colorize"

module Harpoon
  class Logger < Logger
    SEVS = %w(DEBUG INFO WARN ERROR FATAL PASS FAIL)

    def format_severity(severity)
      SEVS[severity] || 'ANY'
    end

  end
end
