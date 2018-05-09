require 'logger'

def log(msg, level='debug')
  logger = Logger.new(STDOUT)
  logger.level = $log_level? $log_level.upcase : 'INFO'
  logger.send(level.downcase, "Thread: #{Thread.current.__id__}, #{msg}")
end

