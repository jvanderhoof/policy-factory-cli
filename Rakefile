# frozen_string_literal: true

require 'bundler'

Bundler.require

require './lib/base'

template_files = Dir["#{Dir.pwd}/lib/templates/**/*.rb"]
template_files.each { |f| require f }

def available_templates(files)
  {}.tap do |templates|
    files.each do |file|
      classification, version = File.dirname(file).split('/')[-2..]
      templates[classification]
      templates[classification] ||= []
      templates[classification] << "#{version}/#{File.basename(file, '.rb')}"
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

def generate_base_policy(templates)
  ERB.new(base_template, trim_mode: '<>').result_with_hash(templates: templates)
end

def api_key
  return ENV['API_KEY'] if ENV.key?('API_KEY')

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

namespace :policy_factory do
  task :load do
    templates = available_templates(template_files)
    client.load_policy('root', generate_base_policy(templates))

    templates.each do |classification, factories|
      factories.each do |factory_version|
        version, factory = factory_version.split('/')
        client.resource(
          "#{account}:variable:conjur/factories/#{classification}/#{version}/#{factory}"
        ).add_value(
          "Factories::Templates::#{classification.capitalize}::#{version.capitalize}::#{factory.camelize}".constantize.send(:data)
        )
      end
    end
  end
end
