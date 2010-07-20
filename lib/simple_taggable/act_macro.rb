module SimpleTaggable
  module ActMacro
    def acts_as_taggable(options = {})
      return if acts_as_taggable?

      include SimpleTaggable::InstanceMethods
      extend SimpleTaggable::ClassMethods

      has_many :taggings, :as => :taggable, :dependent => :destroy, :include => :tag, :class_name => 'SimpleTaggable::Tagging'
      has_many :tags, :through => :taggings, :class_name => 'SimpleTaggable::Tag', :source => :tag do
        def with_counts(options = {})
          # TODO
        end
      end

      before_save :cache_tag_list
      after_save :save_tags

      alias_method_chain :reload, :tag_list

      default_scope :order => options[:order] || :id

      class_inheritable_accessor :taggable_class
      self.taggable_class = self
    end

    def acts_as_taggable?
      included_modules.include?(SimpleTaggable::InstanceMethods)
    end
  end
end