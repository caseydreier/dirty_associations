require File.join( File.dirname(__FILE__), 'test_helper' )
require File.join( File.dirname(__FILE__), 'model_definitions' )

class BuilderTest < ActiveSupport::TestCase
  
  load_test_schema
  
  setup :load_test_data
  teardown :remove_test_data
  
  test "builder takes an association name and a model object and sets them automatically" do
    task = Task.first
    builder = DirtyAssociations::Builder.new(:keywords, task)
    assert !builder.association_name.blank?
    assert !builder.base.blank?
    assert !builder.association_name_singular.blank?
  end
  
  test "on initialize, the builder sets the singular version of the association name" do
    task = Task.first
    builder = DirtyAssociations::Builder.new(:keywords, task)
    assert_equal :keyword, builder.association_name_singular    
  end
  
  
  test "the method, association_is_singular?, should return a boolean false if the association is a collection association" do
    task = Task.first
    builder = DirtyAssociations::Builder.new(:keywords, task) # keywords is habtm
    assert !builder.association_is_singular?
  end
  
  test "the method, association_is_singular?, should return a boolean true if the association is a singular association" do
    todo = Todo.first
    builder = DirtyAssociations::Builder.new(:task, todo)     # task is belongs_to
    assert builder.association_is_singular?
  end
  
  test "the method, association_is_collection?, should return a boolean true if the association is a collection association" do
    task = Task.first
    builder = DirtyAssociations::Builder.new(:blocking_tasks, task) # blocking_tasks is has_many through
    assert builder.association_is_collection?
  end

  test "the method, association_is_collection?, should return a boolean false if the association is a singular association" do
    todo = Todo.first
    builder = DirtyAssociations::Builder.new(:task, todo)     # task is belongs_to
    assert !builder.association_is_collection?
  end
  
  test "calling generate_dirty_methods! will create a series of methods for a collection association" do
    task = Task.first
    builder = DirtyAssociations::Builder.new(:keywords, task)
    builder.generate_dirty_methods!
    
    assert task.respond_to?(:keywords_were)   
    assert task.respond_to?(:keywords_changed?)
    assert task.respond_to?(:keywords_added?)
    assert task.respond_to?(:keywords_added)
    assert task.respond_to?(:keywords_removed?)
    assert task.respond_to?(:keywords_removed)
    
    assert task.respond_to?(:keyword_ids_were)    
    assert task.respond_to?(:keyword_ids_changed?)
    assert task.respond_to?(:keyword_ids_added?)
    assert task.respond_to?(:keyword_ids_added)
    assert task.respond_to?(:keyword_ids_removed?)
    assert task.respond_to?(:keyword_ids_removed)
  end
  
  test "calling generate_dirty_methods! will create a series of methods for a singular association" do
    todo = Todo.first
    builder = DirtyAssociations::Builder.new(:task, todo)
    builder.generate_dirty_methods!
    
    assert todo.respond_to?(:task_was)    
    assert todo.respond_to?(:task_changed?)
    assert todo.respond_to?(:task_removed?)
    assert todo.respond_to?(:task_added?)
    assert todo.respond_to?(:task_id)
    assert todo.respond_to?(:task_id_was)   
    assert todo.respond_to?(:task_id_changed?)
    assert todo.respond_to?(:task_id_removed?)
    assert todo.respond_to?(:task_id_added?)   
        
  end
  
  
  
end