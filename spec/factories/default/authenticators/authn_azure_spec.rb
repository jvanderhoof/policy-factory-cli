# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Authenticators::AuthnAzure') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/authenticators/authn_azure/v1/config.json'))
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Authn-Azure Template',
          'description' => 'Create a new Authn-Azure Authenticator',
          'default_policy_branch' => 'conjur/authn-azure',
          'policy_type' => 'authenticator',
          'variables' => {
            'provider-uri' => {
              'required' => true,
              'description' => 'Provider URI'
            }
          }
        }
      )
    end
  end
end
