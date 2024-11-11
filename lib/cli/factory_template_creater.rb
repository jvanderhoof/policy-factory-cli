# frozen_string_literal: true

module CLI
  # Generates an initial Factory template
  class FactoryTemplateCreator
    def initialize(logger: )
      @logger = logger
    end

    def build(category:, version:, name:)
      target_directory = build_factory_directory(category: category, version: version, name: name)

      create_policy_template(target_directory)
      create_factory_configuration(target_directory)

      @logger.info("Factory stubs generated in: '#{target_directory}'")
    end

    private

    def build_factory_directory(version:, category:, name:)
      version = "v#{version.gsub(/\D/, '')}"
      target_directory = "factories/custom/#{category.underscore}/#{name.underscore}/#{version}"
      FileUtils.mkdir_p(target_directory)
      target_directory
    end

    def create_policy_template(directory)
      if File.exist?("#{directory}/policy.yml")
        @logger.debug("File already exists: '#{directory}/policy.yml'")
      else
        File.open("#{directory}/policy.yml", 'w') do |file|
          file.write("# Place relevant Conjur Policy here.\n")
        end
      end
    end

    def create_factory_configuration(directory)
      if File.exist?("#{directory}/config.json")
        @logger.debug("File already exists: '#{directory}/policy.yml'")
      else
        File.open("#{directory}/config.json", 'w') do |file|
          file.write(
            JSON.pretty_generate(
              {
                title: '',
                description: '',
                variables: {
                  'variable-1': { required: true, description: '' },
                  'variable-2': { description: '' }
                }
              }
            )
          )
        end
      end
    end
  end
end
