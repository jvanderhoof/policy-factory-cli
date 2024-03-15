# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Authenticators::AuthnGCP') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/authenticators/authn_gcp/v1/config.json'))
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Authn-GCP Template',
          'description' => 'Create a new Authn-GCP authenticator',
          'default_policy_branch' => 'conjur/authn-gcp',
          'policy_type' => 'authenticator'
        }
      )
    end
  end
end
