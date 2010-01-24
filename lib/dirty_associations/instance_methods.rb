module DirtyAssociations
  
  module InstanceMethods

     # Called on an instance of the model whose associations we're interested in.  Inside the block,
     # any modifications required are made to the object, and associations are tracked throughout the duration.
     # After the block is executed, the associations are cleared up, and we stop paying attention.
     def track_association_changes(&block)
       raise ArgumentError, 'Must be called with a block!' unless block_given?
       validate_dirty_associations
       initialize_dirty_associations
       yield
       clear_association_changes
     end

     def initialize_dirty_associations
       self.class.dirty_associations.each do |association|
         builder = DirtyAssociations::Builder.new(association, self)
         builder.generate_dirty_methods!
       end
     end

     # Resets the association records
     def clear_association_changes
       @original_associations = nil
     end

     # Returns true if any of the valid associations have changed since tracking was initiated
     def associations_changed?
       return false if original_associations.empty?
       self.class.dirty_associations.each do |association|
         return true if __send__("#{association}_changed?".to_sym)
       end
       false
     end

     private

     # Copy the initial ids from the association
     def record_initial_association_ids!(association)
       association_name_singular = reflection.to_s.singularize
       if singular_association?(reflection)
         original_associations["#{association_name_singular}_original_id".to_sym] = __send__("#{assoc_name}_id".to_sym).dup
       elsif collection_association?(reflection)
         original_associations["#{association_name_singular}_original_ids".to_sym] = __send__("#{assoc_name}_ids".to_sym).dup
       end
     end


 

     def original_associations
       @original_associations ||= {}
     end

     # Returns boolean if the given association is actually an active association of the current model  
     def is_valid_association?(association_name)
       !self.class.reflect_on_association(association_name.to_sym).nil?
     end
     
     
     # Verify that the associations provided exist #
     def validate_dirty_associations
       self.class.dirty_associations.each do |association_name|
         raise DirtyAssociations::InvalidAssociationError, "#{association_name} does not seem to be a valid association to track" unless is_valid_association?(association_name)
       end
     end

   end
  
end