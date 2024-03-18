# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Core::Group') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/core/group/v1/config.json'))
    end
    let(:policy_template) do
      File.read('factories/default/core/group/v1/policy.yml')
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Group Template',
          'description' => 'Creates a Conjur Group',
          'wrap_with_policy' => false,
          'policy_template_variables' => {
            'owner_role' => {
              'description' => 'The Conjur Role that will own this group'
            },
            'owner_type' => {
              'description' => 'The resource type of the owner of this group'
            }
          }
        }
      )
    end
    it 'includes the expected policy template' do
      expect(policy_template).to eq(
        <<~POLICY
          - !group
            id: <%= id %>
          <% if defined?(owner_role) && defined?(owner_type) -%>
            owner: !<%= owner_type %> <%= owner_role %>
          <% end -%>
            annotations:
          <% annotations.each do |key, value| -%>
              <%= key %>: <%= value %>
          <% end -%>
        POLICY
      )
    end
  end
end
