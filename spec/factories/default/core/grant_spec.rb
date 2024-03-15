# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Core::Grant') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/core/grant/v1/config.json'))
    end
    let(:policy_template) do
      File.read('factories/default/core/grant/v1/policy.yml')
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Grant Template',
          'description' => 'Assigns a Role to another Role',
          'include_identifier' => false,
          'include_annotations' => false,
          'wrap_with_policy' => false,
          'policy_template_variables' => {
            'member_resource_type' => {
              'required' => true,
              'description' => 'The member type (group, host, user, or layer) for the grant',
              'valid_values' => ['group', 'host', 'layer', 'user']
            },
            'member_resource_id' => {
              'required' => true,
              'description' => 'The member resource identifier for the grant'
            },
            'role_resource_type' => {
              'required' => true,
              'description' => 'The role type (group or layer) for the grant',
              'valid_values' => ['group', 'layer'],
              'default' => 'group'
            },
            'role_resource_id' => {
              'required' => true,
              'description' => 'The role resource identifier for the grant'
            }
          }
        }
      )
    end
    it 'includes the expected policy template' do
      expect(policy_template).to eq(
        <<~POLICY
          - !grant
            member: !<%= member_resource_type %> <%= member_resource_id %>
            role: !<%= role_resource_type %> <%= role_resource_id %>
        POLICY
      )
    end
  end
end
