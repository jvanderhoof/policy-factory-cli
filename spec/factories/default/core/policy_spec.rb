# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Core::Policy') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/core/policy/v1/config.json'))
    end
    let(:policy_template) do
      File.read('factories/default/core/policy/v1/policy.yml')
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Policy Template',
          'description' => 'Creates a Conjur Policy',
          'policy_template_variables' => {
            'owner_role' => {
              'title' => 'Owner Role',
              'description' => 'The Conjur Role that will own this policy'
            },
            'owner_type' => {
              'title' => 'Owner Type',
              'description' => 'The resource type of the owner of this policy'
            }
          }
        }
      )
    end
    it 'includes the expected policy template' do
      expect(policy_template).to eq(
        <<~POLICY
          - !policy
            id: {{ id }}
          {{# owner_role }}
            {{# owner_type }}
            owner: !{{ owner_type }} {{ owner_role }}
            {{/ owner_type }}
          {{/ owner_role }}
            annotations:
          {{# annotations }}
              {{ key }}: {{ value }}
          {{/ annotations }}
        POLICY
      )
    end
  end
end
