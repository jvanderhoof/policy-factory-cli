# frozen_string_literal: true

require 'bundler'

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

def base_template
  <<~TEMPLATE
  - !policy
    id: conjur
    body:
    - !policy
      id: factories
      body:
      <% templates.each do |template, factories| %>
      - !policy
        id: <%= template %>
        body:
      <% factories.each do |factory| %>
        - !variable <%= factory %>
      <% end %>
      <% end %>
  TEMPLATE
end

def render(template:, **args)
  ERB.new(template, trim_mode: '<>').result_with_hash(args)
end

def generate_base_policy(templates)
  render(template: base_template, templates: templates)
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
    Conjur::API.new_from_key(username, api_key)
  end
end

def account
  ENV.fetch('ACCOUNT', 'cucumber')
end

def create_factory(classification:, version:, name:)
  version = "v#{version.gsub(/\D/, '')}"
  target_directory = "lib/templates/#{classification.underscore}/#{name.underscore}/#{version}"
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
    template_folder = ENV.fetch('TEMPLATE_FOLDER', 'templates')

    templates = available_templates(Dir["#{Dir.pwd}/lib/#{template_folder}/**/*.json"])

    if templates.empty?
      puts "It looks like there are no templates in 'lib/#{template_folder}'"
      exit
    end
    puts "Loading templates from 'lib/#{template_folder}'\n\n"

    client.load_policy('root', generate_base_policy(templates))

    templates.each do |classification, factories|
      factories.each do |factory_version|
        version, factory = factory_version.split('/')

        factory_file_path = "lib/#{template_folder}/#{classification}/#{factory}/#{version}"
        puts "  loading template from: '#{factory_file_path}'"
        client.resource(
          "#{account}:variable:conjur/factories/#{classification}/#{version}/#{factory}"
        ).add_value(
          Compiler::GenerateFactory.new(
            name: factory,
            version: version,
            classification: classification
          ).generate(
            policy_template: File.read("#{factory_file_path}/policy.yml"),
            configuration: JSON.parse(File.read("#{factory_file_path}/config.json"))
          )
        )
      end
    end
  end
end
