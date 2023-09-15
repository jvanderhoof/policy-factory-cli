# frozen_string_literal: true

require 'base64'

module Factories
  # Base class for all templates. This simplifies the publication of these factories.
  class Base
    class << self
      # Required child methods
      def policy_template
        raise 'Method `policy_template` must be defined.'
      end

      def schema
        raise 'Method `schema` must be defined.'
      end

      def data
        Base64.encode64(
          {
            version: version,
            policy: Base64.encode64(policy_template),
            policy_branch: policy_branch,
            schema: schema.merge(
              '$schema': 'http://json-schema.org/draft-06/schema#'
            )
          }.to_json
        )
      end

      private

      # Default policy branch path
      def policy_branch
        "<%= branch %>"
      end

      def version
        # Extract version from this class's full name
        self.to_s.split('::')[-2].downcase.gsub(/v/, '').to_i
      end
    end
  end
end
