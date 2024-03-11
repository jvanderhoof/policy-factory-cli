# frozen_string_literal: true

require 'bundler'
require 'base64'
require 'json'

Bundler.require

require 'fileutils'
require './lib/compiler/generate_factory'

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
    Conjur.configuration.rest_client_options = {
      verify_ssl: false
    }
    Conjur.configuration.account = account
    Conjur.configuration.appliance_url = ENV.fetch('CONJUR_URL', 'https://localhost')
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
    puts "File already exists: '#{target_directory}/policy.yml'"
  else
    File.open("#{target_directory}/policy.yml", 'w') do |file|
      file.write("# Place relevant Conjur Policy here.\n")
    end
  end

  if File.exist?("#{target_directory}/config.json")
    puts "File already exists: '#{target_directory}/policy.yml'"
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

  puts "Factory stubs generated in: '#{target_directory}'"
end

namespace :policy_factory do
  task :create, [:classification, :version, :name] do |_, args|
    create_factory(
      classification: args[:classification],
      version: args[:version],
      name: args[:name]
    )
  end

  task :load do
    target_policy = ENV.fetch('TARGET_POLICY', 'conjur/factories')
    template_folder = ENV.fetch('TEMPLATE_FOLDER', 'default')
    templates = available_templates(Dir["#{Dir.pwd}/factories/#{template_folder}/**/*.json"])

    if templates.empty?
      puts "It looks like there are no templates in 'factories/#{template_folder}'"
      exit
    end
    puts "Loading templates from 'factories/#{template_folder}'\n\n"
    puts "Generated Base Template:"
    puts generate_base_policy(policy_path: target_policy, templates: templates)
    client.load_policy('root',  generate_base_policy(policy_path: target_policy, templates: templates))

    templates.each do |classification, factories|
      factories.each do |factory_version|
        version, factory = factory_version.split('/')

        factory_file_path = "factories/#{template_folder}/#{classification}/#{factory}/#{version}"
        puts "  loading template from: '#{factory_file_path}'"
        policy_template = File.exist?("#{factory_file_path}/policy.yml") ? File.read("#{factory_file_path}/policy.yml") : nil

        compiled_factory = Compiler::GenerateFactory.new(
            name: factory,
            version: version,
            classification: classification
          ).generate(
            policy_template: policy_template,
            configuration: JSON.parse(File.read("#{factory_file_path}/config.json"))
          )
        puts "  compiled factory: '#{compiled_factory}'"
        client.resource(
          "#{account}:variable:#{target_policy}/#{classification}/#{version}/#{factory}"
        ).add_value(compiled_factory)
      end
    end
  end
end
