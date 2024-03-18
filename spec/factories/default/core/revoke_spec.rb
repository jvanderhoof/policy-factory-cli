# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Core::Revoke') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/core/revoke/v1/config.json'))
    end
    let(:policy_template) do
      File.read('factories/default/core/revoke/v1/policy.yml')
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Revoke Template',
          'description' => "Revokes a Role's membership to another Role",
          'include_identifier' => false,
          'wrap_with_policy' => false,
          'policy_template_variables' => {
            'member_resource_type' => {
              'required' => true,
              'description' => 'The member type (group, host, user, or layer) for the revoke',
              'valid_values' => ['group', 'host', 'layer', 'user']
            },
            'member_resource_id' => {
              'required' => true,
              'description' => 'The member resource identifier for the revoke'
            },
            'role_resource_type' => {
              'required' => true,
              'description' => 'The role type (group or layer) for the revoke',
              'valid_values' => ['group', 'layer']
            },
            'role_resource_id' => {
              'required' => true,
              'description' => 'The role resource identifier for the revoke'
            }
          }
        }
      )
    end
    it 'includes the expected policy template' do
      expect(policy_template).to eq(
        <<~POLICY
          - !revoke
            member: !<%= member_resource_type %> <%= member_resource_id %>
            role: !<%= role_resource_type %> <%= role_resource_id %>
        POLICY
      )
    end
  end
end
