module ActsAsList
  module MongoMapper  
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    module ClassMethods
  		def acts_as_list(options = {})
  			configuration = { :column => "position", :scope => {} }
  			configuration.update(options) if options.is_a?(Hash)
  			configuration[:scope] = "#{configuration[:scope]}_id".intern if configuration[:scope].is_a?(Symbol) && configuration[:scope].to_s !~ /_id$/

  			if configuration[:scope].is_a?(Symbol)
  				scope_condition_method = %(
  				  def scope_condition
  				    if #{configuration[:scope].to_s}.nil?
  				      {}
  				    else
  							{ "#{configuration[:scope].to_s}" => "\#{#{configuration[:scope].to_s}}" }.symbolize_keys!
  				    end
  				  end
  				)
  			end

  			class_eval <<-EOV
  					include ActsAsList::MongoMapper::InstanceMethods

  					def acts_as_list_class
  					  ::#{self.name}
  					end

  					def position_column
  					  '#{configuration[:column]}'
  					end

  					#{scope_condition_method}

  					before_destroy :remove_from_list
  					before_create  :add_to_list_bottom, :unless => :in_list?
  				EOV
  		end
    end
  
    module InstanceMethods

  		# Insert the item at the given position (defaults to the top position of 1).
      def insert_in_list_at(position = 1)
        insert_at_position(position)
      end

      # Swap positions with the next lower item, if one exists.
      def move_lower
        return unless lower_item

  			lower_item.decrement_position
        increment_position
      end

      # Swap positions with the next higher item, if one exists.
      def move_higher
        return unless higher_item

        higher_item.increment_position
        decrement_position
      end

      # Move to the bottom of the list. If the item is already in the list, the items below it have their
      # position adjusted accordingly.
      def move_to_bottom
        return unless in_list?

        decrement_positions_on_lower_items
        assume_bottom_position
      end

      # Move to the top of the list. If the item is already in the list, the items above it have their
      # position adjusted accordingly.
      def move_to_top
        return unless in_list?

        increment_positions_on_higher_items
        assume_top_position
      end

      # Removes the item from the list.
      def remove_from_list
        if in_list?
          decrement_positions_on_lower_items
  				self.set( position_column => nil )
  				self[position_column] = nil
        end
      end

      # Increase the position of this item without adjusting the rest of the list.
      def increment_position
        return unless in_list?
  			pos = self.send(position_column)+1
  			self.set( position_column => pos )
  			self[position_column] = pos
      end

      # Decrease the position of this item without adjusting the rest of the list.
      def decrement_position
        return unless in_list?
  			pos = self.send(position_column)-1
  			self.set( position_column => pos )
  			self[position_column] = pos
      end

      # Return +true+ if this object is the first in the list.
      def first?
        return false unless in_list?
        self.send(position_column) == 1
      end

      # Return +true+ if this object is the last in the list.
      def last?
        return false unless in_list?
        self.send(position_column) == bottom_position_in_list
      end

      # Return the next higher item in the list.
      def higher_item
        return nil unless in_list?
  			conditions = scope_condition
  			conditions.merge!( { position_column.to_sym.lt => self.send(position_column).to_i} )
  			acts_as_list_class.first( :conditions => conditions, :order => "#{position_column} desc" ) 
      end

      # Return the next lower item in the list.
      def lower_item
        return nil unless in_list?
  			conditions = scope_condition
  			conditions.merge!( { position_column.to_sym.gt => self.send(position_column).to_i} )
  			acts_as_list_class.first( :conditions => conditions, :order => "#{position_column} asc" ) 
      end

      # Test if this record is in a list
      def in_list?
        !send(position_column).nil?
      end

  		# sorts all items in the list
  		# if two items have same position, the one created more recently goes first
  		def sort
  			conditions = scope_condition
  			list_items = acts_as_list_class.all(:conditions => conditions, :order => "#{position_column} asc, created_at desc")
  			list_items.each_with_index do |list_item, index|
  				list_item.set( position_column => index+1 )
  				list_item[position_column] = index+1
  			end
  		end

      private 
      
      def add_to_list_top
        increment_positions_on_all_items
      end

      def add_to_list_bottom
        self[position_column] = bottom_position_in_list.to_i + 1
      end

      # Overwrite this method to define the scope of the list changes
      def scope_condition
  			{}
  		end

      # Returns the bottom position number in the list.
      #   bottom_position_in_list    # => 2
      def bottom_position_in_list(except = nil)
        item = bottom_item(except)
        item ? item.send(position_column) : 0
      end

      # Returns the bottom item
      def bottom_item(except = nil)				
  			conditions = scope_condition
  			conditions.merge!( { :id.ne => except.id } ) if except
  			acts_as_list_class.first( 
  				:conditions => conditions, 
  				:order => "#{position_column} desc" ) 
      end

      # Forces item to assume the bottom position in the list.
      def assume_bottom_position
  			pos = bottom_position_in_list(self).to_i+1
  			self.set( position_column => pos )
  			self[position_column] = bottom_position_in_list(pos)
      end

      # Forces item to assume the top position in the list.
      def assume_top_position
  			self.set( position_column => 1 )
  			self[position_column] = 1
      end

      # This has the effect of moving all the higher items up one.
      def decrement_positions_on_higher_items(position)
  			conditions = scope_condition
  			conditions.merge!( { position_column.to_sym.lt => position } )
  			acts_as_list_class.decrement( conditions, { position_column => 1 } ) 
      end

      # This has the effect of moving all the lower items up one.
      def decrement_positions_on_lower_items
        return unless in_list?
  			conditions = scope_condition
  			conditions.merge!( { position_column.to_sym.gt => self.send(position_column).to_i } )
  			acts_as_list_class.decrement( conditions, { position_column => 1 } )
      end

      # This has the effect of moving all the higher items down one.
      def increment_positions_on_higher_items
        return unless in_list?
  			conditions = scope_condition
  			conditions.merge!( { position_column.to_sym.lt => self.send(position_column).to_i } )
  			acts_as_list_class.increment( conditions, { position_column => 1 } )
      end

      # This has the effect of moving all the lower items down one.
      def increment_positions_on_lower_items(position)
  			conditions = scope_condition
  			conditions.merge!( { position_column.to_sym.gte => position } )
  			acts_as_list_class.increment( conditions, { position_column => 1 } )
      end

      # Increments position (<tt>position_column</tt>) of all items in the list.
      def increment_positions_on_all_items
  			conditions = scope_condition
  			acts_as_list_class.increment( conditions, { position_column => 1 } )
      end

      def insert_at_position(position)
        remove_from_list
        increment_positions_on_lower_items(position)
  			self.set( position_column => position )
  			self[position_column] = position
      end
    end
  end    
end