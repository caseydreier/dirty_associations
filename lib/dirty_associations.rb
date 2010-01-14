# This plugin provides a way to track changes made to a Model's associations via their primary keys.
# You can ask if an association has changed, see which previous association's ids have been removed and which ones have been added.
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
  def keep_track_of(*reflections)
    cattr_accessor :dirty_associations
    self.dirty_associations = reflections.flatten.map(&:to_sym)
    
    # Alert the user if no names are defined
    raise ArgumentError, "Please specify associations to track" if self.dirty_associations.empty?
    
    include InstanceMethods
  end
  
  module InstanceMethods
    
    # Called on an instance of the model whose associations we're interested in.  Inside the block,
    # any modifications required are made to the object, and associations are tracked throughout the duration.
    # After the block is executed, the associations are cleared up, and we stop paying attention.
    def track_association_changes(&block)
      raise ArgumentError, 'Must be called with a block!' unless block_given?
      initialize_dirty_associations
      yield
      clear_association_changes
    end
    
    def initialize_dirty_associations
      self.class.dirty_associations.each do |reflection|
        assoc_name = reflection.to_s.singularize
        if is_valid_association?(reflection)
          # TODO: Everything with assoc_name or reflection specified as a param should go
          # into a class to do these calculations.
          record_initial_association_ids!(assoc_name) 
          generate_collection_methods(assoc_name) if collection_association?(reflection)
          generate_singular_methods(assoc_name)   if singular_association?(reflection)
        else
          raise ArgumentError, "#{reflection} does not seem to be a valid association to track.  Please make sure you only use this for collections."
        end
      end
    end
    
    # Resets the association records
    def clear_association_changes
      @original_associations = nil
    end
    
    # Returns true if any of the valid associations have changed since tracking was initiated
    def associations_changed?
      return false if original_associations.empty?
      self.class.dirty_associations.each do |reflection|
        assoc_name = reflection.to_s.singularize
        if respond_to?("#{assoc_name}_ids_changed?".to_sym)
          return true if send("#{assoc_name}_ids_changed?".to_sym)
        end
      end
      false
    end
    
    private
    
    # Generates custom methods for tracking association id history for collection methods (has_many, habtm)
    def generate_collection_methods(assoc_name)
      instance_eval <<-EOV
        def #{assoc_name}_ids_were; (original_associations["#{assoc_name}_original_ids".to_sym] || []).uniq; end;
        def #{assoc_name}_ids_removed(); #{assoc_name}_ids_were - #{assoc_name}_ids; end;
        def #{assoc_name}_ids_removed?(); !#{assoc_name.to_s.singularize}_ids_removed.empty?; end;
        def #{assoc_name}_ids_added(); #{assoc_name}_ids - #{assoc_name}_ids_were; end;
        def #{assoc_name}_ids_added?(); !#{assoc_name}_ids_added.empty?; end;
        def #{assoc_name}_ids_changed?(); #{assoc_name}_ids_added? || #{assoc_name}_ids_removed?; end;
      EOV
    end
    
    # Copy the initial ids from the association
    def record_initial_association_ids!(reflection)
      assoc_name = reflection.to_s.singularize
      if singular_association?(reflection)
        original_associations["#{assoc_name}_original_id".to_sym] = __send__("#{assoc_name}_id".to_sym).dup
      elsif collection_association?(reflection)
        original_associations["#{assoc_name}_original_ids".to_sym] = __send__("#{assoc_name}_ids".to_sym).dup
      end
    end
    
    
    # Determines if the given association is a collection of resources or a single resource
    def association_type(reflection)
      type = self.class.reflect_on_association(reflection.to_sym).macro
      case
      when [:has_many, :has_and_belongs_to_many].include?(type) then :collection
      when [:belongs_to, :has_one].include?(type)               then :singular
      else 
        false
      end
    end
    
    # Returns true if the associations represents a single resource
    def singular_association?(reflection)
      association_type(reflection) == :singular
    end

    # Returns true if the association represents a collection
    def collection_association?(reflection)
      association_type(reflection) == :collection
    end    
    
    def original_associations
      @original_associations ||= {}
    end
    
    # Returns boolean if the given association is actually an active association of the current model  
    def is_valid_association?(association_name)
      !self.class.reflect_on_association(association_name.to_sym).nil?
    end

  end
  
end