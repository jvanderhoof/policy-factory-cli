# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Authenticators::AuthnAWS') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/authenticators/authn_aws/v1/config.json'))
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Authn-AWS Template',
          'description' => 'Create a new Authn-AWS authenticator',
          'default_policy_branch' => 'conjur/authn-iam',
          'policy_type' => 'authenticator'
        }
      )
    end
  end
end
