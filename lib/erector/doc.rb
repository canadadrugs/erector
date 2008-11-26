module Erector
  # A proxy to an IO object that adds methods to add xml.
  class Doc

    cattr_accessor :prettyprint_default

    NON_NEWLINEY = {'i' => true, 'b' => true, 'small' => true,
      'img' => true, 'span' => true, 'a' => true,
      'input' => true, 'textarea' => true, 'button' => true, 'select' => true
    }

    SPACES_PER_INDENT = 2

    attr_reader :widget
    attr_accessor :enable_prettyprint

    def initialize(widget, options = {})
      @widget = widget
      @at_start_of_line = true
      @indent = 0
      @enable_prettyprint = prettyprint_default
    end

    def output
      widget.output
    end

    def newliney(tag_name)
      if @enable_prettyprint
        !NON_NEWLINEY.include?(tag_name)
      else
        false
      end
    end

    def open_tag(tag_name, attributes={})
      indent_for_open_tag(tag_name)
      @indent += SPACES_PER_INDENT

      output.concat "<#{tag_name}#{format_attributes(attributes)}>"
      @at_start_of_line = false
    end

    def text(value)
      output.concat(value.html_escape)
      @at_start_of_line = false
      nil
    end

    def close_tag(tag_name)
      @indent -= SPACES_PER_INDENT
      indent()

      output.concat("</#{tag_name}>")

      if newliney(tag_name)
        output.concat "\n"
        @at_start_of_line = true
      end
    end

    def indent_for_open_tag(tag_name)
      if !@at_start_of_line && newliney(tag_name)
        output.concat "\n"
        @at_start_of_line = true
      end

      indent()
    end

    def indent()
      if @at_start_of_line
        output.concat " " * @indent
      end
    end

    def empty_element(tag_name, attributes={})
      indent_for_open_tag(tag_name)

      output.concat "<#{tag_name}#{format_attributes(attributes)} />"

      if newliney(tag_name)
        output.concat "\n"
        @at_start_of_line = true
      end
    end

    def instruct(attributes={:version => "1.0", :encoding => "UTF-8"})
      output.concat "<?xml#{format_sorted(sort_for_xml_declaration(attributes))}?>"
    end

    def to_s
      output.to_s
    end

    protected
    def method_missing(method_name, *args, &blk)
      output.__send__(method_name, *args, &blk)
    rescue NoMethodError => e
      raise NoMethodError, "undefined method `#{method_name}' for #{inspect}"
    end

    def format_attributes(attributes)
      return "" if !attributes || attributes.empty?
      return format_sorted(sorted(attributes))
    end

    def format_sorted(sorted)
      results = ['']
      sorted.each do |key, value|
        if value
          if value.is_a?(Array)
            value = [value].flatten.join(' ')
          end
          results << "#{key}=\"#{value.html_escape}\""
        end
      end
      return results.join(' ')
    end

    def sorted(attributes)
      stringized = []
      attributes.each do |key, value|
        stringized << [key.to_s, value]
      end
      return stringized.sort
    end

    def sort_for_xml_declaration(attributes)
      # correct order is "version, encoding, standalone" (XML 1.0 section 2.8).
      # But we only try to put version before encoding for now.
      stringized = []
      attributes.each do |key, value|
        stringized << [key.to_s, value]
      end
      return stringized.sort{|a, b| b <=> a}
    end
  end
end
