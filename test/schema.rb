ActiveRecord::Schema.define(:version => 0) do  
  create_table "tasks", :force => true do |t|
    t.string   "name",              :null => false
    t.integer  "user_id",           :precision => 38, :scale => 0, :null => false
    t.integer  "preferred_user_id", :precision => 38, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "users", :force => true do |t|
    t.string   "username"
  end
  
  create_table "keywords", :force => true do |t|
    t.string "word", :limit => 50
  end
  
  create_table "keywords_tasks", :id => false, :force => true do |t|
    t.integer "keyword_id", :precision => 38, :scale => 0
    t.integer "task_id",    :precision => 38, :scale => 0
  end
  
  create_table "todos", :force => true do |t|
    t.integer  "task_id",                    :precision => 38, :scale => 0
    t.string   "description", :limit => 512
    t.boolean  "open",                       :precision => 1,  :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "dependencies", :force => true do |t|
    t.integer "task_id",          :precision => 38, :scale => 0, :null => false
    t.integer "blocking_task_id", :precision => 38, :scale => 0, :null => false
  end
  
  create_table "comments", :force => true do |t|
    t.integer  "parent_id",        :precision => 38, :scale => 0, :null => true
    t.integer  "task_id",          :precision => 38, :scale => 0, :null => false
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
end