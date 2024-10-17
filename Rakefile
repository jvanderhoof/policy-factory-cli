# frozen_string_literal: true

require 'bundler'
require 'base64'
require 'json'
require 'logger'

Bundler.require

require 'fileutils'
require './lib/compiler/generate_factory'

def logger
  @logger ||= begin
    logger = Logger.new(STDOUT)
    log_level = ENV.fetch('LOG_LEVEL', 'warn')
    log_level = ENV.fetch('LOG_LEVEL', 'info')
    logger.level = Object.const_get("Logger::#{log_level.upcase}")
    logger
  end
end

def available_templates(files)
  {}.tap do |templates|
    files.each do |file|
      classification, name, version = File.dirname(file).split('/')[-3..-1]
      templates[classification]
      templates[classification] ||= []
      templates[classification] << "#{version}/#{name.underscore}"
    end
  end
end

def indent_line(spaces:, line:)
  "#{' ' * spaces}#{line}\n"
end

def generate_policy_block(id:, indent:)
  [].tap do |response|
    response << indent_line(spaces: indent, line: '- !policy')
    response << indent_line(spaces: indent + 2, line: "id: #{id}")
    response << indent_line(spaces: indent + 2, line: 'body:')
  end.join('')
end

# policy_path: conjur/factories
# templates: { 'core' => ['v1/user', 'v1/group'] }
def generate_base_policy(policy_path:, templates:)
  indent = 0
  [].tap do |response|
    policy_path.split('/').each_with_index do |part, index|
      indent = 2 * index
      response << generate_policy_block(id: part, indent: indent)
    end
    indent += 2
    templates.each do |template, factories|
      response << generate_policy_block(id: template, indent: indent)
      factories.each do |factory|
        response << indent_line(spaces: indent + 2, line: "- !variable #{factory}")
      end
    end
  end.join
end

def api_key
  return ENV['API_KEY'] if ENV['API_KEY'].present?

  return Conjur::API.login(username, ENV['PASSWORD']).to_s if ENV.key?('PASSWORD')

  raise "Conjur `#{username}` user must include either:\n\n  - An API key (via `API_KEY` environment variable)\n\n  - A password (via `PASSWORD` environment variable)"
end

def username
  ENV.fetch('USERNAME', 'admin')
end

def client
  @client ||= begin
    conjur_url = ENV.fetch('CONJUR_URL', 'https://localhost')
    run_as_secure = ENV.fetch('INSECURE', 'false') == 'false'

    if run_as_secure && URI(conjur_url).scheme != 'https'
      raise Exception.new('Conjur URL must be `https` unless the --insecure flag is present.')
    end

    Conjur.configuration.rest_client_options = {
      verify_ssl: run_as_secure
    }
    Conjur.configuration.account = account
    Conjur.configuration.appliance_url = conjur_url
    if ENV['CONJUR_AUTH_TOKEN'].present?
      Conjur::API.new_from_token(JSON.parse(Base64.decode64(ENV['CONJUR_AUTH_TOKEN'])))
    else
      Conjur::API.new_from_key(username, api_key)
    end
  end
end

def account
  ENV.fetch('ACCOUNT', 'cucumber')
end

def create_factory(classification:, version:, name:)
  version = "v#{version.gsub(/\D/, '')}"
  target_directory = "factories/custom/#{classification.underscore}/#{name.underscore}/#{version}"
  FileUtils.mkdir_p(target_directory)

  if File.exist?("#{target_directory}/policy.yml")
    logger.debug("File already exists: '#{target_directory}/policy.yml'")
  else
    File.open("#{target_directory}/policy.yml", 'w') do |file|
      file.write("# Place relevant Conjur Policy here.\n")
    end
  end

  if File.exist?("#{target_directory}/config.json")
    logger.debug("File already exists: '#{target_directory}/policy.yml'")
  else
    File.open("#{target_directory}/config.json", 'w') do |file|
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

  logger.info("Factory stubs generated in: '#{target_directory}'")
end

namespace :policy_factory do
  task :create, [:classification, :version, :name] do |_, args|
    create_factory(
      classification: args[:classification],
      version: args[:version],
      name: args[:name]
    )
  end

  task :inspect, [:path] do |_, args|
    factory_file_path = args[:path]
    classification, name, version = args[:path].split('/').last(3)
    compiled_factory = Compiler::GenerateFactory.new(
        classification: classification,
        version: version,
        name: name
      ).generate(
        policy_template: File.exist?("#{factory_file_path}/policy.yml") ? File.read("#{factory_file_path}/policy.yml") : nil,
        configuration: JSON.parse(File.read("#{factory_file_path}/config.json"))
      )
    factory = JSON.parse(Base64.decode64(compiled_factory))
    puts 'Factory Schema:'
    puts JSON.pretty_generate(factory)
    if factory.key?('policy')
      puts
      puts 'Factory Policy:'
      puts Base64.decode64(factory['policy'])
    end
    puts
    puts "Compiled Factory:"
    puts compiled_factory
  end

  def apply_base_factory_policy(target_policy:, templates:)
    logger.info("Generated Base Template:")
    logger.debug(generate_base_policy(policy_path: target_policy, templates: templates))
    client.load_policy('root',  generate_base_policy(policy_path: target_policy, templates: templates))
  end

  def load_factory(factory:, version:, classification:, template_folder:, target_policy:)
    factory_file_path = "factories/#{template_folder}/#{classification}/#{factory}/#{version}"
    logger.info("  loading template from: '#{factory_file_path}'")
    policy_template = File.exist?("#{factory_file_path}/policy.yml") ? File.read("#{factory_file_path}/policy.yml") : nil

    compiled_factory = Compiler::GenerateFactory.new(
        name: factory,
        version: version,
        classification: classification
      ).generate(
        policy_template: policy_template,
        configuration: JSON.parse(File.read("#{factory_file_path}/config.json"))
      )
    logger.debug("  compiled factory: '#{compiled_factory}'")
    variable = "#{account}:variable:#{target_policy}/#{classification}/#{version}/#{factory}"
    logger.info("  into variable: '#{variable}'")
    client.resource(variable).add_value(compiled_factory)
  end

  task :load do
    target_policy = ENV.fetch('TARGET_POLICY', 'conjur/factories')
    if ENV.fetch('LOAD_ALL', 'false') == 'true'
      template_folder = ENV.fetch('TEMPLATE_FOLDER', 'default')
      templates = available_templates(Dir["#{Dir.pwd}/factories/#{template_folder}/**/*.json"])

      if templates.empty?
        logger.warn("It looks like there are no templates in 'factories/#{template_folder}'")
        exit
      end
      logger.info("Loading templates from 'factories/#{template_folder}'")

      apply_base_factory_policy(target_policy: target_policy, templates: templates)

      templates.each do |classification, factories|
        factories.each do |factory_version|
          version, factory = factory_version.split('/')

          load_factory(
            factory: factory,
            version: version,
            classification: classification,
            template_folder: template_folder,
            target_policy: target_policy
          )
        end
      end
    else
      factory_path = ENV.fetch('FACTORY', '')
      logger.info("loading factory: #{factory_path}")

      _, template_folder, classification, factory, version = factory_path.split('/')

      template = { classification => ["#{version}/#{factory}"] }
      apply_base_factory_policy(target_policy: target_policy, templates: template)

      load_factory(
        factory: factory,
        version: version,
        classification: classification,
        template_folder: template_folder,
        target_policy: target_policy
      )
    end
  end
end
