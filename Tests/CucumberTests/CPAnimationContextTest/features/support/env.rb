$: << File.join(File.dirname(__FILE__), '..', '..', 'Cucapp')

require 'cucapp.rb'
require 'logger'

module AppHelper

  def app
    @app ||= Cucapp.new
  end

  def log
    @log ||= ENV['log']
  end

end

World(
  AppHelper
)