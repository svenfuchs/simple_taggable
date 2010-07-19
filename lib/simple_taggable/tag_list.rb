module SimpleTaggable
  class TagList < Array
    cattr_accessor :delimiter
    self.delimiter = ' '

    class << self
      def from(*strings)
        strings = strings.flatten
        new.tap do |tag_list|
          strings.each do |string|
            string = string.to_s.dup
            string.gsub!(/"(.*?)"\s*#{delimiter}?\s*/) { tag_list << $1; '' }
            string.gsub!(/'(.*?)'\s*#{delimiter}?\s*/) { tag_list << $1; '' }
            tag_list.add(*string.split(delimiter))
          end
        end
      end
    end

    attr_reader :owner

    def initialize(*names)
      add(*names)
    end

    def add(*names)
      normalize!(names)
      concat(names)
      clean!
      self
    end

    def remove(*names)
      normalize!(names)
      delete_if { |name| names.include?(name) }
      self
    end
    
    def to_s
      tags = map { |tag| tag.include?(delimiter) ? "\"#{tag}\"" : tag }
      tags.join(delimiter.ends_with?(" ") ? delimiter : "#{delimiter} ")
    end

    private

      def clean!
        reject!(&:blank?)
        map!(&:strip)
        uniq!
      end

      def normalize!(args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        args.map! { |a| self.class.from(a) } if options[:parse]
        args.flatten!
      end
  end
end