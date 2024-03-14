
# frozen_string_literal: true

require 'spec_helper'
require './lib/compiler/generate_factory'
require 'base64'
require 'json'

describe(Compiler::GenerateFactory) do
  let(:name) { 'policy' }
  let(:version) { 'v1' }
  let(:classification) { 'core' }
  let(:policy_template) { nil }

  subject do
    JSON.parse(
      Base64.decode64(
        described_class
          .new(
            name: name,
            version: version,
            classification: classification
          ).generate(
            policy_template: policy_template,
            configuration: JSON.parse(configuration)
          )
      )
    )
  end

  def decoded_policy_template(policy)
    Base64.decode64(policy).encode('UTF-8')
  end

  describe '#generate' do
    context 'for factories without variables' do
      context 'when configuration is empty' do
        let(:name) { 'bar' }
        let(:classification) { 'foo' }
        let(:policy_template) { nil }
        let(:configuration) { '{}' }

        it 'generates a policy with a minimum policy template' do
          test_policy = <<~POLICY
            - !policy
              id: <%= id %>
              annotations:
            <% annotations.each do |key, value| -%>
                <%= key %>: <%= value %>
            <% end -%>
          POLICY
          expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
        end
        it 'uses the provided version' do
          expect(subject['version']).to eq('v1')
        end
        it 'generates a dynamic branch definition' do
          expect(subject['policy_branch']).to eq('<%= branch %>')
        end
        it 'generates a policy with a minimum schema' do
          expect(subject['schema']).to eq({
            "$schema" => "http://json-schema.org/draft-06/schema#",
            "description" => "",
            "properties" => {
              "annotations" => {
                "description"=>"Additional annotations",
                "type" => "object"
              },
              "branch" => {
                "description" => "Policy branch to apply this policy into",
                "type" => "string"
              },
              "id" => {
                "description" => "Resource Identifier",
                "type" => "string"
              }
            },
            "required" => ["branch", "id"],
            "title" => "",
            "type" => "object"
          })
        end
      end
      context 'when branch is defined' do
        let(:configuration) do
          { default_policy_branch: 'foo/bar' }.to_json
        end
        it 'generates a the defined branch definition' do
          expect(subject['policy_branch']).to eq('foo/bar')
        end
        it 'generates a schema with a without the branch input' do
          expect(subject['schema']).to eq({
            "$schema" => "http://json-schema.org/draft-06/schema#",
            "description" => "",
            "properties" => {
              "annotations" => {
                "description"=>"Additional annotations",
                "type" => "object"
              },
              "id" => {
                "description" => "Resource Identifier",
                "type" => "string"
              }
            },
            "required" => ["id"],
            "title" => "",
            "type" => "object"
          })
        end
        it 'generates a policy with a minimum policy template' do
          test_policy = <<~POLICY
            - !policy
              id: <%= id %>
              annotations:
            <% annotations.each do |key, value| -%>
                <%= key %>: <%= value %>
            <% end -%>
          POLICY
          expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
        end
      end
      context 'when the factory does not wrap with policy' do
        let(:configuration) do
          { wrap_with_policy: false }.to_json
        end
        it 'generates a schema default schema' do
          expect(subject['schema']).to eq({
            "$schema" => "http://json-schema.org/draft-06/schema#",
            "description" => "",
            "properties" => {
              "annotations" => {
                "description"=>"Additional annotations",
                "type" => "object"
              },
              "branch" => {
                "description" => "Policy branch to apply this policy into",
                "type" => "string"
              },
              "id" => {
                "description" => "Resource Identifier",
                "type" => "string"
              }
            },
            "required" => ["branch", "id"],
            "title" => "",
            "type" => "object"
          })
        end
        it 'generates a factory without a policy template' do
          expect(decoded_policy_template(subject['policy'])).to eq('')
        end
        context 'when the factory does not includes the identifier' do
          let(:configuration) do
            { wrap_with_policy: false, include_identifier: false }.to_json
          end
          it 'generates a schema without the identifier' do
            expect(subject['schema']).to eq({
              "$schema" => "http://json-schema.org/draft-06/schema#",
              "description" => "",
              "properties" => {
                "annotations" => {
                  "description"=>"Additional annotations",
                  "type" => "object"
                },
                "branch" => {
                  "description" => "Policy branch to apply this policy into",
                  "type" => "string"
                }
              },
              "required" => ["branch"],
              "title" => "",
              "type" => "object"
            })
          end
          it 'generates a factory without a policy template' do
            expect(decoded_policy_template(subject['policy'])).to eq('')
          end
        end
      end
      context 'when the factory wraps with policy' do
        context 'when the factory does not explicitly remove the identifier' do
          let(:configuration) do
            { wrap_with_policy: false, include_identifier: false }.to_json
          end
          it 'generates a schema without the identifier' do
            expect(subject['schema']).to eq({
              "$schema" => "http://json-schema.org/draft-06/schema#",
              "description" => "",
              "properties" => {
                "annotations" => {
                  "description"=>"Additional annotations",
                  "type" => "object"
                },
                "branch" => {
                  "description" => "Policy branch to apply this policy into",
                  "type" => "string"
                }
              },
              "required" => ["branch"],
              "title" => "",
              "type" => "object"
            })
          end
        end
        context 'when the factory includes the identifier' do
          let(:configuration) do
            { wrap_with_policy: false, include_identifier: true }.to_json
          end
          it 'generates a schema without the identifier' do
            expect(subject['schema']).to eq({
              "$schema" => "http://json-schema.org/draft-06/schema#",
              "description" => "",
              "properties" => {
                "annotations" => {
                  "description"=>"Additional annotations",
                  "type" => "object"
                },
                "branch" => {
                  "description" => "Policy branch to apply this policy into",
                  "type" => "string"
                },
                "id" => {
                  "description" => "Resource Identifier",
                  "type" => "string"
                }
              },
              "required" => ["branch", "id"],
              "title" => "",
              "type" => "object"
            })
          end
        end
      end
      context 'when the factory does not include the identifier' do
        let(:configuration) do
          { include_identifier: false }.to_json
        end
        it 'generates a schema without the id input' do
          expect(subject['schema']).to eq({
            "$schema" => "http://json-schema.org/draft-06/schema#",
            "description" => "",
            "properties" => {
              "annotations" => {
                "description"=>"Additional annotations",
                "type" => "object"
              },
              "branch" => {
                "description" => "Policy branch to apply this policy into",
                "type" => "string"
              },
            },
            "required" => ["branch"],
            "title" => "",
            "type" => "object"
          })
        end
        it 'generates a policy template without the identifier' do
          test_policy = <<~POLICY
            - !policy
              annotations:
            <% annotations.each do |key, value| -%>
                <%= key %>: <%= value %>
            <% end -%>
          POLICY
          expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
        end

      end



      # let(:name) { 'policy' }
      # let(:classification) { 'core' }

      # let(:configuration) do
      #   <<~CONFIG
      #     {
      #       "title": "Policy Template",
      #       "description": "Creates a Conjur Policy",
      #       "wrap_with_policy": false,
      #       "policy_template_variables": {
      #         "owner_role": { "description": "The Conjur Role that will own this policy" },
      #         "owner_type": { "description": "The resource type of the owner of this policy" }
      #       }
      #     }
      #   CONFIG
      # end
      # let(:policy_template) do
      #   <<~POLICY
      #   - !policy
      #     id: <%= id %>
      #   <% if defined?(owner_role) && defined?(owner_type) -%>
      #     owner: !<%= owner_type %> <%= owner_role %>
      #   <% end -%>
      #     annotations:
      #   <% annotations.each do |key, value| -%>
      #       <%= key %>: <%= value %>
      #   <% end -%>
      #   POLICY
      # end
      # context 'when the configuration is valid' do
      #   it 'return the expected schema' do
      #     expect(subject).to eq({
      #       "version" => "v1",
      #       "policy" => "LSAhcG9saWN5CiAgaWQ6IDwlPSBpZCAlPgo8JSBpZiBkZWZpbmVkPyhvd25lcl9yb2xlKSAmJiBkZWZpbmVkPyhvd25lcl90eXBlKSAtJT4KICBvd25lcjogITwlPSBvd25lcl90eXBlICU+IDwlPSBvd25lcl9yb2xlICU+CjwlIGVuZCAtJT4KICBhbm5vdGF0aW9uczoKPCUgYW5ub3RhdGlvbnMuZWFjaCBkbyB8a2V5LCB2YWx1ZXwgLSU+CiAgICA8JT0ga2V5ICU+OiA8JT0gdmFsdWUgJT4KPCUgZW5kIC0lPgo=",
      #       "policy_branch" => "<%= branch %>",
      #       "schema" => {
      #         "$schema" => "http://json-schema.org/draft-06/schema#",
      #         "title" => "Policy Template",
      #         "description" => "Creates a Conjur Policy",
      #         "type" => "object",
      #         "properties" => {
      #           "id" => {
      #             "description" => "Resource Identifier",
      #             "type" => "string"
      #           },
      #           "annotations" => {
      #             "description" => "Additional annotations",
      #             "type" => "object"
      #           },
      #           "branch" => {
      #             "description" => "Policy branch to apply this policy into",
      #             "type" => "string"
      #           },
      #           "owner_role" => {
      #             "description" => "The Conjur Role that will own this policy",
      #             "type" => "string"
      #           },
      #           "owner_type" => {
      #             "description" => "The resource type of the owner of this policy",
      #             "type" => "string"
      #           }
      #         },
      #         "required" => [
      #           "branch",
      #           "id"
      #         ]
      #       }
      #     })
      #   end
      # end
    end
    # context 'for factories with variables' do
    #   let(:name) { 'api' }
    #   let(:classification) { 'connection' }

    #   context 'when policy_type template is defined' do
    #     let(:configuration) do
    #       <<~CONFIG
    #         {
    #           "title": "API Connection Template",
    #           "description": "All information for connecting to an API",
    #           "policy_type": "variable-set",
    #           "variables": {
    #             "url": {
    #               "required": true,
    #               "description": "API Service URL"
    #             },
    #             "key": {
    #               "required": true,
    #               "description": "API Service Key"
    #             }
    #           }
    #         }
    #       CONFIG
    #     end
    #     it 'return the expected schema' do
    #       test_policy = <<~POLICY
    #           - !policy
    #             id: <%= id %>
    #             annotations:
    #           <% annotations.each do |key, value| -%>
    #               <%= key %>: <%= value %>
    #           <% end -%>

    #             body:
    #             - &variables
    #               - !variable url
    #               - !variable key

    #             - !group
    #               id: consumers
    #               annotations:
    #                 description: "Roles that can see and retrieve credentials."
    #             - !group
    #               id: administrators
    #               annotations:
    #                 description: "Roles that can update credentials."
    #             - !group
    #               id: circuit-breaker
    #               annotations:
    #                 description: Provides a mechanism for breaking access to this authenticator.
    #                 editable: true
    #             # Allows 'consumers' group to be cut in case of compromise
    #             - !grant
    #               member: !group consumers
    #               role: !group circuit-breaker
    #             # Administrators also has the consumers role
    #             - !grant
    #               member: !group administrators
    #               role: !group consumers
    #             # Consumers (via the circuit-breaker group) can read and execute
    #             - !permit
    #               resource: *variables
    #               privileges: [ read, execute ]
    #               role: !group circuit-breaker
    #             # Administrators can update (they have read and execute via the consumers group)
    #             - !permit
    #               resource: *variables
    #               privileges: [ update ]
    #               role: !group administrators
    #         POLICY

    #       factory = subject
    #       expect(factory['version']).to eq('v1')
    #       decoded_factory = Base64.decode64(factory['policy']).encode('UTF-8')
    #       expect(decoded_factory).to eq(test_policy.strip)
    #       expect(factory['policy_branch']).to eq('<%= branch %>')
    #       expect(factory['schema']).to eq({
    #         "$schema"=>"http://json-schema.org/draft-06/schema#",
    #         "title"=>"API Connection Template",
    #         "description"=>"All information for connecting to an API",
    #         "type"=>"object",
    #         "properties"=> {
    #           "id" =>{ "description"=>"Resource Identifier", "type"=>"string" },
    #           "annotations" => { "description"=>"Additional annotations", "type"=>"object" },
    #           "branch" => { "description" => "Policy branch to apply this policy into", "type"=>"string" },
    #           "variables" => {
    #             "type"=>"object",
    #             "properties"=> {
    #               "url" => {
    #                 "description" => "API Service URL",
    #                 "type"=>"string"
    #               },
    #               "key" => {
    #                 "description" => "API Service Key",
    #                 "type"=>"string"
    #               }
    #             },
    #             "required"=>["url", "key"]
    #           }
    #         },
    #         "required" => [ "branch", "id", "variables" ]
    #       })
    #     end
    #   end
    # end
  end
end
