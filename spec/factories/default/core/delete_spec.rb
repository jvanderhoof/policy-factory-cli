# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Core::Delete') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/core/delete/v1/config.json'))
    end
    let(:policy_template) do
      File.read('factories/default/core/delete/v1/policy.yml')
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Delete Template',
          'description' => 'Deletes a Role or Resource',
          'include_identifier' => false,
          'include_annotations' => false,
          'wrap_with_policy' => false,
          'policy_template_variables' => {
            'resource_type' => {
              'required' => true,
              'description' => 'The resource type to delete',
              'valid_values' => ['group', 'host', 'layer', 'policy', 'user', 'variable', 'webservice']
            },
            'resource_id' => {
              'required' => true,
              'description' => 'The resource identifier to delete'
            }
          }
        }
      )
    end
    it 'includes the expected policy template' do
      expect(policy_template).to eq(
        <<~POLICY
          - !delete
            record: !{{ resource_type }} {{ resource_id }}
        POLICY
      )
    end
  end
end
