$: << File.dirname(__FILE__) + '/lib'

require_relative 'apps/dynamic/reference'

Dir['apps/*'].each do |path|
  require_relative path + '/app'
end

if ENV['ROLLBAR_ACCESS_TOKEN']
  require 'rollbar'
  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
  end
end

use Api::App
use CucumberEclipse::App
use Dynamic::App
run Modern::NotFound
