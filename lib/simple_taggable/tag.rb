module SimpleTaggable
  class Tag < ActiveRecord::Base
    set_table_name 'tags'
    
    has_many :taggings, :class_name => 'SimpleTaggable::Tagging'

    validates_presence_of :name
    validates_uniqueness_of :name

    cattr_accessor :destroy_unused
    self.destroy_unused = true
    
    scope :tags, lambda { |*args|
      options = args.extract_options!
      tags = joins(:tags).select('DISTINCT tags.*, count(*) AS count')
      tags = tags & Tag.at_least(options[:at_least] || 1)
      tags = tags & Tag.at_least(options[:at_most]) if options[:at_most]
      tags
    }
    
    scope :with_taggings, lambda { |type| # TODO ... urgs
      joins(:taggings).joins("INNER JOIN #{type.table_name} ON taggings.taggable_id = #{type.table_name}.id AND taggings.taggable_type = '#{type.name}'")
    }
      
    scope :at_least, lambda { |num|
      group('tags.id, tags.name').having('count(*) >= ?', num)
    }
    
    scope :at_most, lambda { |num|
      group('tags.id, tags.name').having('count(*) <= ?', num)
    }

    # class << self
    #   def find_or_create_by_name(name)
    #     find(:first, :conditions => ["name LIKE ?", name]) || create(:name => name)
    #   end
    # end
    # 
    # def count
    #   read_attribute(:count).to_i
    # end
    # 
    # def ==(object)
    #   super || (object.is_a?(Tag) && name == object.name)
    # end
    # 
    # def to_s
    #   name
    # end
    # alias :to_param :to_s
  end
end