# frozen_string_literal: true

require 'active_support'
require 'base64'

require './lib/compiler/configuration/factory_variable'
require './lib/compiler/configuration/factory_configuration'

module Compiler
  class GenerateFactory
    def initialize(name:, version:, category:)
      @name = name
      @version = version
      @category = category
      @logger = Logger.new(STDOUT)
    end

    def generate(policy_template:, configuration:)
      factory_config = Configuration::FactoryConfiguration.build_from_hash(
        policy_template: policy_template,
        configuration: default_configuration.merge(strip_empty(configuration).deep_symbolize_keys),
        logger: @logger
      )

      create_factory(
        schema: generate_schema(configuration: factory_config),
        policy_template: generate_policy_template(configuration: factory_config),
        configuration: factory_config
      )
    end

    private

    def strip_empty(configuration)
      {}.tap do |config|
        configuration.each do |key, value|
          config[key] = value if key.to_s.present? && value.to_s.present?
        end
      end
    end

    def default_configuration
      { title: "#{@name.capitalize} Factory" }
    end

    def create_factory(schema:, policy_template:, configuration:)
      Base64.strict_encode64(
        {
          version: @version,
          policy: Base64.strict_encode64(policy_template.to_s),
          policy_branch: configuration.policy_branch,
          schema: schema
        }.to_json
      )
    end

    def print_indent(indent_count)
      str = ''
      indent_count.times { str += '  ' }
      str
    end

    def generate_policy_template(configuration:)
      return configuration.factory_template if !configuration.wrap_with_policy && !configuration.with_variables_group

      default_policy = []
      indent = 0

      if configuration.wrap_with_policy
        default_policy += [
          '- !policy',
          '  id: {{ id }}',
          '  annotations:',
          '  {{# annotations }}',
          '    {{ key }}: {{ value }}',
          '  {{/ annotations }}',
          '',
          '  body:'
        ]
        indent += 1
      end
      default_policy.tap do |policy|
        if configuration.variables.present?
          if configuration.with_variables_group
            policy.push("#{print_indent(indent)}- &variables")
            indent += 1
            policy.concat(configuration.variables.map { |variable, _| "#{print_indent(indent)}- !variable #{variable.identifier}" })
            policy.push('')
            indent -= 1
          else
            policy.concat(configuration.variables.map { |variable, _| "#{print_indent(indent)}- !variable #{variable.identifier}" })
          end
        end
        policy.concat(configuration.factory_template.split("\n").map { |line| "#{print_indent(indent)}#{line}" })
      end
        .join("\n")
    end

    # Creates the appropriate JSON Schema based on the configuration
    def generate_schema(configuration:)
      properties = {}.tap do |property_hsh|
        property_hsh[:id] = { title: 'Resource Identifier', description: '', type: 'string' } if configuration.include_identifier
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
        if configuration.include_policy_branch
          schema[:properties][:branch] = { title: 'Policy Branch', description: 'Policy branch to apply this policy to', type: 'string' }
          schema[:required] << 'branch'
        end

        schema[:required] << 'id' if configuration.include_identifier

        configuration.policy_template_variables.each do |variable|
          schema[:properties][variable.identifier] = generate_variable(variable)
          if variable.required && !schema[:required].include?(variable.identifier)
            schema[:required] << variable.identifier
          end
        end
        unless configuration.variables.empty?
          schema[:properties][:variables] = { type: 'object', properties: {}, required: [] }
          schema[:required] << 'variables' if configuration.variables.any? { |v| v.required }

          configuration.variables.each do |variable|
            schema[:properties][:variables][:properties][variable.identifier] = generate_variable(variable)
            schema[:properties][:variables][:required] << variable.identifier if variable.required
          end
        end
      end
    end

    def generate_variable(variable)
      { title: variable.title, description: variable.description, type: variable.type }.tap do |rtn|
        rtn[:readOnly] = variable.hidden if variable.hidden
        rtn[:default] = variable.default if variable.default.present?
        rtn[:enum] = variable.valid_values if variable.valid_values
      end
    end
  end
end
