# frozen_string_literal: true

require 'bundler'
require 'base64'
require 'json'
require 'logger'
require 'pry'

Bundler.require

require 'fileutils'
require './lib/compiler/generate_factory'
require './lib/compiler/utilities/hash_util'

require './lib/cli/mindmap_builder'
require './lib/cli/factory_template_creater'
require './lib/cli/factory_loader'

def logger
  @logger ||= begin
    logger = Logger.new($stdout)
    # log_level = ENV.fetch('LOG_LEVEL', 'warn')
    log_level = ENV.fetch('LOG_LEVEL', 'info')
    logger.level = Object.const_get("Logger::#{log_level.upcase}")
    logger
  end
end

namespace :tests do
  task :build_test_mindmap do
    puts 'Building test mindmap...'
    puts ''
    spec_path = 'spec/lib/compiler/generate_factory_spec.rb'

    mindmap = CLI::MindmapBuilder.new.build(spec_path)

    File.open('spec/lib/compiler/overview.puml', 'w') do |output|
      mindmap.split("\n").each do |input_line|
        output.write("#{input_line}\n")
      end
    end
  end
end

namespace :policy_factory do
  task :create, [:classification, :version, :name] do |_, args|
    CLI::FactoryTemplateCreator.new(
      logger: logger
    ).build(
      category: args[:classification],
      version: args[:version],
      name: args[:name]
    )
  end

  task :inspect, [:path] do |_, args|
    factory_file_path = args[:path]
    factory = CLI::FactoryRunbookBuilder.new.build_factory(factory_file_path)

    decompiled_factory = JSON.parse(Base64.decode64(factory.factory))
    puts 'Factory Schema:'
    puts JSON.pretty_generate(decompiled_factory['schema'])
    if decompiled_factory.key?('policy')
      puts
      puts 'Factory Policy:'
      puts Base64.decode64(decompiled_factory['policy'])
    end
    puts
    puts 'Compiled Factory:'
    puts factory.factory
  end

  task :load do
    target_policy = ENV.fetch('TARGET_POLICY', 'conjur/factories')
    if ENV.fetch('LOAD_ALL', 'false') == 'true'
      template_folder = ENV.fetch('TEMPLATE_FOLDER', 'default')
      logger.info("loading all '#{template_folder}' factories")

      templates = Dir["factories/#{template_folder}/**/*.json"]
      template_folders = templates.map { |f| f.split('/')[0...-1].join('/') }
    else
      factory_path = ENV.fetch('FACTORY', '')
      logger.info("loading factory: #{factory_path}")

      template_folders = [factory_path]
    end

    CLI::FactoryLoader.new(logger: logger).load(
      CLI::FactoryRunbookBuilder.new.build(template_folders, target_policy: target_policy)
    )
  end
end
