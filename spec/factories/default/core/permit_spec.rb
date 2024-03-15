# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Core::Permit') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/core/permit/v1/config.json'))
    end
    let(:policy_template) do
      File.read('factories/default/core/permit/v1/policy.yml')
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Permit Template',
          'description' => 'Assigns permissions to a Role',
          'include_identifier' => false,
          'include_annotations' => false,
          'wrap_with_policy' => false,
          'policy_template_variables' => {
            'role_type' => {
              'required' => true,
              'description' => 'The role type to grant permission on a resource',
              'valid_values' => ['group', 'host', 'layer', 'policy', 'user']
            },
            'role_id' => {
              'required' => true,
              'description' => 'The role identifier to grant permission on a resource'
            },
            'resource_type' => {
              'required' => true,
              'description' => 'The resource type to grant the permission on',
              'valid_values' => ['group', 'host', 'layer', 'policy', 'user', 'variable']
            },
            'resource_id' => {
              'required' => true,
              'description' => 'The resource identifier to grant the permission on'
            },
            'privileges' => {
              'required' => true,
              'description' => 'Comma seperated list of privileges to grant on the resource'
            }
          }
        }
      )
    end
    it 'includes the expected policy template' do
      expect(policy_template).to eq(
        <<~POLICY
          - !permit
            role: !<%= role_type %> <%= role_id %>
            resource: !<%= resource_type %> <%= resource_id %>
            privileges: [<%= privileges %>]
        POLICY
      )
    end
  end
end
