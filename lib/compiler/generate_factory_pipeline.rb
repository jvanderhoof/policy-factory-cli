# frozen_string_literal: true

require 'active_support'
require 'base64'

# require './lib/compiler/configuration/factory_variable'
# require './lib/compiler/configuration/factory_configuration'

module Compiler
  # Generates a factory pipeline from configuration
  class GenerateFactoryPipeline
    def initialize(name:, version:, category:)
      @name = name
      @version = version
      @category = category
      @logger = Logger.new(STDOUT)
    end

    def generate(configuration:)
      # create_factory(configuration)
      Base64.strict_encode64(
        {
          version: @version,
          factory_type: 'factory-pipeline',
          schema: configuration
        }.to_json
      )
    end

    # private

    # def create_factory(configuration)
    #   Base64.strict_encode64(
    #     {
    #       version: @version,
    #       factory_type: 'factory-pipeline',
    #       schema: configuration
    #     }.to_json
    #   )
    # end
  end
end
