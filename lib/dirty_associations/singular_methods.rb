module DirtyAssociations
  module SingularMethods
    SINGULAR_METHOD_SUFFIXES = ['_was', '_changed?', '_removed?', '_added?', '_id']
    
    def generate_singular_methods!
      generate_singular_id_methods!
      generate_singular_object_methods!    
    end
    
    def generate_singular_id_methods!
      self.base.instance_eval <<-EOV
        # Returns the primary_key of the current association record
        def #{association_name}_id()
          #{association_name}.id
        end
        
        # Returns the original id of the association at the start of association tracking
        def #{association_name}_id_was
          original_associations["#{association_name}_original_id"].to_sym ||= nil
        end
        
        # Boolean if the association has been removed and not replaced
        def #{association_name}_id_removed?
          #{association_name}.nil?
        end
        
        # Boolean if the association was added where there previous was none before
        def #{association_name}_id_added?
          #{association_name}_id_was.nil?
        end
        
        # Boolean if the association has changed
        def #{association_name}_id_changed?
          !(#{association_name}_id == #{association_name}_id_was)
        end
        
      EOV
    end
    
    def generate_singular_object_methods!
      self.base.instance_eval <<-EOV
        # Returns the old activerecord object, or nil if the object no longer exists
        def #{association_name}_was
          begin
            #{association_name}.find(#{association_name}_id_was)
          rescue ActiveRecord::RecordNotFound
            nil
          end
        end
        
        # The boolean methods behave exactly the same as their _id counterparts
                                     
        alias #{association_name}_removed? #{association_name}_id_removed?
        alias #{association_name}_changed? #{association_name}_id_changed?
        alias #{association_name}_added?   #{association_name}_id_added?
        
      EOV
      
    end
    
  end 
end