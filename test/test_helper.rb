ENV["RAILS_ENV"] = "test"
plugin_test_dir = File.dirname(__FILE__)
require File.join(plugin_test_dir, '../../../../config/environment')
require 'test_help'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end

# This loads a custom schema into the DB (usually a SQLite one) for testing purposes of 
# our plugin.  Pulls database.yml and schema.rb from the current test directory of the plugin.
def load_test_schema 
  config = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))  
  ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))
  db_adapter = ENV['DB']
  
  # no db passed, try one of these DBs before bombing.  
  db_adapter ||= begin 
    require 'sqlite'  
      'sqlite'
    rescue MissingSourceFile 
      begin 
        require 'sqlite3'  
        'sqlite3'  
      rescue MissingSourceFile 
      end  
    end 

  if db_adapter.nil? 
    raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."  
  end 

  # Load our plugin test schema into our DB #
  ActiveRecord::Base.establish_connection(config[db_adapter])  
  load(File.join(File.dirname(__FILE__), "schema.rb"))
  require File.join(File.dirname(__FILE__), '../init.rb')
end

# Populates our test db with some records.
def load_test_data
  @u1 = User.create(:username => "Alfonzo")
  @preferred_user = User.create(:username => "Mortanzo")
  
  @t1 = Task.create(:name => "New Test", :user => @u1)
  
  @k1 = Keyword.create(:word => "RoR")
  @k2 = Keyword.create(:word => "Internet")
  @k3 = Keyword.create(:word => "Unassigned")
  
  @t1.keywords << @k1
  @t1.keywords << @k2
  
  @comment1 = @t1.comments.create(:body => 'Comment text')
  @comment1_response = @comment1.responses.create(:body => "Comment response", :task => @t1)
  
  @t1.todos.create(:description => "New Todo Item", :open => true)
  
  @task_with_preferred_user = Task.create(:name => "Blocked Test", :user => @u1, :preferred_user => @preferred_user)
  @task_with_preferred_user.blocking_tasks << @t1
end

# Removes all test data from our test db.
def remove_test_data
  Task.delete_all
  Keyword.delete_all
  Todo.delete_all
  Dependency.delete_all
end
