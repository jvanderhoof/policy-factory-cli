# frozen_string_literal: true

module Factories
  module Templates
    module Core
      module V1
        class Policy < Factories::Base
          class << self
            def policy_template
              <<~TEMPLATE
                - !policy
                  id: <%= id %>
                <% if defined?(owner_role) && defined?(owner_type) -%>
                  owner: !<%= owner_type %> <%= owner_role %>
                <% end -%>
                  annotations:
                    factory: core/v1/policy
                <% annotations.each do |key, value| -%>
                    <%= key %>: <%= value %>
                <% end -%>
              TEMPLATE
            end

            def schema
              {
                '$schema': 'http://json-schema.org/draft-06/schema#',
                'title': 'User Template',
                'description': 'Creates a Conjur Policy',
                'type': 'object',
                'properties': {
                  'id': {
                    'description': 'Policy ID',
                    'type': 'string'
                  },
                  'branch': {
                    'description': 'Policy branch to load this policy into',
                    'type': 'string'
                  },
                  'owner_role': {
                    'description': 'The Conjur Role that will own this policy',
                    'type': 'string'
                  },
                  'owner_type': {
                    'description': 'The resource type of the owner of this policy',
                    'type': 'string'
                  },
                  'annotations': {
                    'description': 'Additional annotations',
                    'type': 'object'
                  }
                },
                'required': %w[id branch]
              }
            end
          end
        end
      end
    end
  end
end
