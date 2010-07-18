module SimpleTaggable
  class Tagging < ActiveRecord::Base
    set_table_name 'taggings'

    belongs_to :tag, :class_name => 'SimpleTaggable::Tag'
    belongs_to :taggable, :polymorphic => true

    after_destroy :destroy_unused_tag
    
    scope :with_tagged, lambda { |taggable, tags|
      with_taggable(taggable) & Tag.where(:name => tags)
    }

    scope :with_taggable, lambda { |taggable|
      where('taggable_id = ?.id AND taggable_type = ?', taggable.table_name, taggable.name)
    }

    def destroy_unused_tag
      tag.destroy if Tag.destroy_unused && tag.taggings.count.zero?
    end
  end
end