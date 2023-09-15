# frozen_string_literal: true

module Factories
  module Templates
    module Core
      module V1
        class User < Factories::Base
          class << self
            def policy_template
              <<~TEMPLATE
                - !user
                  id: <%= id %>
                <% if defined?(owner_role) && defined?(owner_type) -%>
                  owner: !<%= owner_type %> <%= owner_role %>
                <% end -%>
                <% if defined?(ip_range) -%>
                  restricted_to: <%= ip_range %>
                <% end -%>
                  annotations:
                    factory: core/v1/user
                <% annotations.each do |key, value| -%>
                    <%= key %>: <%= value %>
                <% end -%>
              TEMPLATE
            end

            def schema
              {
                "title": "User Template",
                "description": "Creates a Conjur User",
                "type": "object",
                "properties": {
                  "id": {
                    "description": "User ID",
                    "type": "string"
                  },
                  "branch": {
                    "description": "Policy branch to load this user into",
                    "type": "string"
                  },
                  "owner_role": {
                    "description": "The Conjur Role that will own this user",
                    "type": "string"
                  },
                  "owner_type": {
                    "description": "The resource type of the owner of this user",
                    "type": "string"
                  },
                  "ip_range": {
                    "description": "Limits the network range the user is allowed to authenticate from",
                    "type": "string"
                  },
                  "annotations": {
                    "description": "Additional annotations",
                    "type": "object"
                  }
                },
                "required": %w[id branch]
              }
            end
          end
        end
      end
    end
  end
end
