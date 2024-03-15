# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Authenticators::AuthnOidc') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/authenticators/authn_oidc/v1/config.json'))
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Authn-OIDC Template',
          'description' => 'Create a new Authn-OIDC Authenticator',
          'default_policy_branch' => 'conjur/authn-oidc',
          'policy_type' => 'authenticator',
          'variables' => {
            'provider-uri' => {
              'required' => true,
              'description' => 'OIDC Provider endpoint'
            },
            'client-id' => {
              'required' => true,
              'description' => 'OIDC Client ID'
            },
            'client-secret' => {
              'required' => true,
              'description' => 'OIDC Client Secret'
            },
            'redirect-uri' => {
              'description' => 'Target URL to redirect to after successful authentication'
            },
            'claim-mapping' => {
              'required' => true,
              'description' => 'OIDC JWT claim mapping. This value must match to a Conjur Host ID.'
            }
          }
        }
      )
    end
  end
end
