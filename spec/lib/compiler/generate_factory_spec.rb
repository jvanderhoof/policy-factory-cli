
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
      context 'when the factory is not wrapped with policy' do
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
        context 'when the factory removes the identifier' do
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
      context 'when the factory is wrapped in policy' do
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
      context 'when the factory is wrapped in policy but excludes the identifier' do
        let(:configuration) do
          { include_identifier: false }.to_json
        end
        it 'generates a schema with the id input' do
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
        it 'generates a policy template without the identifier' do
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
      context 'when annotations are excluded' do
        let(:configuration) do
          { include_annotations: false }.to_json
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

        it 'generates a schema without annotations' do
          expect(subject['schema']).to eq({
            "$schema" => "http://json-schema.org/draft-06/schema#",
            "description" => "",
            "properties" => {
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
      context 'when policy template variables are defined' do
        let(:configuration) do
          { policy_template_variables: {foo: {}} }.to_json
        end
        it 'generates a schema with the defined variable' do
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
              },
              "foo" => {
                "description" => "",
                "type" => "string"
              }
            },
            "required" => ["branch", "id"],
            "title" => "",
            "type" => "object"
          })
        end
        context 'when it is required' do
          let(:configuration) do
            { policy_template_variables: {foo: { required: true }} }.to_json
          end
          it 'generates a schema with the defined variable' do
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
                },
                "foo" => {
                  "description" => "",
                  "type" => "string"
                }
              },
              "required" => ["branch", "id", "foo"],
              "title" => "",
              "type" => "object"
            })
          end
        end
        context 'when it has a description' do
          let(:configuration) do
            { policy_template_variables: {foo: { description: 'foo-bar' }} }.to_json
          end
          it 'generates a schema with the defined variable' do
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
                },
                "foo" => {
                  "description" => "foo-bar",
                  "type" => "string"
                }
              },
              "required" => ["branch", "id"],
              "title" => "",
              "type" => "object"
            })
          end
        end
        context 'when it has a defined set of options' do
          let(:configuration) do
            { policy_template_variables: {foo: { valid_values: %w[foo bar] }} }.to_json
          end
          it 'generates a schema with the defined variable' do
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
                },
                "foo" => {
                  "description" => "",
                  "type" => "string",
                  "enum" => ["foo", "bar"]
                }
              },
              "required" => ["branch", "id"],
              "title" => "",
              "type" => "object"
            })
          end
        end
        context 'when it has a default value' do
          let(:configuration) do
            { policy_template_variables: {foo: { default: 'foo-bar-baz' }} }.to_json
          end
          it 'generates a schema with the defined variable' do
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
                },
                "foo" => {
                  "description" => "",
                  "type" => "string",
                  "default" => "foo-bar-baz"
                }
              },
              "required" => ["branch", "id"],
              "title" => "",
              "type" => "object"
            })
          end
        end
      end
    end
    context 'when variables are defined' do
      let(:configuration) do
        { variables: {foo: { }} }.to_json
      end
      it 'generates a policy with a minimum policy template' do
        test_policy = <<~POLICY
          - !policy
            id: <%= id %>
            annotations:
          <% annotations.each do |key, value| -%>
              <%= key %>: <%= value %>
          <% end -%>

            body:
            - &variables
              - !variable foo
        POLICY
        expect(decoded_policy_template(subject['policy'])).to eq(test_policy)
      end
      it 'generates a schema with the defined variable' do
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
            },
            "variables" => {
              "type" => "object",
              "properties" => {
                "foo" => {
                  "description" => "",
                  "type" => "string"
                }
              },
              "required" => []
            }
          },
          "required" => ["branch", "id", "variables"],
          "title" => "",
          "type" => "object"
        })
      end
      context 'when a variable group is not required' do
        let(:configuration) do
          { with_variable_group: false, variables: {foo: { }} }.to_json
        end
        it 'generates a policy with a minimum policy template' do
          test_policy = <<~POLICY
            - !policy
              id: <%= id %>
              annotations:
            <% annotations.each do |key, value| -%>
                <%= key %>: <%= value %>
            <% end -%>

              body:
              - !variable foo
          POLICY
          expect(decoded_policy_template(subject['policy'])).to eq(test_policy)
        end

      end
      context 'when it has a description' do
        let(:configuration) do
          { variables: { foo: { description: 'this is foo' }}}.to_json
        end
        it 'generates a schema with the defined variable' do
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
              },
              "variables" => {
                "type" => "object",
                "properties" => {
                  "foo" => {
                    "description" => "this is foo",
                    "type" => "string"
                  }
                },
                "required" => []
              }
            },
            "required" => ["branch", "id", "variables"],
            "title" => "",
            "type" => "object"
          })
        end
      end
      context 'when it is required' do
        let(:configuration) do
          { variables: {foo: { required: true }} }.to_json
        end
        it 'generates a schema with the defined variable' do
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
              },
              "variables" => {
                "type" => "object",
                "properties" => {
                  "foo" => {
                    "description" => "",
                    "type" => "string"
                  }
                },
                "required" => ["foo"]
              }
            },
            "required" => ["branch", "id", "variables"],
            "title" => "",
            "type" => "object"
          })
        end
      end
      context 'when it has a defined set of options' do
        let(:configuration) do
          { variables: {foo: { valid_values: %w[foo bar] }} }.to_json
        end
        it 'generates a schema with the defined variable' do
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
              },
              "variables" => {
                "type" => "object",
                "properties" => {
                  "foo" => {
                    "description" => "",
                    "type" => "string",
                    "enum" => ["foo", "bar"]
                  }
                },
                "required" => []
              }
            },
            "required" => ["branch", "id", "variables"],
            "title" => "",
            "type" => "object"
          })
        end
      end
      context 'when it has a default value' do
        let(:configuration) do
          { variables: {foo: { default: 'foo-bar' }} }.to_json
        end
        it 'generates a schema with the defined variable' do
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
              },
              "variables" => {
                "type" => "object",
                "properties" => {
                  "foo" => {
                    "description" => "",
                    "type" => "string",
                    "default" => "foo-bar"
                  }
                },
                "required" => []
              }
            },
            "required" => ["branch", "id", "variables"],
            "title" => "",
            "type" => "object"
          })
        end
      end
    end
    context 'when a default template is provided' do
      let(:configuration) do
        { policy_type: 'variable-set' }.to_json
      end
      it 'generates a policy with a referenced policy template' do
        test_policy = <<~POLICY
          - !policy
            id: <%= id %>
            annotations:
          <% annotations.each do |key, value| -%>
              <%= key %>: <%= value %>
          <% end -%>

            body:
            - !group
              id: consumers
              annotations:
                description: "Roles that can see and retrieve credentials."
            - !group
              id: administrators
              annotations:
                description: "Roles that can update credentials."
            - !group
              id: circuit-breaker
              annotations:
                description: Provides a mechanism for breaking access to this authenticator.
                editable: true
            # Allows 'consumers' group to be cut in case of compromise
            - !grant
              member: !group consumers
              role: !group circuit-breaker
            # Administrators also has the consumers role
            - !grant
              member: !group administrators
              role: !group consumers
            # Consumers (via the circuit-breaker group) can read and execute
            - !permit
              resource: *variables
              privileges: [ read, execute ]
              role: !group circuit-breaker
            # Administrators can update (they have read and execute via the consumers group)
            - !permit
              resource: *variables
              privileges: [ update ]
              role: !group administrators
        POLICY
        expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
      end
      context 'when a non-existing template is provided' do
        let(:configuration) do
          { policy_type: 'fake-template' }.to_json
        end
        it 'generates a policy without the referenced policy template' do
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
      context 'when variables are defined' do
        let(:configuration) do
          { policy_type: 'variable-set', variables: { foo: {} }}.to_json
        end
        it 'generates a policy with a referenced policy template' do
          test_policy = <<~POLICY
            - !policy
              id: <%= id %>
              annotations:
            <% annotations.each do |key, value| -%>
                <%= key %>: <%= value %>
            <% end -%>

              body:
              - &variables
                - !variable foo

              - !group
                id: consumers
                annotations:
                  description: "Roles that can see and retrieve credentials."
              - !group
                id: administrators
                annotations:
                  description: "Roles that can update credentials."
              - !group
                id: circuit-breaker
                annotations:
                  description: Provides a mechanism for breaking access to this authenticator.
                  editable: true
              # Allows 'consumers' group to be cut in case of compromise
              - !grant
                member: !group consumers
                role: !group circuit-breaker
              # Administrators also has the consumers role
              - !grant
                member: !group administrators
                role: !group consumers
              # Consumers (via the circuit-breaker group) can read and execute
              - !permit
                resource: *variables
                privileges: [ read, execute ]
                role: !group circuit-breaker
              # Administrators can update (they have read and execute via the consumers group)
              - !permit
                resource: *variables
                privileges: [ update ]
                role: !group administrators
          POLICY
          expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
        end
      end
    end
  end
end
