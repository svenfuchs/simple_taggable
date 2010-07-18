module SimpleTaggable
  module ClassMethods
    # TODO
    # conditions << type_condition unless descends_from_active_record?
    
    def tags(*args)
      options = args.extract_options!
      
      tags = Tag.select("DISTINCT tags.*, count(*) AS count").with_taggings(self)
      tags = tags & Tag.at_least(options[:at_least] || 1)
      tags = tags & Tag.at_most(options[:at_most]) if options[:at_most]
      tags = tags & current_scoped_methods if current_scoped_methods.where_values.present? # TODO ... urgs
      tags
    end

    def tagged(tags, options = {})
      valid_keys = [:except, :match_all]
      options.assert_valid_keys *valid_keys
      except, match_all, includes, order = options.values_at(*valid_keys)

      tags   = TagList.from(tags)
      except = TagList.from(options[:except]) if options[:except]

      tagged = joins(:tags) & Tag.where(:name => tags)
      tagged = tagged.with_all_tags(tags)  if match_all
      tagged = tagged.without_tags(except) if except
      tagged.select("DISTINCT #{table_name}.*")
    end
  end
end