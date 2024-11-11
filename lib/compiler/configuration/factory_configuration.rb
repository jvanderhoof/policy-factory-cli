# frozen_string_literal: true

module Compiler
  module Configuration
    class FactoryConfiguration
      class << self
        def reserved_template_variables
          {
            id: {
              title: 'Resource Identifier',
              description: ''
            },
            annotations: {
              title: 'Annotations',
              description: 'Additional annotations',
              type: 'object'
            },
            branch: {
              title: 'Policy Branch',
              description: 'Policy branch to apply this policy to'
            }
          }
        end

        def hydrate_variables(variables, defaults: {})
          (variables || []).map do |variable, values|
            args = (defaults[variable.to_sym] || {}).merge(values.symbolize_keys).merge({ identifier: variable.to_s })
            FactoryVariable.new(**args)
          end
        end

        def build_from_hash(policy_template:, configuration:, logger:)
          variables = hydrate_variables(configuration.delete(:variables))
          policy_template_variables = hydrate_variables(configuration.delete(:policy_template_variables), defaults: reserved_template_variables)

          unless variables.empty?
            configuration[:with_variables_group] = true unless configuration[:with_variables_group] == false
            configuration[:wrap_with_policy] = true unless configuration[:wrap_with_policy] == false
          end

          if configuration[:wrap_with_policy] && configuration.key?(:include_identifier) && !configuration[:include_identifier]
            logger.warn("When 'wrap-with-policy' is true, 'include_identifier' is ignored.")
            configuration[:include_identifier] = true
          end

          factory_template_name = configuration.delete(:policy_type).to_s.underscore

          if policy_template.to_s.strip.empty? && factory_template_name.empty?
            raise 'No policy template found (and policy-type was not set).'
          end

          if policy_template.present? && factory_template_name.present?
            raise "A factory cannot define 'policy-type' and include a policy.yml template. Please choose one or the other."
          end

          if policy_template.nil? && factory_template_name.present? && File.exist?("lib/compiler/policy_types/#{factory_template_name}.yml")
            policy_template = File.read("lib/compiler/policy_types/#{factory_template_name}.yml")
            if configuration.key?(:wrap_with_policy) && !configuration[:wrap_with_policy]
              logger.warn("When 'policy-type' is defined, the 'wrap-with-policy' setting is ignored.")
              configuration[:wrap_with_policy] = true
            end
            if configuration.key?(:include_identifier) && !configuration[:include_identifier]
              logger.warn("When 'policy-type' is defined, the 'include-identifier' setting is ignored.")
              configuration[:include_identifier] = true
            end
          elsif factory_template_name.present? && !File.exist?("lib/compiler/policy_types/#{factory_template_name}.yml")
            raise "Factory defines 'policy-type' but the template '#{factory_template_name}' is not a valid template option."
          end
          policy_template ||= ''

          FactoryConfiguration.new(
            **configuration.merge(
              variables: variables,
              policy_template_variables: policy_template_variables,
              factory_template: policy_template
            ).deep_symbolize_keys
          )
        end
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

      # disable Metrics/ParameterLists
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
      # enable Metrics/ParameterLists

      def policy_branch
        @default_policy_branch || '{{ branch }}'
      end
    end
  end
end
