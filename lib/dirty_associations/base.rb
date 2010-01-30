module DirtyAssociations
  module Base
    
    # This is the main class method to define which associations in the model one would like to track changes.
    # This can be called before or after associations are defined.  Validation occurs on object instantiation.
    # You can also just pass the symbol <tt>:all</tt> which will automatically track all available associations.
    #
    # Example:
    #
    #   class Task < ActiveRecord::Base
    #     has_many   :comments
    #     belongs_to :user
    #     has_and_belongs_to_many :keywords
    #
    #     keep_track_of :comments, :keywords
    #   end
    #
    # Or:
    #   class Task < ActiveRecord::Base
    #     #...same association definitions as above...#
    #     keep_track_of :all # => will track :comments, :keywords, and :user
    #   end
    def keep_track_of(*associations)
      raise ArgumentError, "Please specify at least one association to track" if associations.empty?

      cattr_accessor :dirty_associations
      self.dirty_associations = associations.flatten.map(&:to_sym)

      include InstanceMethods
    end
    
  end
end