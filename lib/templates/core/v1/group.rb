# frozen_string_literal: true

module Factories
  module Templates
    module Core
      module V1
        class Group < Factories::Base
          class << self
            def policy_template
              <<~TEMPLATE
                - !group
                  id: <%= id %>
                <% if defined?(owner_role) && defined?(owner_type) -%>
                  owner: !<%= owner_type %> <%= owner_role %>
                <% end -%>
                  annotations:
                    factory: core/v1/group
                <% annotations.each do |key, value| -%>
                    <%= key %>: <%= value %>
                <% end -%>
              TEMPLATE
            end

            def schema
              {
                "title": "Group Template",
                "description": "Creates a Conjur Group",
                "type": "object",
                "properties": {
                  "id": {
                    "description": "Group Identifier",
                    "type": "string"
                  },
                  "branch": {
                    "description": "Policy branch to load this group into",
                    "type": "string"
                  },
                  "owner_role": {
                    "description": "The Conjur Role that will own this group",
                    "type": "string"
                  },
                  "owner_type": {
                    "description": "The resource type of the owner of this group",
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
