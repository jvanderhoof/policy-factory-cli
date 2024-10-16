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
      # If the configuration is a collection of factories, generate the collection
      if configuration.key?('factories')
        create_factory_collections(
          factories: configuration['factories'],
          schema: generate_schema(configuration: configuration)
        )
      else
        configuration = merge_with_default_configuration(configuration)
        if policy_template.nil? && configuration['policy_type'].present?
          if File.exist?("lib/compiler/policy_types/#{configuration['policy_type'].underscore}.yml")
            policy_template = File.read("lib/compiler/policy_types/#{configuration['policy_type'].underscore}.yml")
          else
            policy_template = ''
          end
        end
        schema = generate_schema(configuration: configuration)
        factory_policy_template = generate_policy_template(
          configuration: configuration,
          policy_template: policy_template
        )
        create_factory(
          schema: schema,
          policy_template: factory_policy_template,
          configuration: configuration
        )
      end
    end

    private

    def merge_with_default_configuration(configuration)
      default_configuration.keys.each do |key|
        configuration[key] = to_boolean(configuration[key])
      end
      default_configuration.merge(configuration)
    end

    def default_configuration
      {
        wrap_with_policy: true,
        include_identifier: true,
        include_annotations: true,
        with_variable_group: true
      }.stringify_keys
    end

    def to_boolean(str)
      str.to_s.downcase != 'false'
    end

    def create_factory(schema:, policy_template:, configuration:)
      Base64.strict_encode64(
        {
          version: @version,
          policy: Base64.strict_encode64(policy_template.to_s),
          policy_branch: default_policy_branch(configuration),
          schema: schema
        }.to_json
      )
    end

    def create_factory_collections(schema:, factories:)
      Base64.strict_encode64(
        {
          version: @version,
          factories: factories,
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

      default_policy = [
        '- !policy',
        '  id: <%= id %>',
        '  annotations:',
        '<% annotations.each do |key, value| -%>',
        '    <%= key %>: <%= value %>',
        '<% end -%>'
      ]
      if configuration['policy_type'].present? && !configuration['variables']
        unless policy_template.to_s.empty?
          default_policy.push('')
          default_policy.push('  body:')
        end
      end
      if configuration['variables']
        default_policy.tap do |policy|
          policy.push('')
          policy.push('  body:')
        end
      end

      default_policy.tap do |policy|
        if configuration['variables']
          policy.push('  - &variables') if configuration['with_variable_group']
          if configuration['with_variable_group']
            policy.concat(configuration['variables'].map { |variable, _| "    - !variable #{variable}" })
          else
            policy.concat(configuration['variables'].map { |variable, _| "  - !variable #{variable}" })
          end
          policy.push('')
        end
        policy.concat(policy_template.to_s.split("\n").map { |line| "  #{line}" })
      end
        .join("\n")
    end

    # Creates the appropriate JSON Schema based on the configuration
    def generate_schema(configuration:)
      properties = {}.tap do |property_hsh|
        if configuration['wrap_with_policy'] && configuration['include_identifier']
          property_hsh[:id] = { description: 'Resource Identifier', type: 'string' }
        elsif configuration['wrap_with_policy']
          property_hsh[:id] = { description: 'Resource Identifier', type: 'string' }
        elsif configuration['include_identifier']
          property_hsh[:id] = { description: 'Resource Identifier', type: 'string' }
        end
        if configuration['include_annotations']
          property_hsh[:annotations] = { description: 'Additional annotations', type: 'object' }
        end
      end
      {
        '$schema': 'http://json-schema.org/draft-06/schema#',
        title: configuration['title'].to_s,
        description: configuration['description'].to_s,
        type: 'object',
        properties: properties,
        required: []
      }.tap do |schema|
        # If branch is not defined, require it in the payload
        if configuration['default_policy_branch'].to_s.empty?
          schema[:properties][:branch] = { description: 'Policy branch to apply this policy into', type: 'string' }
          schema[:required] << 'branch'
        end
        if configuration['wrap_with_policy'] && configuration['include_identifier']
          schema[:required] << 'id'
        elsif configuration['wrap_with_policy']
          schema[:required] << 'id'
        elsif configuration['include_identifier']
          schema[:required] << 'id'
        end

        if configuration.key?('policy_template_variables')
          configuration['policy_template_variables'].each do |variable, values|
            schema[:properties][variable] = { description: values['description'].to_s, type: 'string' }
            schema[:required] << variable if values['required'].to_s.downcase == 'true' && !schema[:required].include?(variable)
            if values['default'].present?
              schema[:properties][variable][:default] = values['default']
            end
            if values['valid_values'].present?
              schema[:properties][variable][:enum] = values['valid_values']
            end
          end
        end
        if configuration.key?('variables')
          schema[:properties][:variables] = { type: 'object', properties: {}, required: [] }
          schema[:required] << 'variables'

          configuration['variables'].each do |variable, values|
            schema[:properties][:variables][:properties][variable] = { description: values['description'].to_s, type: 'string' }
            if values['default'].present?
              schema[:properties][:variables][:properties][variable][:default] = values['default']
            end

            if values['valid_values'].present?
              schema[:properties][:variables][:properties][variable][:enum] = values['valid_values']
            end
            if values.key?('required') && values['required'] == true
              schema[:properties][:variables][:required] << variable
            end
          end
        end
      end
    end
  end
end
