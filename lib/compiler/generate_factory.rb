# frozen_string_literal: true

require 'base64'

module Compiler
  class GenerateFactory
    def initialize(name:, version:, classification:)
      @name = name
      @version = version
      @classification = classification
    end

    def build_configuration(configuration)
      dashed_config = dasherize_keys(configuration)
      rtn = {}.tap do |config|
        dashed_config.each do |key, value|
          config[key] = value
        end
        if dashed_config.key?('variables')
          config['with-variables-group'] = true unless dashed_config['with-variables-group'] == false
          config['wrap-with-policy'] = true
        end

        config['wrap-with-policy'] = true if dashed_config.key?('policy-type')
      end
      merge_with_default_configuration(rtn)
    end

    def generate(policy_template:, configuration:)
      configuration = build_configuration(configuration)
      if policy_template.nil? && configuration['policy-type'].present?
        if File.exist?("lib/compiler/policy_types/#{configuration['policy-type'].underscore}.yml")
          policy_template = File.read("lib/compiler/policy_types/#{configuration['policy-type'].underscore}.yml")
          configuration['wrap-with-policy'] = true
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

    private

    # Handles converting old configuration which used underscores to the
    # new configuration which uses dashes
    def dasherize_keys(configuration)
      {}.tap do |rtn|
        configuration.each do |key, value|
          new_key = key.to_s.gsub(/_/, '-')
          if value.is_a?(Hash)
            rtn[new_key] = dasherize_keys(value)
          else
            rtn[new_key] = value
          end
        end
      end
    end

    def merge_with_default_configuration(configuration)
      default_configuration.merge(configuration)
    end

    def default_configuration
      {
        'wrap-with-policy': false,
        'include-identifier': true,
        'include-annotations': true,
        'with-variables-group': false
      }.stringify_keys
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

    def default_policy_branch(configuration)
      if configuration['default-policy-branch'].to_s.empty?
        '{{ branch }}'
      else
        configuration['default-policy-branch']
      end
    end

    def generate_policy_template(configuration:, policy_template:)
      return policy_template unless configuration['wrap-with-policy'].to_s.downcase == 'true'

      default_policy = [
        '- !policy',
        '  id: {{ id }}',
        '  annotations:',
        '  {{# annotations }}',
        '    {{ key }}: {{ value }}',
        '  {{/ annotations }}'
      ]
      if configuration['policy-type'].present? && !configuration['variables']
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
          policy.push('  - &variables') if configuration['with-variables-group']
          if configuration['with-variables-group']
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
        if configuration['wrap-with-policy'] && configuration['include-identifier']
          property_hsh[:id] = { title: 'Resource Identifier', type: 'string' }
        elsif configuration['wrap-with-policy']
          property_hsh[:id] = { title: 'Resource Identifier', type: 'string' }
        elsif configuration['include-identifier']
          property_hsh[:id] = { title: 'Resource Identifier', type: 'string' }
        end
        if configuration['include-annotations']
          property_hsh[:annotations] = { title: 'Annotations', description: 'Additional annotations', type: 'object' }
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
        if configuration['default-policy-branch'].to_s.empty?
          schema[:properties][:branch] = { title: 'Policy Branch', description: 'Policy branch to apply this policy into', type: 'string' }
          schema[:required] << 'branch'
        end
        if configuration['wrap-with-policy'] && configuration['include-identifier']
          schema[:required] << 'id'
        elsif configuration['wrap-with-policy']
          schema[:required] << 'id'
        elsif configuration['include-identifier']
          schema[:required] << 'id'
        end

        if configuration.key?('policy-template-variables')
          configuration['policy-template-variables'].each do |variable, values|
            schema[:properties][variable] = { title: (values['title'] || variable.capitalize).to_s, description: values['description'].to_s, type: 'string' }
            schema[:required] << variable if values['required'].to_s.downcase == 'true' && !schema[:required].include?(variable)
            if values['default'].present?
              schema[:properties][variable][:default] = values['default']
            end
            if values['valid-values'].present?
              schema[:properties][variable][:enum] = values['valid-values']
            end
          end
        end
        if configuration.key?('variables')
          schema[:properties][:variables] = { type: 'object', properties: {}, required: [] }
          schema[:required] << 'variables'

          configuration['variables'].each do |variable, values|
            schema[:properties][:variables][:properties][variable] = { title: (values['title'] || variable.capitalize).to_s, description: values['description'].to_s, type: 'string' }
            if values['default'].present?
              schema[:properties][:variables][:properties][variable][:default] = values['default']
            end

            if values['valid-values'].present?
              schema[:properties][:variables][:properties][variable][:enum] = values['valid-values']
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
