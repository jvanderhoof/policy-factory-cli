# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Core::Variable') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/core/variable/v1/config.json'))
    end
    let(:policy_template) do
      File.read('factories/default/core/variable/v1/policy.yml')
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Variable',
          'description' => 'Creates a Conjur Variable',
          'with_variables_group' => false,
          'variables' => {
            'value' => {
              'title' => 'Value',
              'required' => true,
              'description' => 'Variable value'
            }
          }
        }
      )
    end
    it 'includes the expected policy template' do
      expect(policy_template).to eq(
        <<~POLICY
          - !variable

          - !group view
          - !group retrieve
          - !group update

          - !permit
            role: !group view
            privilege: [ read ]
            resource: !variable

          - !permit
            role: !group retrieve
            privilege: [ execute ]
            resource: !variable

          - !permit
            role: !group update
            privilege: [ update ]
            resource: !variable

          - !grant
            member: !group retrieve
            role: !group view

          - !grant
            member: !group update
            role: !group retrieve
        POLICY
      )
    end
  end
end
