module SimpleTaggable
  module InstanceMethods
    def tag_list
      @tag_list ||= cached_tag_list.nil? ? TagList.new(*tags.map(&:name)) : TagList.from(cached_tag_list)
    end

    def tag_list=(value)
      @tag_list = TagList.from(value)
    end

    # def tag_counts(options = {})
    #   self.class.send :with_scope, :find => { :conditions => self.class.send(:tags_condition, tag_list) } do
    #     self.class.tag_counts(options)
    #   end
    # end

    protected

      def cache_tag_list
        self.cached_tag_list = tag_list.to_s
      end

      def reload_with_tag_list(*args)
        @tag_list = nil
        reload_without_tag_list(*args)
      end

      def save_tags
        return unless @tag_list

        new_tag_names = @tag_list - tags.map(&:name)
        old_tags = tags.reject { |tag| @tag_list.include?(tag.name) }

        self.class.transaction do
          unless old_tags.empty?
            taggings.find(:all, :conditions => ["tag_id IN (?)", old_tags]).each(&:destroy)
            taggings.reset
          end
          new_tag_names.each { |name| tags << Tag.find_or_create_by_name(name) }
        end
      end
  end
end
