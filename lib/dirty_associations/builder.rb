require 'active_support'

module DirtyAssociations
  class Builder < Struct.new :association_name, :base
    include CollectionMethods
   # include SingularMethods
    
    attr_accessor :association_name_singular
    
    def initialize(association_name,base)
      super(association_name,base)
      self.association_name_singular = self.association_name.to_s.singularize.to_sym
    end

    # Generates the methods used to track the association's changes
    # For collection associations:
    # * collection_plural_were
    # * collection_plural_added?
    # * collection_plural_removed?
    # * collection_plural_added
    # * collection_plural_removed
    # * collection_plural_changed?
    # * collection_singular_ids_were
    # * collection_singular_ids_changed? 
    # * collection_singular_ids_removed?
    # * collection_singular_ids_added?
    # * collection_singular_ids_removed
    # * collection_singular_ids_added
    # 
    # For singular associations:
    # * collection_singular_was
    # * collection_singular_added?
    # * collection_singular_removed?
    # * collection_singular_changed?
    # * collection_singular_id
    # * collection_singular_id_was
    # * collection_singular_id_changed? 
    # * collection_singular_id_removed?
    # * collection_singular_id_added?
    def generate_dirty_methods!
      generate_collection_methods! if is_collection?
      generate_singular_methods   if is_singular?
    end
    
    # Returns boolean if the given association is a collection association (has_many, habtm)
    def is_collection?
      association_type == :collection
    end
    
    # Returns boolean if the given association is a singular association (has_one, belongs_to)
    def is_singular?
      association_type == :singular
    end
    
    # Determines if the given association is a collection of resources or a single resource
    def association_type
      type = self.base.class.reflect_on_association(association_name).macro
      case
      when [:has_many, :has_and_belongs_to_many].include?(type) then :collection
      when [:belongs_to, :has_one].include?(type)               then :singular
      else 
        false
      end
    end
    
  end
end