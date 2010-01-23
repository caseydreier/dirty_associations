ENV["RAILS_ENV"] = "test"
plugin_test_dir = File.dirname(__FILE__)
require File.join(plugin_test_dir, '../../../../config/environment')
require 'rubygems'
require 'active_support'
require 'active_support/test_case'
require 'test_help'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end

# This loads a custom schema into the DB (usually a SQLite one) for testing purposes of 
# our plugin.  Pulls database.yml and schema.rb from the current test directory of the plugin
def load_test_schema 
  config = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))  
  ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))
  db_adapter = ENV['DB']
  
  # no db passed, try one of these fine config-free DBs before bombing.  
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
