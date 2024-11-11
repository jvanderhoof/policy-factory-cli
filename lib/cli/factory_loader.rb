# frozen_string_literal: true

require 'mustache'
require 'base64'
require 'json'
require 'fileutils'

module CLI
  # Saves Factories into Conjur
  class FactoryLoader
    def initialize(logger: Logger.new($stdout))
      @logger = logger
    end

    def load(factories)
      factories[:policies].each do |policy|
        @logger.info("Loading policy into '#{policy[:branch]}'")
        client.load_policy(
          policy[:branch] == '/' ? 'root' : policy[:branch],
          policy[:policy]
        )
      end
      factories[:factories].each do |factory|
        @logger.info("Loading factory into '#{factory[:path]}'")
        client.resource("#{account}:variable:#{factory[:path]}").add_value(factory[:factory])
      end
    end

    private

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

    def api_key
      return ENV['API_KEY'] if ENV['API_KEY'].present?

      return Conjur::API.login(username, ENV['PASSWORD']).to_s if ENV.key?('PASSWORD')

      raise "Conjur `#{username}` user must include either:\n\n  - An API key (via `API_KEY` environment variable)\n\n  - A password (via `PASSWORD` environment variable)"
    end

    def username
      ENV.fetch('USERNAME', 'admin')
    end
  end
end
