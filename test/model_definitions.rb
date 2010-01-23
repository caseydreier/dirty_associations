# These are models to use during the testing instances #

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
