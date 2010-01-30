module DirtyAssociations
  
  module InstanceMethods

     # Called on an instance of the model whose associations we're interested in.  Inside the block,
     # any changes to the associations are tracked. After the block is executed, the associations are reset.
     def enable_dirty_associations(&block)
       raise ArgumentError, 'Must be called with a block!' unless block_given?
       
       # If the user passes ":all", scan the model and set tracking on all the associations
       # That is unless there is an "all" assocition defined, in which case, continue without setting all assocations
       populate_dirty_associtaions_with_all_associations! if !is_valid_association?(:all) && self.class.dirty_associations.delete(:all)
       
       # Go and validate to make sure these associations are named properly
       validate_dirty_associations
       
       # Initialize the initial values and construct the dirty methods for each association
       initialize_dirty_associations
       yield
       
       # Clear out when the block ends
       clear_association_changes
     end

     # Generate the methods for each association, and record the initial state of each association specified.
     def initialize_dirty_associations
       self.class.dirty_associations.each do |association|
         builder = DirtyAssociations::Builder.new(association, self)
         builder.generate_dirty_methods!
         
         # Record the initial state of the association #
         case
         when builder.association_is_collection?  then  record_initial_collection_association_state!(association)
         when builder.association_is_singular?    then  record_initial_singular_association_state!(association)
         end
       end
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

     # Record the association id from a singular association
     def record_initial_singular_association_state!(association)
       original_associations["#{association}".to_sym] = __send__("#{association}_id".to_sym)
     end

     # Record the association ids from a collection association     
     def record_initial_collection_association_state!(association)
       original_associations["#{association}".to_sym] = __send__("#{association.to_s.singularize}_ids".to_sym).dup
     end
     
     # Holds the original association ids for tracked associations
     def original_associations
       @_original_associations ||= {}
     end
     
     # Resets the association records
     def clear_association_changes
       @_original_associations = {}
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
     
     # Collect all association names and populate the class variable +dirty_associations+ with them.
     def populate_dirty_associtaions_with_all_associations!
       self.class.dirty_associations = self.class.reflect_on_all_associations.map(&:name)
     end

   end
  
end