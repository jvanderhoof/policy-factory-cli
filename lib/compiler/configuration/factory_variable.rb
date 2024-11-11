# frozen_string_literal: true

module Compiler
  module Configuration
    # Provides a standard interface for working with Template Variables and Conjur Variables
    class FactoryVariable
      attr_reader :identifier, :description, :default, :valid_values, :required, :hidden, :type

      # disable Metrics/ParameterLists
      def initialize(
        identifier:,
        title: nil,
        description: '',
        default: nil,
        valid_values: nil,
        required: false,
        hidden: false,
        type: 'string'
      )
        @identifier = identifier
        @title = title
        @description = description
        @default = default
        @valid_values = valid_values
        @required = required
        @hidden = hidden
        @type = type
      end
      # enable Metrics/ParameterLists

      def title
        @title || identifier.capitalize
      end
    end
  end
end
