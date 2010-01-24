module DirtyAssociations
  module CollectionMethods
    
    # Creates methods for dirty collections associations
    def generate_collection_methods!
      generate_collection_id_methods!
      generate_collection_object_methods!
    end
    
    # This generates the methods for handling calls to collection_singular_ids*
    # They return the primary keys of the association records that have changed,
    # as well as adding a few boolean methods to quickly determine if they've changed at all.
    def generate_collection_id_methods!
      base.instance_eval <<-EOV
      
        # Returns an array of primary keys of the original state of this association when tracking began.
        def #{association_name_singular}_ids_were
          (original_associations["#{association_name}".to_sym] || []).uniq
        end
        
        # Return an array of primary keys of removed association records.
        def #{association_name_singular}_ids_removed
          #{association_name_singular}_ids_were - #{association_name_singular}_ids
        end
        
        # Boolean if records have been removed from this association since tracking began.
        def #{association_name_singular}_ids_removed?
          !#{association_name_singular}_ids_removed.empty?
        end
        
        # Return an array of primary keys of associations that have been added to this record since tracking began.
        def #{association_name_singular}_ids_added
          #{association_name_singular}_ids - #{association_name_singular}_ids_were
        end
        
        # Boolean if records have been added to this association.
        def #{association_name_singular}_ids_added?
          !#{association_name_singular}_ids_added.empty?
        end
        
        # Boolean if records have been added or removed from this association.
        def #{association_name_singular}_ids_changed?
          #{association_name_singular}_ids_added? || #{association_name_singular}_ids_removed?
        end
        
      EOV
    end
    
    # These methods are similar to the _ids methods, but instead of returning just the primary
    # keys of the association changes, they attempt to return the actual records themselves, if they still exist.
    def generate_collection_object_methods!
      base.instance_eval <<-EOV
        # Returns a collection of objects previously associated with this record
        # Not guaranteed to return all records, since some may have been deleted from the database in the interim.
        def #{association_name}_were
          #{association_name}.find(#{association_name_singular}_ids_were)
        end
        
        # Returns a collection of objects that have been removed from the current record.
        # May not return all records if some were deleted in the interim.
        def #{association_name}_removed
          #{association_name}.find(#{association_name_singular}_ids_removed)
        end
        
        # Returns a collection of objects that have been added to the current record since tracking began.
        def #{association_name}_added
          #{association_name}.find(#{association_name_singular}_ids_added)
        end
        
        # The boolean methods return the same result as the _ids versions, so lets just alias those
        alias #{association_name}_added?   #{association_name_singular}_ids_added?
        alias #{association_name}_changed? #{association_name_singular}_ids_changed?
        alias #{association_name}_removed? #{association_name_singular}_ids_removed?
       EOV
             
    end
    
    
    
  end
end