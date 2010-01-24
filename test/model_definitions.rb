# These are models to use during the testing instances #

class Task < ActiveRecord::Base 
	 has_many :todos
	 has_many :dependencies, 
	          :foreign_key => "task_id"
   has_many :blocking_tasks, 
            :through => :dependencies
            
	 has_and_belongs_to_many :keywords
	 
   belongs_to :user
   belongs_to :preferred_user, :class_name => "User"
   
   keep_track_of :keywords, :todos, :blocking_tasks, :user, :preferred_user
end 

class User < ActiveRecord::Base 
  has_many :tasks
  has_one  :preferred_task, :class_name => 'Task', :foreign_key => :preferred_user_id
  
  keep_track_of :tasks, :preferred_task
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
