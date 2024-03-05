# frozen_string_literal: true

require 'base64'

module Compiler
  class GenerateFactory
    def initialize(name:, version:, classification:)
      @name = name
      @version = version
      @classification = classification
    end

    def generate(policy_template:, configuration:)
      if policy_template.nil? && configuration['policy_type'].present?
        policy_template = File.read("lib/compiler/policy_types/#{configuration['policy_type'].underscore}.yml")
      end
      schema = generate_schema(configuration: configuration)
      factory_policy_template = generate_policy_template(
        configuration: configuration,
        policy_template: policy_template
      )
      puts(schema.inspect)
      puts
      puts(factory_policy_template)
      puts '--------'
      create_factory(
        schema: schema,
        policy_template: factory_policy_template,
        configuration: configuration
      )
    end

    private

    def create_factory(schema:, policy_template:, configuration:)
      Base64.strict_encode64(
        {
          version: @version,
          policy: Base64.strict_encode64(policy_template),
          policy_branch: default_policy_branch(configuration),
          schema: schema
        }.to_json
      )
    end

    def default_policy_branch(configuration)
      if configuration['default_policy_branch'].to_s.empty?
        '<%= branch %>'
      else
        configuration['default_policy_branch']
      end
    end

    def generate_policy_template(configuration:, policy_template:)
      return policy_template if configuration['wrap_with_policy'].to_s.downcase == 'false'

      [
        '- !policy',
        '  id: <%= id %>',
        '  annotations:',
        # "    factory: #{@classification}/#{@version}/#{@name}",
        '<% annotations.each do |key, value| -%>',
        '    <%= key %>: <%= value %>',
        '<% end -%>',
        '',
        '  body:'
      ].tap do |policy|
        if configuration['variables'] && configuration['without_variable_group'].to_s.downcase != 'true'
          policy.push('  - &variables')

          policy.concat(configuration['variables'].map { |variable, _| "    - !variable #{variable}" })
          policy.push('')
        end
        policy.concat(policy_template.split("\n").map { |line| "  #{line}" })
      end
        .join("\n")
    end

    # Creates the appropriate JSON Schema based on the configuration
    def generate_schema(configuration:)
      properties = {}.tap do |property_hsh|
        unless configuration['include_identifier'].to_s.downcase == 'false'
          property_hsh[:id] = { description: 'Resource Identifier', type: 'string' }
        end
        unless configuration['include_annotations'].to_s.downcase == 'false'
          property_hsh[:annotations] = { description: 'Additional annotations', type: 'object' }
        end
      end
      {
        '$schema': 'http://json-schema.org/draft-06/schema#',
        title: configuration['title'],
        description: configuration['description'],
        type: 'object',
        properties: properties,
        required: []
      }.tap do |schema|
        # If branch is not defined, require it in the payload
        if configuration['default_policy_branch'].to_s.empty?
          schema[:properties][:branch] = { description: 'Policy branch to load this resource into', type: 'string' }
          schema[:required] << 'branch'
        end
        unless configuration['wrap_with_policy'].to_s.downcase == 'false'
          schema[:required] << 'id'
        end

        if configuration.key?('policy_template_variables')
          configuration['policy_template_variables'].each do |variable, values|
            schema[:properties][variable] = { description: values['description'], type: 'string' }
            schema[:required] << variable if values['required'].to_s.downcase == 'true' && !schema[:required].include?(variable)
            # Fragile, but we need a way to set annotations as an object.
            schema[:properties]['annotations'][:type] = 'object' if variable == 'annotations'
            if values['default'].present?
              schema[:properties][variable][:default] = values['default']
            end
            if values['valid_values'].present?
              schema[:properties][variable][:enum] = values['valid_values']
            end
            if values['type'].present?
              schema[:properties][variable][:type] = values['type']
            end

          end
        end
        if configuration.key?('variables')
          schema[:properties][:variables] = { type: 'object', properties: {}, required: [] }
          schema[:required] << 'variables'

          configuration['variables'].each do |variable, values|
            schema[:properties][:variables][:properties][variable] = { description: values['description'], type: 'string' }
            if values['default'].present?
              schema[:properties][:variables][:properties][variable][:default] = values['default']
            end

            if values['valid_values'].present?
              schema[:properties][:variables][:properties][variable][:enum] = values['valid_values']
            end

            if values['type'].present?
              schema[:properties][:variables][:properties][variable][:type] = values['type']
            end

            if values.key?('required') && values['required'] == true
              schema[:properties][:variables][:required] << variable
            end
          end
        end
      end
    end

    # def valid?
    #   config = JSON.parse(@configuration)
    #   %w[title description].each do |attr|
    #     raise "'config.json' must include a '#{attr}', '\"#{attr}\": \"...\"'"
    #   end
    # end
  end
end
