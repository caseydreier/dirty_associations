# This plugin provides a way to track changes made to a Model's associations.
# You can ask if an association has changed, see which previous association's ids have been removed and which ones have been added.
#
# Author::    Casey Dreier
# Copyright:: Copyright (c) 2010
# License::   MIT
#
# In order to begin tracking changes, you must explicitly declare your desire to do so.  
# The instance method +track_association_changes+ accepts a block where you can operate on the object
# as you wish, and any association changes made while inside the block will be recorded. 
# Once the block is ended, any recorded changes are wiped clean.
#
# Please see the README for more information and examples.
module DirtyAssociations
  
  autoload  :Base,                 'dirty_associations/base'
  autoload  :InstanceMethods,      'dirty_associations/instance_methods'
  autoload  :Builder,              'dirty_associations/builder'
  autoload  :CollectionMethods,    'dirty_associations/collection_methods'
  autoload  :SingularMethods,      'dirty_associations/singular_methods'
  
  include DirtyAssociations::Base
  
  class InvalidAssociationError < ArgumentError; end;
  
end