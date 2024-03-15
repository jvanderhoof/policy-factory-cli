# frozen_string_literal: true

require 'spec_helper'

describe('Factories::Default::Connections::Database') do
  context 'v1' do
    let(:schema) do
      JSON.parse(File.read('factories/default/connections/database/v1/config.json'))
    end
    it 'includes the expected schema' do
      expect(schema).to eq(
        {
          'title' => 'Database Connection Template',
          'description' => 'All information for connecting to a database',
          'policy_type' => 'variable-set',
          'variables' => {
            'type' => {
              'required' => true,
              'description' => 'Database Type',
              'valid_values' => ['sqlserver', 'postgresql', 'mysql', 'oracle', 'db2', 'sqlite']
            },
            'url' => {
              'required' => true,
              'description' => 'Database URL'
            },
            'port' => {
              'required' => true,
              'description' => 'Database Port'
            },
            'username' => {
              'required' => true,
              'description' => 'Database Username'
            },
            'password' => {
              'required' => true,
              'description' => 'Database Password'
            },
            'ssl-certificate' => {
              'description' => 'Client SSL Certificate'
            },
            'ssl-key' => {
              'description' => 'Client SSL Key'
            },
            'ssl-ca-certificate' => {
              'description' => 'CA Root Certificate'
            }
          }
        }
      )
    end
  end
end
