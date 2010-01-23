require 'test_helper'
require 'model_definitions'

class BuilderTest < ActiveSupport::TestCase
  
	load_test_schema
	
	setup :load_test_data
	teardown :remove_test_data
	
	test "builder takes an association name and a model object and sets them automatically" do
	  task = Task.first
	  builder = DirtyAssociations::Builder.new(:keywords, task)
	  assert !builder.association_name.blank?
	  assert !builder.base.blank?
  end
  
  test "the method, is_singular?, should return a boolean false if the association is a collection association" do
    task = Task.first
	  builder = DirtyAssociations::Builder.new(:keywords, task) # keywords is habtm
	  assert !builder.is_singular?
  end
  
  test "the method, is_singular?, should return a boolean true if the association is a singular association" do
    todo = Todo.first
	  builder = DirtyAssociations::Builder.new(:task, todo)     # task is belongs_to
	  assert builder.is_singular?
  end
  
  test "the method, is_collection?, should return a boolean true if the association is a collection association" do
    task = Task.first
	  builder = DirtyAssociations::Builder.new(:blocking_tasks, task) # blocking_tasks is has_many through
	  assert builder.is_collection?
  end

  test "the method, is_collection?, should return a boolean false if the association is a singular association" do
    todo = Todo.first
	  builder = DirtyAssociations::Builder.new(:task, todo)     # task is belongs_to
	  assert !builder.is_collection?
  end
  
  
  
end