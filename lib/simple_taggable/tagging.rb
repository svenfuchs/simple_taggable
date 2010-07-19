module SimpleTaggable
  class Tagging < ActiveRecord::Base
    set_table_name 'taggings'

    belongs_to :tag, :class_name => 'SimpleTaggable::Tag'
    belongs_to :taggable, :polymorphic => true

    after_destroy :destroy_unused_tag
    
    class << self
      def with_any_tags(taggable, tags)
        with_taggable(taggable) & Tag.named_like_any_of(tags)
      end

      def count_tagged(taggable, tags)
        select('count(*)').joins(:tag).with_any_tags(taggable, tags)
      end
      
      def tagged_ids(taggable, tags)
        select(:taggable_id).joins(:tag).with_any_tags(taggable, tags)
      end
      
      protected

        def with_taggable(taggable)
          p taggable
          where("taggable_id = #{taggable.table_name}.id AND taggable_type = ?", taggable.name)
        end
    end

    def destroy_unused_tag
      tag.destroy if Tag.destroy_unused && tag.taggings.count.zero?
    end
  end
end