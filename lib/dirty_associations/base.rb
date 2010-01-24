module DirtyAssociations
  module Base #:nodoc:
    
    # This is the main class method to define which associations in the model one would like to make dirty.
    # This can be called before or after associations are defined.  Validation occurs on object instantiation.
    def keep_track_of(*associations)
      raise ArgumentError, "Please specify at least one association to track" if associations.empty?

      cattr_accessor :dirty_associations
      self.dirty_associations = associations.flatten.map(&:to_sym)

      include InstanceMethods
    end
    
  end
end