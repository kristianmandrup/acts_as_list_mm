require 'rspec'
require 'rspec/autorun'
require 'mongo_mapper'
require 'acts_as_list_mm'

$:.unshift "#{File.dirname(__FILE__)}/../model/"

require 'mixin'
require 'list_mixin'

RSpec.configure do |config|
#  config.include(Matchers)  
end