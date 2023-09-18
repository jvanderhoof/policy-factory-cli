# frozen_string_literal: true

module Factories
  module Templates
    module Core
      module V1
        class ManagedPolicy < Factories::Base
          class << self
            def policy_template
              <<~TEMPLATE
                - !group <%= name %>-admins
                - !policy
                  id: <%= name %>
                  owner: !group <%= name %>-admins
                  annotations:
                    factory: core/v1/managed-policy
                <% annotations.each do |key, value| -%>
                    <%= key %>: <%= value %>
                <% end -%>
              TEMPLATE
            end

            def schema
              {
                'title': 'Managed Policy Template',
                'description': 'Policy with an owner group',
                'type': 'object',
                'properties': {
                  'name': {
                    'description': 'Policy name (used to create the policy ID and the <name>-admins owner group)',
                    'type': 'string'
                  },
                  'branch': {
                    'description': 'Policy branch to load this policy into',
                    'type': 'string'
                  },
                  'annotations': {
                    'description': 'Additional annotations',
                    'type': 'object'
                  }
                },
                'required': %w[name branch]
              }
            end
          end
        end
      end
    end
  end
end
