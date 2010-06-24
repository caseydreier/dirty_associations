module DirtyAssociations
  # This module includes all the logic necessary to generate methods required for a collection 
  # (one-to-many, many-to-many) association's dirty functionality.
  # It also includes the descriptions of each method that will be generated.
  # The following methods are created for collection associations:
  #
  # [collection_changed?]
  #  Returns +true+ if the association collection has changed.
  # [collection_added?]
  #  Returns +true+ if new records have been added to the association collection.
  # [collection_removed?]
  #  Returns +true+ if records have been removed from the association collection.
  # [collection_added]
  #  Returns an array of associated objects that have been added to this collection.
  # [collection_removed]
  #  Returns an array of associated objects that have been removed from the collection, if they still exist.
  #  This will not raise any exceptions if any objects no longer exist, it just won't return them.
  # [collection_were]
  #  Returns an array of the association's objects as they were at the start of association tracking.
  # [collection_singular_ids_changed?]
  #  Returns +true+ if the association collection has changed.
  # [collection_singular_ids_added?]
  #  Returns +true+ if new records have been added to the association collection.
  # [collection_singular_ids_removed?]
  #  Returns +true+ if records have been removed from the association collection.
  # [collection_singular_ids_added]
  #  Returns an array of associated objects' ids that have been added to the collection.
  # [collection_singular_ids_removed]
  #  Returns an array of associated objects' ids that have been removed from the collection.
  # [collection_singular_ids_were]
  #  Returns an array of the associated objects' ids as they were at the start of association tracking.
  module CollectionMethods
    
    # Creates methods for dirty collections associations
    def generate_collection_methods!
      generate_collection_id_methods!
      generate_collection_object_methods!
    end
    
    # This generates the methods for handling calls to _collection_singular_ids_*
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
          primary_key = self.class.reflect_on_association(:#{association_name}).klass.primary_key
          ids_string = #{association_name_singular}_ids_were  * ','
          self.class.reflect_on_association(:#{association_name}).klass.all(:conditions => [primary_key + " IN (" + ids_string + ")"])
        end
        
        # Returns a collection of objects that have been removed from the current record.
        # May not return all records if some were deleted in the interim.
        def #{association_name}_removed
          primary_key = self.class.reflect_on_association(:#{association_name}).klass.primary_key
          self.class.reflect_on_association(:#{association_name}).klass.all(:conditions => { primary_key => #{association_name_singular}_ids_removed})
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