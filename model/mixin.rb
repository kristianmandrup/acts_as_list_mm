# see http://www.viget.com/extend/getting-started-with-mongodb-mongomapper/
require 'default_behavior'

class Mixin
  include MongoMapper::Document

  key :pos, Integer
  key :parent_id, Integer
  
  timestamps! # HECK YES   
  
  before_save :log_before_save  
  before_create :add_to_list_bottom #_when_necessary

  def self.table_name 
    "mixins" 
  end

  include DefaultBehavior    
end  
