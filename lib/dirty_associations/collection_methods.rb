module DirtyAssociations
  module CollectionMethods
    
    # Creates methods for dirty collections associations
    def generate_collection_methods!
      generate_collection_object_methods!
      generate_collection_id_methods!
    end
    
    def generate_collection_id_methods!
      base.instance_eval <<-EOV
        def #{association_name_singular}_ids_were; (original_associations["#{association_name_singular}_original_ids".to_sym] || []).uniq; end;
        def #{association_name_singular}_ids_removed(); #{association_name_singular}_ids_were - #{association_name_singular}_ids; end;
        def #{association_name_singular}_ids_removed?(); !#{association_name_singular}_ids_removed.empty?; end;
        def #{association_name_singular}_ids_added(); #{association_name_singular}_ids - #{association_name_singular}_ids_were; end;
        def #{association_name_singular}_ids_added?(); !#{association_name_singular}_ids_added.empty?; end;
        def #{association_name_singular}_ids_changed?(); #{association_name_singular}_ids_added? || #{association_name_singular}_ids_removed?; end;
      EOV
    end
    
    def generate_collection_object_methods!
      base.instance_eval <<-EOV
         def #{association_name}_were; (original_associations["#{association_name_singular}_original_ids".to_sym] || []).uniq; end;
         def #{association_name}_removed(); #{association_name_singular}_ids_were - #{association_name_singular}_ids; end;
         def #{association_name}_removed?(); !#{association_name_singular}_ids_removed.empty?; end;
         def #{association_name}_added(); #{association_name_singular}_ids - #{association_name}_ids_were; end;
         def #{association_name}_added?(); !#{association_name_singular}_ids_added.empty?; end;
         def #{association_name}_changed?(); #{association_name_singular}_ids_added? || #{association_name_singular}_ids_removed?; end;
       EOV
             
    end
    
    
    
  end
end