# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Authenticators::AuthnJwt') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/authenticators/authn_jwt_jwks/v1/config.json'))
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Authn-JWT JWKS Template',
          'description' => 'Create a new Authn-JWT Authenticator using a JWKS endpoint',
          'default_policy_branch' => 'conjur/authn-jwt',
          'policy_type' => 'authenticator',
          'variables' => {
            'jwks-uri' => {
              'required' => true,
              'description' => 'The resource for a set of JSON-encoded public keys, one of which corresponds to the key used to digitally sign the JWT. The keys must be encoded as a JWK Set (RFC7517).'
            },
            'ca-cert' => {
              'description' => 'CA certificate used to connect to the JWKS endpoint'
            },
            'token-app-property' => {
              'required' => true,
              'description' => 'JWT claim used to identify the host identity'
            },
            'identity-path' => {
              'description' => 'The path that exists between host/ and the token-app-property claim value'
            },
            'issuer' => {
              'required' => true,
              'description' => 'The expected issuer of the JWT'
            },
            'enforced-claims' => {
              'description' => 'A list of claims that must be present in the JWT'
            },
            'mapping-claims' => {
              'description' => "You can map claim names to more user-friendly aliases in your app ID's host annotations, instead of the actual claim name"
            },
            'audience' => {
              'description' => 'The expected audience of the JWT'
            }
          }
        }
      )
    end
  end
end
