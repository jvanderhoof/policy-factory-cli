# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Core::User') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/core/user/v1/config.json'))
    end
    let(:policy_template) do
      File.read('factories/default/core/user/v1/policy.yml')
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'User Template',
          'description' => 'Creates a Conjur User',
          'wrap_with_policy' => false,
          'policy_template_variables' => {
            'owner_role' => {
              'description' => 'The Conjur Role that will own this user'
            },
            'owner_type' => {
              'description' => 'The resource type of the owner of this user'
            },
            'ip_range' => {
              'description' => 'Limits the network range the user is allowed to authenticate from'
            }
          }
        }
      )
    end
    it 'includes the expected policy template' do
      expect(policy_template).to eq(
        <<~POLICY
          - !user
            id: {{ id }}
          {{# owner_role }}
            {{# owner_type }}
            owner: !{{ owner_type }} {{ owner_role }}
            {{/ owner_type }}
          {{/ owner_role }}
          {{# ip_range }}
            restricted_to: {{ ip_range }}
          {{/ ip_range }}
            annotations:
          {{# annotations }}
              {{ key }}: {{ value }}
          {{/ annotations }}
        POLICY
      )
    end
  end
end
