module SimpleTaggable
  class Tag < ActiveRecord::Base
    set_table_name 'tags'

    has_many :taggings, :class_name => 'SimpleTaggable::Tagging'

    validates_presence_of :name
    validates_uniqueness_of :name

    cattr_accessor :destroy_unused
    self.destroy_unused = true

    class << self
      def with_tagged_type(type) # TODO ...
        joins(:taggings).joins("INNER JOIN #{type.table_name} ON taggings.taggable_id = #{type.table_name}.id AND taggings.taggable_type = '#{type.name}'")
      end

      def find_or_create_named_like(name)
        named_like(name).first || create!(:name => name)
      end

      def named_like(name)
        where(name_matches(name))
      end

      def named_like_any_of(names)
        where(any_of(names.map { |name| name_matches(name) }))
      end

      def at_least(num)
        group('tags.id, tags.name').having(['count(*) >= ?', num])
      end

      def at_most(num)
        group('tags.id, tags.name').having(['count(*) <= ?', num])
      end

      protected

        def name_matches(name)
          arel_table[:name].matches(name)
        end

        def any_of(predicates)
          predicates.inject(predicates.shift) { |result, predicate| result.or(predicate) }
        end
    end

    def count
      self[:count].to_i
    end
  end
end
