require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

MongoMapper.database = 'acts_as_list_test_db'

describe 'ActsAsList for Mongo Mapper' do    
  before :each do
    (1..4).each do |counter| 
      lm = ListMixin.create! :pos => counter, :parent_id => 5, :original_id => counter 
    end    
  end

  after :each do
    MongoMapper.database.collections.each do |coll|
      coll.drop unless coll.name =~ /(.*\.)?system\..*/
    end        
  end

  def get_positions item
    item.where(:parent_id => 5).order('pos').all.map(&:original_id)
  end
  
  context "4 list items (1,2,3,4) that have parent_id = 5"  do
    describe '# initial configuration' do
      # it "should list items 1 to 4 in order" do
      #   positions = get_positions(ListMixin)        
      #   positions.should == [1, 2, 3, 4]
      # end
    end
  end

  describe '#reordering' do
    it "should move item 2 to position 3" do  
      ListMixin.where(:original_id => 2).first.move_lower            
      get_positions(ListMixin).should == [1, 3, 2, 4]
    end
      
    it "should move item 2 to position 1" do    
      ListMixin.where(:original_id => 2).first.move_higher
      get_positions(ListMixin).should == [2, 1, 3, 4]  
    end
      
    it "should move item 1 to bottom" do    
      ListMixin.where(:original_id => 1).first.move_to_bottom
      get_positions(ListMixin).should == [2, 3, 4, 1]  
    end
    
    it "should move item 1 to top" do    
      ListMixin.where(:original_id => 1).first.move_to_top
      get_positions(ListMixin).should == [1, 2, 3, 4]  
    end
    
    it "should move item 2 to bottom" do    
      ListMixin.where(:original_id => 2).first.move_to_bottom
      get_positions(ListMixin).should == [1, 3, 4, 2]  
    end
    
    it "should move item 4 to top" do    
      ListMixin.where(:original_id => 4).first.move_to_top
      get_positions(ListMixin).should == [4, 1, 2, 3]  
    end 

    it "should move item 3 to bottom" do
      get_positions(ListMixin).should == [1, 2, 3, 4]      
         
      ListMixin.where(:original_id => 3).first.move_to_bottom
      get_positions(ListMixin).should == [1, 2, 4, 3]  
    end
  end
     
  describe 'relative position queries' do
    it "should find item 2 to be lower item of item 1" do
      ListMixin.where(:original_id => 2).first.should == ListMixin.where(:original_id => 1).first.lower_item
    end

    it "should not find any item higher than nr 1" do
      ListMixin.where(:original_id => 1).first.higher_item.should == nil
    end

    it "should find item 3 to be higher item of item 4" do
      ListMixin.where(:original_id => 3).first.should == ListMixin.where(:original_id => 4).first.higher_item
    end

    it "should not find item lower than item 4" do
      ListMixin.where(:original_id => 4).first.lower_item.should == nil
    end
  end
       
  describe 'injection' do
    it "should inject it" do   
      inj = {:parent_id => 1}
      
      item = ListMixin.new(inj)
      item.scope_condition.should == inj
      item.position_column.should == 'pos'      
    end
  end
  
  describe '#insert' do
    it "should let single lonely new item be the first item" do
      lm = ListMixin.create(:parent_id => 20)
      lm.pos.should == 1
      lm.first?.should be_true
      lm.last?.should be_true
    end

    it "should let single lonely new item be the last item" do
      lm = ListMixin.create(:parent_id => 20)
      lm.pos.should == 1
      lm.last?.should be_true
    end

    it "should not the second added item be the first item" do
      lm = ListMixin.create(:parent_id => 20)
      lm2 = ListMixin.create(:parent_id => 20)
      lm2.pos.should == 2
      lm2.first?.should be_false
      lm2.last?.should be_true
    end
    
    it "should let second added item with parent=0 be the first item" do
      lm = ListMixin.create(:parent_id => 20)
      lm2 = ListMixin.create(:parent_id => 0)
      lm2.pos.should == 1
      lm2.first?.should be_true
      lm2.last?.should be_true
    end    
  end  

  describe '#insert at' do

    it "should use insert_at as expected" do
      lm = ListMixin.create(:parent_id => 20)
      lm.pos.should == 1

      lm = ListMixin.create(:parent_id => 20)
      lm.pos.should == 2

      lm = ListMixin.create(:parent_id => 20)
      lm.pos.should == 3
      
      lm4 = ListMixin.create(:parent_id => 20)
      lm4.pos.should == 4
      
      lm4.insert_at(3)
      lm4.pos.should == 3

      lm.reload
      lm.pos.should == 4

      lm.insert_at(2)
      lm.pos.should == 2

      lm4.reload
      lm4.pos.should == 4

      lm5 = ListMixin.create(:parent_id => 20)
      lm5.pos.should == 5

      lm5.insert_at(1)
      lm5.pos.should == 1

      lm4.reload
      lm4.pos.should == 5
            
    end 
  end   

  describe 'delete middle' do
    it "should delete items as expected" do
      get_positions(ListMixin).should == [1, 2, 3, 4]
      ListMixin.where(:original_id => 2).first.destroy    
      get_positions(ListMixin).should == [1, 3, 4]
      ListMixin.where(:original_id => 1).first.destroy    
      get_positions(ListMixin).should == [3, 4]
    end
  end  
end
