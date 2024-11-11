# frozen_string_literal: true

module CLI
  # Generates a PlantUML mindmap from a RSpec file
  class MindmapBuilder
    def initialize; end

    def build(file_path)
      output = [].tap do |file|
        file << '@startmindmap'
        File.readlines(file_path).each do |line|
          next if /^[\s]+#/.match?(line)

          file << extract_title(line) if line.match(/^describe\(/)
          file << extract_describe(line) if line.match(/describe *'/)
          file << extract_context(line) if line.match(/context *'/)
          file << extract_it(line) if line.match(/it *'/)
        end
        file << '@endmindmap'
      end
      output.join("\n")
    end

    private

    def color(line)
      if /error/.match?(line)
        'Red'
      else
        'LimeGreen'
      end
    end

    def extract_title(line)
      result = line.match(/describe[\s|(]([\w:]+)/)&.captures&.first
      "title #{result}"
    end

    def preceding_whitespaces(line)
      line[/\A */].size
    end

    def whitespace_to_asterisk(count)
      rtn = []
      (count / 2).times { rtn << '*' }
      rtn.join
    end

    def extract_describe(line)
      result = line.match(/describe ["|'][.|#](\w+)["|'] do/)&.captures&.first
      "* #{result.capitalize}"
    end

    def extract_context(line)
      result = line.match(/context ["|']([\w\s-]+)["|'] do/)&.captures&.first
      "#{whitespace_to_asterisk(preceding_whitespaces(line))} #{result.capitalize}"
    end

    def extract_it(line)
      result = line.match(/it ["|']([\w\s-]+)["|'] do/)&.captures&.first
      "#{whitespace_to_asterisk(preceding_whitespaces(line))}[##{color(line)}] It #{result}"
    end

    def extract_class(line)
      line.match(/describe\((.+)\) do/)&.captures&.first
    end
  end
end
