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
            'database-type' => {
              'required' => true,
              'description' => 'The type of database this connection is',
              'title' => 'Type',
              'valid_values' => ['sqlserver', 'postgresql', 'mysql', 'oracle', 'db2', 'sqlite']
            },
            'url' => {
              'required' => true,
              'title' => 'URL'
            },
            'port' => {
              'required' => true,
              'title' => 'Port',
              'default' => '5432'
            },
            'username' => {
              'required' => true,
              'title' => 'Username'
            },
            'password' => {
              'required' => true,
              'title' => 'Password'
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
