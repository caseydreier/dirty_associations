# This plugin provides a way to track changes made to a Model's associations via their primary keys.
# You can ask if an association has changed, see which previous association's ids have been removed and which ones have been added.
#
# Author::    Casey Dreier
# Copyright:: Copyright (c) 2010
# License::   MIT
#
# You specify the associations to in the parent model.  In order to begin tracking changes, you must explicitly declare 
# your desire to do so.  The instance method +track_association_changes+ accepts a block where you can operate on the object
# as you wish.  Once the block is complete, any recorded changes are wiped clean.
#
# Inside the block, you get the following free methods based on the associations you specified in +keep_track_of+:
#
# * association_singular_ids_changed?
# * association_singular_ids_removed?
# * association_singular_ids_added?
# * association_singular_ids_removed
# * association_singular_ids_added
# 
# As well as a method that tells you if any associations changed:
# * associations_changed? # Note this is actually uses the word, "associations" as the actual method name
#
# === Example
#   class Task < ActiveRecord::Base
#     has_and_belongs_to_many :keywords
#     has_many :blocking_tasks
#     keep_track_of :keywords, :blocking_tasks
#   end
# 
#   task = Task.first
#   task.track_association_changes do
#     task.associations_changed?
#      => false
#
#   task.keyword_ids_changed?
#     => false
#
#   task.keywords << Keyword.first
#   task.keywords << Keyword.last
#
#   task.associations_changed?
#     => true
#
#   task.keyword_ids_changed?
#     => true
#
#   task.keyword_ids_added
#     => [keyword_id1, keyword_id2]
#
#   task.save
#   task.associations_changed?
#     => true
#   end
#   task.associations_changed?
#     => false

module DirtyAssociations
  
  autoload  :Base,                 'dirty_associations/base'
  autoload  :InstanceMethods,      'dirty_associations/instance_methods'
  autoload  :Builder,              'dirty_associations/builder'
  autoload  :CollectionMethods,    'dirty_associations/collection_methods'
  autoload  :SingularMethods,      'dirty_associations/singular_methods'
  
  include DirtyAssociations::Base
  
  class InvalidAssociationError < ArgumentError; end;
  
end