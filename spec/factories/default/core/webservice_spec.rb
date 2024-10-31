# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Core::Webservice') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/core/webservice/v1/config.json'))
    end
    let(:policy_template) do
      File.read('factories/default/core/webservice/v1/policy.yml')
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Webservice Template',
          'description' => 'Creates a Conjur Webservice',
          'wrap_with_policy' => false,
          'policy_template_variables' => {
            'owner_role' => {
              'description' => 'The Conjur Role that will own this Webservice'
            },
            'owner_type' => {
              'description' => 'The resource type of the owner of this Webservice'
            }
          }
        }
      )
    end
    it 'includes the expected policy template' do
      expect(policy_template).to eq(
        <<~POLICY
          - !webservice
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
