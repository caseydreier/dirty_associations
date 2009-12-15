require File.join(File.dirname(__FILE__), 'test_helper.rb')

class Task < ActiveRecord::Base 
	 has_many :todos
	 has_and_belongs_to_many :keywords
	 has_many :dependencies, :foreign_key => "task_id"
   has_many :blocking_tasks, :through => :dependencies
   keep_track_of :keywords, :todos, :blocking_tasks
end 

class Todo < ActiveRecord::Base 
	 belongs_to :task
end

class Keyword < ActiveRecord::Base 
	 has_and_belongs_to_many :tasks
	 
end 

class Dependency < ActiveRecord::Base
  belongs_to :task, :foreign_key => "task_id"
  belongs_to :blocking_task, :class_name => "Task", :foreign_key => "blocking_task_id"
end

class DirtyAssociationsTest < ActiveSupport::TestCase
	load_test_schema
	setup :load_test_data
	teardown :remove_test_data

  test "plugin loads properly" do
    assert Task.respond_to?(:dirty_associations)
    assert_equal 3, Task.dirty_associations.size
    
    task = Task.first
    assert task.respond_to?(:track_association_changes)
  end
  
  # test "throws an error if no associations are specified" do
  #   assert_raise ArgumentError do
  #     class Keyword < ActiveRecord::Base
  #       keep_track_of # this needs arguments....
  #     end
  #   end
  # end
  
  # test "throws an error if one of the provided associations to track is not valid" do
  #   class Dependency < ActiveRecord::Base
  #     keep_track_of :task # can't track one-to-one at the moment
  #   end
  #   
  #   assert_raise ArgumentError do
  #     dep = Dependency.first.begin_tracking_associations
  #   end
  #   
  # end
  
  test "calling begin_tracking_associations initializes the tracking variables" do
    t = Task.first
    t.track_association_changes do
    
      assert t.respond_to?(:keyword_ids_changed?)
  		assert t.respond_to?(:keyword_ids_added?)
  		assert t.respond_to?(:keyword_ids_added)
  		assert t.respond_to?(:keyword_ids_removed?)
  		assert t.respond_to?(:keyword_ids_removed)
  		assert t.respond_to?(:clear_association_changes)

  		assert t.respond_to?(:todo_ids_changed?)
  		assert t.respond_to?(:todo_ids_added?)
  		assert t.respond_to?(:todo_ids_added)
  		assert t.respond_to?(:todo_ids_removed?)
  		assert t.respond_to?(:todo_ids_removed)

  		assert t.respond_to?(:blocking_task_ids_changed?)
  		assert t.respond_to?(:blocking_task_ids_added?)
  		assert t.respond_to?(:blocking_task_ids_added)
  		assert t.respond_to?(:blocking_task_ids_removed?)
  		assert t.respond_to?(:blocking_task_ids_removed)
  		
  	end
  end
  
  test "should record added and removed habtm associations" do
		t = Task.first
		t.track_association_changes do
		
  		# Assert we have keywords #
  		assert t.keywords.size > 0
  		original_keyword_ids = t.keyword_ids.dup
      
  		# Make sure nothing is amiss #
  		assert !t.associations_changed?
  		assert !t.keyword_ids_removed?
  		assert !t.keyword_ids_added?
		
  		# remove keywords #
  		t.keywords.clear
  		assert t.associations_changed?
  		assert t.keyword_ids_removed?
  		assert !t.keyword_ids_added?
		
  		# Make sure we can access the removed IDs #
  		assert t.keyword_ids_removed.is_a?(Array)
  		assert t.keyword_ids_removed.size == original_keyword_ids.size
  		assert_equal original_keyword_ids.sort, t.keyword_ids_removed.sort
		
  		# After the main record saves, the history is *not* reset #
  		assert t.save
  		assert t.associations_changed?
  		assert t.keyword_ids_removed?
  		assert !t.keyword_ids_added?
		
  		# Now try adding a few #
  		t.keywords << Keyword.find_by_word('Unassigned')
  		assert t.associations_changed?
  		assert t.keyword_ids_removed?
  		assert t.keyword_ids_added?
		
  		assert t.keyword_ids_added.is_a?(Array)
  		assert t.keyword_ids_added.size == 1
  		assert t.keyword_ids_added.first == Keyword.find_by_word('Unassigned').id
		
  		# Try building an association and saving a new keyword #
  		t.keywords.create(:word => "Well Tested")
		
  		assert t.keyword_ids_removed?
  		assert t.keyword_ids_added?
  		assert t.keyword_ids_added.size == 2
  		assert t.keyword_ids_added.include?(Keyword.find_by_word("Well Tested").id)
		
  		# History should be maintained after save #
  		t.save
  		assert t.associations_changed?
  		assert t.keyword_ids_removed?
  		assert t.keyword_ids_added?
		end
		
		# Should be cleared after the block #
		assert !t.associations_changed?
		
	end
	
	test "no duplicates in mass-assignment of habtm ids" do
		t = Task.first
		t.track_association_changes do
		
  		original_keyword_ids = t.keyword_ids.dup
  		assert original_keyword_ids.size > 1
  		new_keyword_id = original_keyword_ids.pop
  		t.keyword_ids = [new_keyword_id]
		
  		# Make sure that it didn't record new_keyword_id in removed *and* added via this method
  		# i.e. ActiveRec only deletes the removed ids, not all of them, and then adds back the specified ids #
  		assert t.associations_changed?
  		assert t.keyword_ids_removed?
  		assert !t.keyword_ids_added?
		end
		
		t = Task.first
		t.track_association_changes do
		
  		# Try the same problem from a different method # 		
  		keyword = t.keywords.first
  		t.keywords.clear
  		t.keywords << keyword
		
  		# since this value was both added and removed, there is ultimately no difference #  		
  		assert !t.associations_changed?
  		assert !t.keyword_ids_removed?
  		assert !t.keyword_ids_added? 
		end
		
	end
	
	test "should record added and removed has_many => :through associations" do
		t = Task.find_by_name("Blocked Test")
		t.track_association_changes do
	  	assert t.blocking_tasks.size == 1
  		assert !t.associations_changed?
  		assert !t.blocking_task_ids_removed?
  		assert !t.blocking_task_ids_added?
		
  		# check to see they remove correctly #
  		blocking_task_id = t.blocking_tasks.first.id
		
  		t.blocking_tasks.clear
  		assert t.associations_changed?
  		assert t.blocking_task_ids_removed?
  		assert !t.blocking_task_ids_added?
  		assert t.blocking_task_ids_removed.size == 1
  		assert_equal blocking_task_id, t.blocking_task_ids_removed.first
		end
		
		
	end
	
	
	test "building a new record should count as a changed association but not reflect in the changed ids list until it has an id" do 
	  t = Task.first
	  t.track_association_changes do
  	  assert !t.keyword_ids_changed?
  	  t.keywords.build(:word => "Custom Keyword")
	  
  	  assert !t.keyword_ids_changed?
  	  assert t.keyword_ids_added.empty?
	  
  	  t.save
  	  assert t.keyword_ids_changed?
  	  assert !t.keyword_ids_added.empty?	  
	  end
  end
  
  
	def load_test_data
		t1 = Task.create(:name => "New Test")

		k1 = Keyword.create(:word => "RoR")
		k2 = Keyword.create(:word => "Internet")
		k3 = Keyword.create(:word => "Unassigned")

		t1.keywords << k1
		t1.keywords << k2

		t1.todos.create(:description => "New Todo Item", :open => true)

		t2 = Task.create(:name => "Blocked Test")
		t2.blocking_tasks << t1
	end

	def remove_test_data
		Task.delete_all
		Keyword.delete_all
		Todo.delete_all
		Dependency.delete_all
	end


end