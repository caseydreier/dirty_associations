require File.join( File.dirname(__FILE__), 'test_helper' )
require File.join( File.dirname(__FILE__), 'model_definitions' )

class DirtyAssociationsTest < ActiveSupport::TestCase
  load_test_schema
  
  setup :load_test_data
  teardown :remove_test_data

  test "plugin loads properly" do
    assert Task.respond_to?(:dirty_associations)
    assert_equal 5, Task.dirty_associations.size # the number of associations to track
    
    task = Task.first
    assert task.respond_to?(:enable_dirty_associations)
  end
  
  test "throws an error if no associations are specified" do
    assert_raise ArgumentError do
      class Keyword < ActiveRecord::Base
        keep_track_of # this needs arguments....
      end
    end
  end
  
  test "should record added and removed habtm associations" do
    t = Task.first
    t.enable_dirty_associations do
    
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
    t.enable_dirty_associations do
    
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
    t.enable_dirty_associations do
    
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
    t.enable_dirty_associations do
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
    t.enable_dirty_associations do
      assert !t.keyword_ids_changed?
      t.keywords.build(:word => "Custom Keyword")
    
      assert !t.keyword_ids_changed?
      assert t.keyword_ids_added.empty?
    
      t.save
      assert t.keyword_ids_changed?
      assert !t.keyword_ids_added.empty?    
    end
  end
  
  test "calling the _were method for a has_many association returns the old objects associated with the initial state of the association" do
    # Let's build the initial object and its children #
    task = Task.create(:name => "new task", :user => User.first)
    task.todos.create(:description => "write tests", :open => true)
    task.todos.create(:description => "write more tests", :open => true)
    task.todos.create(:description => "drink", :open => true)
    original_todos = task.todos.dup
    
    task.enable_dirty_associations do
      task.todos.clear
      assert task.todos_changed?
      assert task.todos_removed?
      assert_equal original_todos, task.todos_were
      assert_equal original_todos, task.todos_removed
    end
  end
  
  test "calling the _were method for a has_many association returns a partial result of the original objects if some where deleted" do
    # Let's build the initial object and its children #
    task = Task.create(:name => "new task", :user => User.first)
    task.todos.create(:description => "write tests", :open => true)
    task.todos.create(:description => "write more tests", :open => true)
    task.todos.create(:description => "drink", :open => true)
    original_todos = task.todos.dup    
    
    task.enable_dirty_associations do
      task.todos.first.delete # delete from the db entirely
      task.todos(true)
      assert task.todos_changed?
      assert task.todos_removed? # we still know that something *was* removed, even if it's not in the db anymore
      assert_equal original_todos[1..2], task.todos_were # only loads the two that remain in the db
      assert task.todos_removed.empty?
      assert original_todos.first.id, task.todo_ids_removed.first # we still have the id of the non-existent record
    end
  end
  
  test "calling the _were method for a habtm association returns the old objects associated with the initial state of the association" do
    assert @t1.keywords.size > 0 # keywords is habtm
    original_keywords = @t1.keywords.dup
    
    @t1.enable_dirty_associations do
      @t1.keywords.clear
      assert @t1.keywords_changed?
      assert @t1.keywords_removed?
      assert_equal original_keywords, @t1.keywords_were
      assert_equal original_keywords, @t1.keywords_removed
    end
  end
  
  test "calling the _were method for a habtm association returns a partial result of the original objects if some where deleted" do
    assert @t1.keywords.size > 0 # keywords is habtm
    original_keywords = @t1.keywords.dup
    
    @t1.enable_dirty_associations do
      @t1.keywords.first.delete
      @t1.keywords(true) # reload association
      assert @t1.keywords_changed?
      assert @t1.keywords_removed?
      assert_equal original_keywords[1..original_keywords.size], @t1.keywords_were # only loads the two that remain in the db
      assert @t1.keywords_removed.empty?
      assert original_keywords.first.id, @t1.keyword_ids_removed.first # we still have the id of the non-existent record
    end
  end

  test "calling the _were method for a has_many => :through association returns the old objects associated with the initial state of the association" do
    t = Task.find_by_name("Blocked Test")
    t.enable_dirty_associations do
      assert t.blocking_tasks.size == 1 # blocking_tasks is has_many, through
    
      # check to see they remove correctly #
      original_blocking_task = t.blocking_tasks.first.dup
    
      t.blocking_tasks.clear
      assert t.blocking_tasks_removed?
      assert_equal original_blocking_task, t.blocking_tasks_removed.first
      assert_equal original_blocking_task, t.blocking_tasks_were.first      
    end
  end 

  test "calling the _were method for a has_many => :through association returns partial collection of objects if some were deleted" do
    t = Task.find_by_name("Blocked Test")
    t.enable_dirty_associations do
      assert t.blocking_tasks.size == 1 # blocking_tasks is has_many, through   
      t.blocking_tasks.first.delete
      t.blocking_tasks(true)
      assert t.blocking_tasks_removed?
      assert t.blocking_tasks_were.empty?
      assert t.blocking_tasks_removed.empty?
      assert !t.blocking_task_ids_were.empty?
    end
  end
    
  test "a has_one association returns the proper foreign key via the {singular_association}_id method" do
    task = @preferred_user.preferred_task
    @preferred_user.enable_dirty_associations do 
      assert_equal task.id, @preferred_user.preferred_task_id
    end
  end

  test "a dirty has_one association will report boolean true if it changed" do
    task = @preferred_user.preferred_task
    new_task = Task.first(:conditions => ["id <> ?",task.id] )
    @preferred_user.enable_dirty_associations do 
      @preferred_user.preferred_task = new_task
      assert @preferred_user.preferred_task_changed?
      assert @preferred_user.preferred_task_id_changed?
      assert !@preferred_user.preferred_task_id_added?
      assert !@preferred_user.preferred_task_added?
      assert !@preferred_user.preferred_task_id_removed?
      assert !@preferred_user.preferred_task_removed?
    end    
  end

  test "a dirty has_one association will report boolean true a previously empty association was added" do
    assert @u1.preferred_task.nil?
    new_task = Task.first
    @u1.enable_dirty_associations do 
      @u1.preferred_task = new_task
      assert @u1.preferred_task_changed?
      assert @u1.preferred_task_id_changed?
      assert @u1.preferred_task_added?
      assert @u1.preferred_task_id_added?
      assert !@u1.preferred_task_id_removed?
      assert !@u1.preferred_task_removed?
    end     
  end  

  test "a dirty has_one association will report boolean true for removal only if an existing record was removed" do
    task = @preferred_user.preferred_task
    @preferred_user.enable_dirty_associations do 
      @preferred_user.preferred_task = nil
      assert @preferred_user.preferred_task_changed?
      assert @preferred_user.preferred_task_id_changed?
      assert @preferred_user.preferred_task_removed?
      assert @preferred_user.preferred_task_id_removed?
      assert !@preferred_user.preferred_task_id_added?
      assert !@preferred_user.preferred_task_added?
    end    
  end
  
  test "a dirty has_one association should return the original association's primary key from the _id_was method" do
    task = @preferred_user.preferred_task
    @preferred_user.enable_dirty_associations do 
      @preferred_user.preferred_task = nil
      assert @preferred_user.preferred_task.nil?
      assert_equal task.id, @preferred_user.preferred_task_id_was
    end    
  end
  
  test "a dirty has_one association should return nil from the _was method when the original object no longer exists" do
    task = @preferred_user.preferred_task
    @preferred_user.enable_dirty_associations do 
      @preferred_user.preferred_task.delete # removes object from the database.
      assert_nil @preferred_user.preferred_task_was
    end    
  end

  test "a dirty has_one association should return the old object from the _was method after the original object was de-associated" do
    task = @preferred_user.preferred_task
    @preferred_user.enable_dirty_associations do 
      task.preferred_user_id = nil
      task.save
      assert_nil @preferred_user.preferred_task(true) # refresh this association
      assert_equal task, @preferred_user.preferred_task_was
    end    
  end
  
  test "a dirty belongs_to association will report boolean true for the _changed? method if it was replaced with a new record" do
    task = Task.first
    task.user = User.first # I'm just being explicit here.  Note that this won't be tracked since it's outside of the block.
    task.enable_dirty_associations do
      task.user = User.last
      assert task.user_changed?
      assert !task.user_added?
      assert !task.user_removed?
    end
    
  end

  test "a dirty belongs_to association should report boolean true for the _added? method if a new record was added to an empty association" do
    task = Task.first
    task.preferred_user = nil # Note that this won't be tracked since it's outside of the block.
    task.enable_dirty_associations do
      task.preferred_user = User.last
      assert task.preferred_user_changed?
      assert task.preferred_user_added?
      assert !task.preferred_user_removed?
    end
    
  end
  
  test "a dirty belongs_to association should report boolean true for the _removed? method if the association was removed and not replaced" do
    @task_with_preferred_user.enable_dirty_associations do
      @task_with_preferred_user.preferred_user_id = nil
      @task_with_preferred_user.preferred_user(true)
      assert @task_with_preferred_user.preferred_user_changed?
      assert !@task_with_preferred_user.preferred_user_added?
      assert @task_with_preferred_user.preferred_user_removed?
    end
  end
  
  test "after initialization dirty associations should report no changes have been made" do
    @task_with_preferred_user.enable_dirty_associations do
      assert !@task_with_preferred_user.preferred_user_changed?
      assert !@task_with_preferred_user.user_added?
      assert !@task_with_preferred_user.preferred_user_removed?
    end
  end
  
  test "a dirty belongs_to association should return the original id of the association after a change has been made" do
    original_user_id = @task_with_preferred_user.preferred_user.id
    new_user = User.first(:conditions =>["id <> ?", @task_with_preferred_user.preferred_user_id])
    @task_with_preferred_user.enable_dirty_associations do
      @task_with_preferred_user.preferred_user = new_user
      assert_equal original_user_id, @task_with_preferred_user.preferred_user_id_was
    end
  end
  
  test "a dirty belongs_to association should return the original object of the association after a change has been made, if it exists" do
    original_user = @task_with_preferred_user.preferred_user.dup
    new_user = User.first(:conditions =>["id <> ?", @task_with_preferred_user.preferred_user_id])
    @task_with_preferred_user.enable_dirty_associations do
      @task_with_preferred_user.preferred_user = new_user
      assert_equal original_user, @task_with_preferred_user.preferred_user_was
    end
  end
  
  test "a dirty belongs_to association should return nil if the original object of the association was deleted" do
    @task_with_preferred_user.enable_dirty_associations do
      @task_with_preferred_user.preferred_user.delete
      assert_nil @task_with_preferred_user.preferred_user_was
    end
  end  
  
  test "a dirty belongs_to association should return the original primary_key of the original object even if the association was deleted" do
    original_user_id = @task_with_preferred_user.preferred_user.id
    @task_with_preferred_user.enable_dirty_associations do
      @task_with_preferred_user.preferred_user.delete
      assert_equal original_user_id, @task_with_preferred_user.preferred_user_id_was
    end
  end
  
  test "building a new association for a belongs_to should record change only after the parent record is saved" do
    task = Task.new(:name => "test", :user => User.first)
    task.enable_dirty_associations do
      task.build_preferred_user(:username => 'onthefly')
      assert !task.preferred_user_changed?
      assert !task.preferred_user_added?
      task.save
      assert task.preferred_user_changed?
      assert task.preferred_user_added?      
    end
  end
  
  test "creating a new association through a belongs_to will record the id immediately" do
    task = Task.new(:name => "test", :user => User.first)
    task.enable_dirty_associations do
      task.create_preferred_user(:username => 'onthefly')
      assert task.preferred_user_changed?
      assert task.preferred_user_added?      
    end
  end
  
  test "calling 'keep_track_of :all' should track all listed associations for a model" do
    # The Comment model calls: keep_track_of :all
    @comment1.enable_dirty_associations do
      assert_equal ["task", "responses", "parent"].sort, @comment1.class.dirty_associations.map {|a| a.to_s}.sort
    end
  end
  
  test "association tracking returns valid objects for self-referencing associations" do
    # The Comment model uses a self-referencing association for responses to a comment.
    @comment1.enable_dirty_associations do
      # Create a new child comment
      new_comment = @comment1.responses.create(:body => 'Newest response', :task => @t1)
      
      # Make sure the associations changed properly
      assert @comment1.associations_changed?
      
      # Assert that the added object is the same as the one created
      assert_equal new_comment, @comment1.responses_added.first
    end
  end
  
  # this was added to deal with a bug on MySQL when calling _removed on a non-dirty record
  test "calling the _added and _removed methods for a has_many association on a non-dirty record returns empty" do
    # Let's build the initial object and its children #
    task = Task.create(:name => "new task", :user => User.first)
    task.todos.create(:description => "write tests", :open => true)
    task.todos.create(:description => "write more tests", :open => true)
    task.todos.create(:description => "drink", :open => true)
    
    task.enable_dirty_associations do
      assert task.todos_added.empty?
      assert task.todos_removed.empty?
    end
  end
  
  
end