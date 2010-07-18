module SimpleTaggable
  module ActMacro
    def acts_as_taggable(options = {})
      return if acts_as_taggable?

      include SimpleTaggable::InstanceMethods
      extend SimpleTaggable::ClassMethods

      has_many :taggings, :as => :taggable, :dependent => :destroy, :include => :tag, :class_name => 'SimpleTaggable::Tagging'
      has_many :tags, :through => :taggings, :class_name => 'SimpleTaggable::Tag', :source => :tag

      before_save :cache_tag_list
      after_save :save_tags

      alias_method_chain :reload, :tag_list
      
      default_scope :order => options[:order] || :id
    
      scope :with_all_tags, lambda { |tags|
        inclusion = Tagging.select('count(*)').joins(:tag).with_tagged(self, tags)
        where("(#{inclusion.to_sql}) = #{tags.size}")
      }
    
      scope :without_tags, lambda { |tags|
        exclusion = Tagging.select(:taggable_id).joins(:tag).with_tagged(self, tags)
        where("#{table_name}.id NOT IN (#{exclusion.to_sql})")
      }
    end

    def acts_as_taggable?
      included_modules.include?(SimpleTaggable::InstanceMethods)
    end
  end
end