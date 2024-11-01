# frozen_string_literal: true

require 'active_support'
require 'base64'

module Compiler
  module Configuration
    class FactoryVariable
      attr_reader :identifier, :description, :default, :valid_values, :required

      def initialize(identifier:, title: nil, description: '', default: nil, valid_values: nil, required: false)
        @identifier = identifier
        @title = title
        @description = description
        @default = default
        @valid_values = valid_values
        @required = required
      end

      def title
        @title || identifier.capitalize
      end
    end

    class FactoryConfiguration
      def self.hydrate_variables(variables)
        # binding.pry
        (variables || []).map do |variable, values|
          args = values.symbolize_keys.merge({ identifier: variable.to_s })
          # binding.pry
          FactoryVariable.new(**args)
        end
      end

      def self.build_from_hash(policy_template:, configuration:)
        variables = hydrate_variables(configuration.delete(:variables))
        # binding.pry
        policy_template_variables = hydrate_variables(configuration.delete(:policy_template_variables))

        unless variables.empty?
          configuration[:with_variables_group] = true unless configuration[:with_variables_group] == false
          configuration[:wrap_with_policy] = true
        end

        configuration[:include_identifier] = true if configuration[:wrap_with_policy]

        factory_template_name = configuration.delete(:policy_type).to_s.underscore
        if policy_template.nil? && factory_template_name.present?
          if File.exist?("lib/compiler/policy_types/#{factory_template_name}.yml")
            policy_template = File.read("lib/compiler/policy_types/#{factory_template_name}.yml")
            configuration[:wrap_with_policy] = true
            configuration[:include_identifier] = true
          else
            policy_template = ''
          end
        end

        FactoryConfiguration.new(
          **configuration.merge(
            variables: variables,
            policy_template_variables: policy_template_variables,
            factory_template: policy_template
          ).deep_symbolize_keys
        )
      end

      attr_reader(
        :title,
        :description,
        :default_policy_branch,
        :factory_template,
        :with_variables_group,
        :wrap_with_policy,
        :include_identifier,
        :include_annotations,
        :include_policy_branch,
        :variables,
        :policy_template_variables
      )

      def initialize(
        title: '',
        description: '',
        default_policy_branch: nil,
        factory_template: '',
        variables: [],
        policy_template_variables: [],
        with_variables_group: false,
        wrap_with_policy: false,
        include_identifier: true,
        include_annotations: true
      )
        @title = title
        @description = description
        @default_policy_branch = default_policy_branch
        @factory_template = factory_template
        @variables = variables
        @policy_template_variables = policy_template_variables
        @with_variables_group = with_variables_group
        @wrap_with_policy = wrap_with_policy
        @include_identifier = include_identifier
        @include_annotations = include_annotations
        @include_policy_branch = default_policy_branch.to_s.empty?
      end

      def policy_branch
        @default_policy_branch || '{{ branch }}'
      end
    end
  end

  class GenerateFactory
    def initialize(name:, version:, classification:)
      @name = name
      @version = version
      @classification = classification
    end

    # def underscore_keys(configuration)
    #   {}.tap do |rtn|
    #     configuration.each do |key, value|
    #       new_key = key.to_s.underscore
    #       rtn[new_key] = value.is_a?(Hash) ? underscore_keys(value) : value
    #     end
    #   end
    # end

    # def build_configuration(configuration)
    #   binding.pry

    #   # configuration.each do |key, value|
    #   #   key = key.underscore
    #   # end

    #   dashed_config = dasherize_keys(configuration)
    #   rtn = {}.tap do |config|
    #     dashed_config.each do |key, value|
    #       config[key] = value
    #     end
    #     if dashed_config.key?('variables')
    #       config['with-variables-group'] = true unless dashed_config['with-variables-group'] == false
    #       config['wrap-with-policy'] = true
    #     end

    #     config['wrap-with-policy'] = true if dashed_config.key?('policy-type')
    #   end
    #   merge_with_default_configuration(rtn)
    # end

    def generate(policy_template:, configuration:)
      # configuration = build_configuration(configuration)
      factory_config = Configuration::FactoryConfiguration.build_from_hash(
        policy_template: policy_template,
        configuration: configuration.deep_symbolize_keys
      )

      # if policy_template.nil? && configuration['policy-type'].present?
      #   if File.exist?("lib/compiler/policy_types/#{configuration['policy-type'].underscore}.yml")
      #     policy_template = File.read("lib/compiler/policy_types/#{configuration['policy-type'].underscore}.yml")
      #     configuration['wrap-with-policy'] = true
      #   else
      #     policy_template = ''
      #   end
      # end
      schema = generate_schema(configuration: factory_config)
      factory_policy_template = generate_policy_template(
        configuration: factory_config,
        policy_template: factory_config.factory_template
      )
      create_factory(
        schema: schema,
        policy_template: factory_policy_template,
        configuration: factory_config
      )
    end

    private

    # # Handles converting old configuration which used underscores to the
    # # new configuration which uses dashes
    # def dasherize_keys(configuration)
    #   {}.tap do |rtn|
    #     configuration.each do |key, value|
    #       new_key = key.to_s.gsub(/_/, '-')
    #       rtn[new_key] = value.is_a?(Hash) ? dasherize_keys(value) : value
    #     end
    #   end
    # end

    # def merge_with_default_configuration(configuration)
    #   default_configuration.merge(configuration)
    # end

    # def default_configuration
    #   {
    #     'wrap-with-policy': false,
    #     'include-identifier': true,
    #     'include-annotations': true,
    #     'with-variables-group': false
    #   }.stringify_keys
    # end

    def create_factory(schema:, policy_template:, configuration:)
      Base64.strict_encode64(
        {
          version: @version,
          policy: Base64.strict_encode64(policy_template.to_s),
          policy_branch: configuration.policy_branch, # default_policy_branch(configuration),
          schema: schema
        }.to_json
      )
    end

    # def default_policy_branch(configuration)
    #   if configuration.default_policy_branch
    #     '{{ branch }}'
    #   else
    #     configuration['default-policy-branch']
    #   end
    # end

    def generate_policy_template(configuration:, policy_template:)
      return policy_template unless configuration.wrap_with_policy

      default_policy = [
        '- !policy',
        '  id: {{ id }}',
        '  annotations:',
        '  {{# annotations }}',
        '    {{ key }}: {{ value }}',
        '  {{/ annotations }}'
      ]
      # if configuration['policy-type'].present? && !configuration['variables']
      #   unless policy_template.to_s.empty?
      #     default_policy.push('')
      #     default_policy.push('  body:')
      #   end
      # end
      # if configuration['variables']
      #   default_policy.tap do |policy|
      #     policy.push('')
      #     policy.push('  body:')
      #   end
      # end
      if configuration.variables.present? || (configuration.factory_template.present? && configuration.wrap_with_policy)
        default_policy.tap do |policy|
          policy.push('')
          policy.push('  body:')
        end
      end

      # default_policy.tap do |policy|
      #   if configuration['variables']
      #     policy.push('  - &variables') if configuration['with-variables-group']
      #     if configuration['with-variables-group']
      #       policy.concat(configuration['variables'].map { |variable, _| "    - !variable #{variable}" })
      #     else
      #       policy.concat(configuration['variables'].map { |variable, _| "  - !variable #{variable}" })
      #     end
      #     policy.push('')
      #   end
      #   policy.concat(policy_template.to_s.split("\n").map { |line| "  #{line}" })
      # end
      # binding.pry
      default_policy.tap do |policy|
        if configuration.variables.present?
          policy.push('  - &variables') if configuration.with_variables_group
          if configuration.with_variables_group
            policy.concat(configuration.variables.map { |variable, _| "    - !variable #{variable.identifier}" })
          else
            policy.concat(configuration.variables.map { |variable, _| "  - !variable #{variable.identifier}" })
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
        # if configuration['wrap-with-policy'] && configuration['include-identifier']
        # if configuration.wrap_with_policy && configuration.include_identifier
        #   property_hsh[:id] = { title: 'Resource Identifier', type: 'string' }
        # # elsif configuration['wrap-with-policy']
        # elsif configuration.wrap_with_policy
        #   property_hsh[:id] = { title: 'Resource Identifier', type: 'string' }
        # # elsif configuration['include-identifier']
        # elsif configuration.include_identifier
        #   property_hsh[:id] = { title: 'Resource Identifier', type: 'string' }
        # end
        if configuration.include_identifier
          property_hsh[:id] = { title: 'Resource Identifier', type: 'string' }
        end
        # if configuration['include-annotations']
        if configuration.include_annotations
          property_hsh[:annotations] = { title: 'Annotations', description: 'Additional annotations', type: 'object' }
        end
      end
      {
        '$schema': 'http://json-schema.org/draft-06/schema#',
        title: configuration.title,
        description: configuration.description,
        type: 'object',
        properties: properties,
        required: []
      }.tap do |schema|
        #
        # TODO: make sure branch is always required....
        #
        # If branch is not defined, require it in the payload
        # if configuration['default-policy-branch'].to_s.empty?
        if configuration.include_policy_branch
          schema[:properties][:branch] = { title: 'Policy Branch', description: 'Policy branch to apply this policy into', type: 'string' }
          schema[:required] << 'branch'
        end
        # if configuration['wrap-with-policy'] && configuration['include-identifier']
        #   schema[:required] << 'id'
        # elsif configuration['wrap-with-policy']
        #   schema[:required] << 'id'
        # elsif configuration['include-identifier']
        #   schema[:required] << 'id'
        # end
        schema[:required] << 'id' if configuration.include_identifier

        # if configuration.key?('policy-template-variables')
        # configuration['policy-template-variables'].each do |variable, values|
        configuration.policy_template_variables.each do |variable|
          # binding.pry
          # schema[:properties][variable] = { title: (values['title'] || variable.capitalize).to_s, description: values['description'].to_s, type: 'string' }
          schema[:properties][variable.identifier] = { title: variable.title, description: variable.description, type: 'string' }
          # schema[:required] << variable if values['required'].to_s.downcase == 'true' && !schema[:required].include?(variable)
          schema[:required] << variable.identifier if variable.required && !schema[:required].include?(variable)
          # if values['default'].present?
          # schema[:properties][variable][:default] = values['default']
          schema[:properties][variable.identifier][:default] = variable.default if variable.default.present?
          # if values['valid-values'].present?
          #   schema[:properties][variable][:enum] = values['valid-values']
          # end
          schema[:properties][variable.identifier][:enum] = variable.valid_values if variable.valid_values
        end
        # end
        # if configuration.key?('variables')
        #   schema[:properties][:variables] = { type: 'object', properties: {}, required: [] }
        #   schema[:required] << 'variables'

        #   configuration['variables'].each do |variable, values|
        #     schema[:properties][:variables][:properties][variable] = { title: (values['title'] || variable.capitalize).to_s, description: values['description'].to_s, type: 'string' }
        #     if values['default'].present?
        #       schema[:properties][:variables][:properties][variable][:default] = values['default']
        #     end

        #     if values['valid-values'].present?
        #       schema[:properties][:variables][:properties][variable][:enum] = values['valid-values']
        #     end
        #     if values.key?('required') && values['required'] == true
        #       schema[:properties][:variables][:required] << variable
        #     end
        #   end
        # end
        unless configuration.variables.empty?
          schema[:properties][:variables] = { type: 'object', properties: {}, required: [] }
          schema[:required] << 'variables'

          configuration.variables.each do |variable|
            schema[:properties][:variables][:properties][variable.identifier] = { title: variable.title, description: variable.description, type: 'string' }
            schema[:properties][:variables][:properties][variable.identifier][:default] = variable.default unless variable.default.blank?

            # binding.pry
            schema[:properties][:variables][:properties][variable.identifier][:enum] = variable.valid_values unless variable.valid_values.blank?
            schema[:properties][:variables][:required] << variable.identifier if variable.required
          end
        end
      end
    end
  end
end
