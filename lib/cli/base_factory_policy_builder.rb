# frozen_string_literal: true

require 'mustache'

module CLI
  # Generates the plan for loading a provided set of Factories
  class BaseFactoryPolicyBuilder
    def initialize(logger: Logger.new(STDOUT), renderer: Mustache.new)
      @logger = logger
      @renderer = renderer
    end

    # Arg `factories` is an array
    #
    # Default policy location takes the form:
    #   conjur/factories/core/v1/group
    def generate_base_factory_policy(factories:,  policy_base: '/', target_policy: 'conjur/factories')
      [].tap do |templates|
        # creates 'conjur/factories'
        templates << { branch: policy_base, policy: File.read('factory_policy/base.yml') }
        factories.group_by(&:category).each do |category, category_factories|
          # creates 'core'
          templates << {
            branch: target_policy,
            policy: generate_factory_category_template(category)
          }
          category_factories.group_by(&:version).each do |version, factory_versions|
            # creates 'v1'
            templates << {
              branch: "#{target_policy}/#{category}",
              policy: generate_version_template(version)
            }
            # creates 'group'
            factory_versions.each do |factory_version|
              templates << {
                branch: "#{target_policy}/#{category}/#{version}",
                policy: generate_factory_variable_template(factory_version)
              }
            end
          end
        end
      end
    end

    private

    def generate_factory_template(name)
      @renderer.render(File.read('factory_policy/factory.yml'), { 'name' => name })
    end

    def generate_version_template(version)
      @renderer.render(File.read('factory_policy/version.yml'), { 'version' => version })
    end

    def generate_factory_variable_template(factory)
      template = if File.exist?("factory_policy/factories/#{factory.name}.yml")
                   File.read("factory_policy/factories/#{factory.name}.yml")
                 else
                   File.read('factory_policy/factories/default.yml')
                 end
      @renderer.render(template, factory.to_h)
    end

    def generate_factory_category_template(category)
      template = if File.exist?("factory_policy/categories/#{category}.yml")
                   File.read("factory_policy/categories/#{category}.yml")
                 else
                   File.read('factory_policy/categories/default.yml')
                 end
      @renderer.render(template, { 'category' => category })
    end
  end
end
