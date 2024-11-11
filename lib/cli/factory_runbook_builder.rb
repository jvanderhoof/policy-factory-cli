# frozen_string_literal: true

require 'base64'
require 'json'
require 'fileutils'

require './lib/cli/factory'
require './lib/cli/base_factory_policy_builder'

module CLI
  # Builds a runlist of of:
  #   policies and their respected target branches
  #   factory variables and their corresponding factories
  class FactoryRunbookBuilder
    def initialize(logger: Logger.new(STDOUT))
      @logger = logger
    end

    # returns a runlist of policies and variables in the form:
    # {
    #   policies: [
    #     { branch: "...", policy: "..." }
    #   ],
    #   factories: [
    #     { path: "...", factory: "" }
    #   ]
    # }
    def build(factory_paths, target_policy: 'conjur/factories')
      factories = collect_factories(factory_paths)
      factory_policies = CLI::BaseFactoryPolicyBuilder.new(
        logger: @logger
      ).generate_base_factory_policy(
        factories: factories,
        target_policy: target_policy
      )
      {
        policies: factory_policies,
        factories: factories.map { |f| { path: "#{target_policy}/#{f.variable_path}", factory: f.factory } }
      }
    end

    def build_factory(path)
      _, _, category, name, version = path.split('/')

      compiled_factory = build_compiled_factory(factory_path: path, name: name, version: version, category: category)

      build_template_config(
        compiled_factory: compiled_factory,
        name: name,
        version: version,
        category: category
      )
    end

    private

    def collect_factories(factory_paths)
      factory_paths.map do |path|
        build_factory(path)
      end
    end

    def build_template_config(compiled_factory:, name:, version:, category:)
      schema = JSON.parse(Base64.strict_decode64(compiled_factory))['schema']
      CLI::Factory.new(
        name: name,
        version: version,
        category: category,
        type: 'Variable Factory',
        title: schema['title'],
        description: schema['description'],
        factory: compiled_factory
      )
    end

    def load_factory_configuration(factory_path)
      Compiler::Utilities::HashUtil.new.underscore_keys(
        JSON.parse(
          File.read("#{factory_path}/config.json")
        )
      )
    end

    def build_compiled_factory(factory_path:, name:, version:, category:)
      Compiler::GenerateFactory.new(
        name: name,
        version: version,
        category: category
      ).generate(
        policy_template: File.exist?("#{factory_path}/policy.yml") ? File.read("#{factory_path}/policy.yml") : nil,
        configuration: load_factory_configuration(factory_path)
      )
    end
  end
end
