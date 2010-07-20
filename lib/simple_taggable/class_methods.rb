module SimpleTaggable
  module ClassMethods
    # TODO conditions << type_condition unless descends_from_active_record?
    def tags(*args)
      options = args.extract_options!
      
      tags = Tag.select("DISTINCT tags.*, count(*) AS count").with_tagged_type(self)
      tags = tags.at_least(options[:at_least] || 1)
      tags = tags.at_most(options[:at_most]) if options[:at_most]
      tags = tags & current_scoped_methods if current_scoped_methods.where_values.present? # TODO ... urgs
      tags
    end

    def tagged(tags, options = {})
      return [] if tags.blank?

      tags   = TagList.from(tags)
      except = TagList.from(options[:except]) if options[:except]

      tagged = joins(:tags)
      tagged = tagged.send(options[:match_all] ? :with_all_tags : :with_any_tags, tags)
      tagged = tagged.without_tags(except) if except
      tagged.select("DISTINCT #{table_name}.*")
    end
    
    protected
    
      def with_any_tags(tags)
        scoped & Tagging.with_taggable(self.taggable_class) & Tag.named_like_any_of(tags)
      end
    
      def with_all_tags(tags)
        where("(#{Tagging.count_tagged(self.taggable_class, tags).to_sql}) = #{tags.size}")
      end
  
      def without_tags(tags)
        # where(arel_table[:id].not_in(Tagging.tagged_ids(self, tags)))
        where("#{table_name}.id NOT IN (#{Tagging.tagged_ids(self, tags).to_sql})")
      end
  end
end