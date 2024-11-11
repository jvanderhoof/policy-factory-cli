# frozen_string_literal: true

require 'spec_helper'
require './lib/compiler/generate_factory'
require 'base64'
require 'json'

describe(Compiler::GenerateFactory) do
  let(:name) { 'policy' }
  let(:version) { 'v1' }
  let(:classification) { 'core' }
  let(:policy_template) { '- !host foo-bar' }

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
    context 'when policy template is empty' do
      let(:policy_template) { nil }
      let(:configuration) { {}.to_json }
      it 'returns an appropriate error' do
        expect { subject }.to raise_error(
          RuntimeError,
          "No policy template found (and policy-type was not set)."
        )
      end
      context 'when policy_type template is defined' do
        context 'when policy_type template does not exist' do
          let(:configuration) { { policy_type: 'foo-bar' }.to_json }
          it 'returns an appropriate error' do
            expect { subject }.to raise_error(
              RuntimeError,
              "Factory defines 'policy-type' but the template 'foo_bar' is not a valid template option."
            )
          end
        end
      end
    end
    context 'when factory template is present' do
      context 'when configuration is empty' do
        let(:configuration) { {}.to_json }
        let(:default_schema) do
          {
            "$schema" => "http://json-schema.org/draft-06/schema#",
            "description" => "",
            "properties" => {
              "annotations" => {
                "title" => "Annotations",
                "description" => "Additional annotations",
                "type" => "object"
              },
              "branch" => {
                "title" => "Policy Branch",
                "description" => "Policy branch to apply this policy to",
                "type" => "string"
              },
              "id" => {
                "title" => "Resource Identifier",
                "description" => '',
                "type" => "string"
              }
            },
            "required" => ["branch", "id"],
            "title" => "Policy Factory",
            "type" => "object"
          }
        end
        it 'does not modiify the provided policy' do
          expect(decoded_policy_template(subject['policy'])).to eq(policy_template)
        end
        it 'derives the title from the Factory path' do
          expect(subject['schema']).to eq(default_schema)
        end
        it 'includes the default branch' do
          expect(subject['policy_branch']).to eq("{{ branch }}")
        end
      end
      context 'title' do
        context 'when the factory title is set' do
          let(:configuration) { { title: 'foo-bar' }.to_json }
          it 'uses the provided title' do
            expect(subject['schema']['title']).to eq('foo-bar')
          end
          context "when the title is empty" do
            let(:configuration) { { title: '' }.to_json }
            it 'uses the factory name in the title' do
              expect(subject['schema']['title']).to eq('Policy Factory')
            end
          end
        end
        context "when the title is missing" do
          let(:configuration) { { }.to_json }
          it 'uses the factory name in the title' do
            expect(subject['schema']['title']).to eq('Policy Factory')
          end
        end
      end
      context 'description' do
        context 'when the description is set' do
          let(:configuration) { { description: 'foo-bar' }.to_json }
          it 'uses the provided title' do
            expect(subject['schema']['description']).to eq('foo-bar')
          end
          context 'when description is empty' do
            let(:configuration) { { description: '' }.to_json }
            it 'includes an empty description' do
              expect(subject['schema']['description']).to eq('')
            end
          end
        end
        context 'when description is missing' do
          let(:configuration) { { }.to_json }
          it 'includes an empty description' do
            expect(subject['schema']['description']).to eq('')
          end
        end
      end
      context 'default_policy_branch' do
        context 'when the factory policy branch is defined' do
          let(:configuration) do
            { default_policy_branch: 'foo/bar' }.to_json
          end
          it 'includes the defined branch' do
            expect(subject['policy_branch']).to eq('foo/bar')
          end
          it 'generates a schema without the branch as an input' do
            expect(subject['schema']).to eq({
              "$schema" => "http://json-schema.org/draft-06/schema#",
              "description" => "",
              "properties" => {
                "annotations" => {
                  "title" => "Annotations",
                  "description" => "Additional annotations",
                  "type" => "object"
                },
                "id" => {
                  "title" => "Resource Identifier",
                  "description" => '',
                  "type" => "string"
                }
              },
              "required" => ["id"],
              "title" => "Policy Factory",
              "type" => "object"
            })
          end
        end
      end
      context 'wrap_with_policy' do
        let(:configuration) { { wrap_with_policy: true }.to_json }
        context 'when template is missing' do
          let(:policy_template) { nil }
          it 'results in an appropriate error' do
            expect { subject }.to raise_error(RuntimeError, 'No policy template found (and policy-type was not set).')
          end
        end
        context 'when policy template is present' do
          # let(:policy_template) { '- !host foo-bar' }
          it 'wraps the provided template in a policy' do
            test_policy = <<~POLICY
            - !policy
              id: {{ id }}
              annotations:
              {{# annotations }}
                {{ key }}: {{ value }}
              {{/ annotations }}

              body:
              - !host foo-bar
            POLICY
            expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
          end
          context 'when the identifier is removed' do
            let(:configuration) { { wrap_with_policy: true, include_identifier: false }.to_json }
            it 'returns a schema with the identifer to ensure the policy is valid' do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "annotations" => {
                    "title" => "Annotations",
                    "description" => "Additional annotations",
                    "type" => "object"
                  },
                  "branch" => {
                    "title" => "Policy Branch",
                    "description" => "Policy branch to apply this policy to",
                    "type" => "string"
                  },
                  "id" => {
                    "title" => "Resource Identifier",
                    "description" => '',
                    "type" => "string"
                  }
                },
                "required" => ["branch", "id"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
          context 'when annotations are removed' do
            let(:configuration) { { wrap_with_policy: true, include_annotations: false }.to_json }
            it 'generates a schema without annotations' do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "branch" => {
                    "title" => "Policy Branch",
                    "description" => "Policy branch to apply this policy to",
                    "type" => "string"
                  },
                  "id" => {
                    "title" => "Resource Identifier",
                    "description" => '',
                    "type" => "string"
                  }
                },
                "required" => ["branch", "id"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
            it 'still includes annotations in the policy' do
              test_policy = <<~POLICY
              - !policy
                id: {{ id }}
                annotations:
                {{# annotations }}
                  {{ key }}: {{ value }}
                {{/ annotations }}

                body:
                - !host foo-bar
              POLICY
              expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
            end
          end
        end
      end
      context 'include_identifier' do
        context 'when it is set ' do
          context 'to false' do
            let(:configuration) { { include_identifier: false }.to_json }
            it 'generates a schema without an id' do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "annotations" => {
                    "description" => "Additional annotations",
                    "title" => "Annotations",
                    "type" => "object"
                  },
                  "branch" => {
                    "title" => "Policy Branch",
                    "description" => "Policy branch to apply this policy to",
                    "type" => "string"
                  }
                },
                "required" => ["branch"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
          context 'to true' do
            let(:configuration) { { include_identifier: true }.to_json }
            it 'generates a schema with an id' do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "annotations" => {
                    "description" => "Additional annotations",
                    "title" => "Annotations",
                    "type" => "object"
                  },
                  "branch" => {
                    "title" => "Policy Branch",
                    "description" => "Policy branch to apply this policy to",
                    "type" => "string"
                  },
                  "id" => {
                    "title" => "Resource Identifier",
                    "description" => '',
                    "type" => "string"
                  }
                },
                "required" => ["branch", "id"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
        end
        context 'when it is not set' do
          let(:configuration) { { }.to_json }
          it 'generates a schema with an id' do
            expect(subject['schema']).to eq({
              "$schema" => "http://json-schema.org/draft-06/schema#",
              "description" => "",
              "properties" => {
                "annotations" => {
                  "description" => "Additional annotations",
                  "title" => "Annotations",
                  "type" => "object"
                },
                "branch" => {
                  "title" => "Policy Branch",
                  "description" => "Policy branch to apply this policy to",
                  "type" => "string"
                },
                "id" => {
                  "title" => "Resource Identifier",
                  "description" => '',
                  "type" => "string"
                }
              },
              "required" => ["branch", "id"],
              "title" => "Policy Factory",
              "type" => "object"
            })
          end
        end
      end
      context 'include_annotations' do
        context 'when it is set ' do
          context 'to false' do
            let(:configuration) { { include_annotations: false }.to_json }
            it 'generates a schema without annotations' do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "branch" => {
                    "title" => "Policy Branch",
                    "description" => "Policy branch to apply this policy to",
                    "type" => "string"
                  },
                  "id" => {
                    "title" => "Resource Identifier",
                    "description" => '',
                    "type" => "string"
                  }
                },
                "required" => ["branch", "id"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
          context 'to true' do
            let(:configuration) { { include_annotations: true }.to_json }
            it 'generates a schema with annotations' do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "annotations" => {
                    "description" => "Additional annotations",
                    "title" => "Annotations",
                    "type" => "object"
                  },
                  "branch" => {
                    "title" => "Policy Branch",
                    "description" => "Policy branch to apply this policy to",
                    "type" => "string"
                  },
                  "id" => {
                    "title" => "Resource Identifier",
                    "description" => '',
                    "type" => "string"
                  }
                },
                "required" => ["branch", "id"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
        end
        context 'when it is not set' do
          let(:configuration) { { }.to_json }
          it 'generates a schema with annotations' do
            expect(subject['schema']).to eq({
              "$schema" => "http://json-schema.org/draft-06/schema#",
              "description" => "",
              "properties" => {
                "annotations" => {
                  "description" => "Additional annotations",
                  "title" => "Annotations",
                  "type" => "object"
                },
                "branch" => {
                  "title" => "Policy Branch",
                  "description" => "Policy branch to apply this policy to",
                  "type" => "string"
                },
                "id" => {
                  "title" => "Resource Identifier",
                  "description" => '',
                  "type" => "string"
                }
              },
              "required" => ["branch", "id"],
              "title" => "Policy Factory",
              "type" => "object"
            })
          end
        end
      end
      context 'policy_type' do
        context 'when a template is also present' do
          let(:configuration) { { policy_type: 'variable-set'}.to_json }
          context 'when the factory includes a local policy template' do
            it 'raises an appropriate error message' do
              expect { subject }.to raise_error(
                RuntimeError,
                "A factory cannot define 'policy-type' and include a policy.yml template. Please choose one or the other."
              )
            end
          end
        end
        context 'when a factory template is not present' do
          let(:policy_template) { nil }
          let(:configuration) { { policy_type: 'variable-set'}.to_json }
          it 'wraps the provided template in a policy' do
            test_policy = <<~POLICY
              - !policy
                id: {{ id }}
                annotations:
                {{# annotations }}
                  {{ key }}: {{ value }}
                {{/ annotations }}

                body:
                - !group
                  id: consumers
                  annotations:
                    description: "Roles that can see and retrieve credentials."
                - !group
                  id: administrators
                  annotations:
                    description: "Roles that can update credentials."
                # Administrators also has the consumers role
                - !grant
                  member: !group administrators
                  role: !group consumers
                # Consumers can read and execute
                - !permit
                  resource: *variables
                  privileges: [ read, execute ]
                  role: !group consumers
                # Administrators can update (they have read and execute via the consumers group)
                - !permit
                  resource: *variables
                  privileges: [ update ]
                  role: !group administrators
            POLICY
            expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
          end
          context 'when the identifier is removed' do
            let(:configuration) { { policy_type: 'variable-set', include_identifier: false }.to_json }
            it 'is ignored' do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "annotations" => {
                    "description" => "Additional annotations",
                    "title" => "Annotations",
                    "type" => "object"
                  },
                  "branch" => {
                    "title" => "Policy Branch",
                    "description" => "Policy branch to apply this policy to",
                    "type" => "string"
                  },
                  "id" => {
                    "title" => "Resource Identifier",
                    "description" => '',
                    "type" => "string"
                  }
                },
                "required" => ["branch", "id"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
          context 'when the policy wrap is disabled' do
            let(:configuration) { { policy_type: 'variable-set', wrap_with_policy: false }.to_json }
            it 'ignores the policy-wrap setting' do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "annotations" => {
                    "description" => "Additional annotations",
                    "title" => "Annotations",
                    "type" => "object"
                  },
                  "branch" => {
                    "title" => "Policy Branch",
                    "description" => "Policy branch to apply this policy to",
                    "type" => "string"
                  },
                  "id" => {
                    "title" => "Resource Identifier",
                    "description" => '',
                    "type" => "string"
                  }
                },
                "required" => ["branch", "id"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
          context 'when the default template is an authenticator' do
            let(:configuration) do
              { policy_type: 'authenticator' }.to_json
            end
            it 'generates a policy with the authenticator policy template' do
              test_policy = <<~POLICY
                - !policy
                  id: {{ id }}
                  annotations:
                  {{# annotations }}
                    {{ key }}: {{ value }}
                  {{/ annotations }}

                  body:
                  - !webservice
                  - !group
                    id: authenticatable
                    annotations:
                      description: "Roles that can authenticate using this authenticator."
                  # Roles that can authenticate
                  - !permit
                    role: !group authenticatable
                    privilege: [ read, authenticate ]
                    resource: !webservice
                  # Enables Authenticator Status checking/troubleshooting
                  - !webservice
                    id: status
                    annotations:
                      description: Web service for checking authenticator status
                  - !group
                    id: operators
                    annotations:
                      description: Group with permission to check the authenticator status
                  - !permit
                    role: !group operators
                    privilege: [ read ]
                    resource: !webservice status
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
                  id: {{ id }}
                  annotations:
                  {{# annotations }}
                    {{ key }}: {{ value }}
                  {{/ annotations }}

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
                  # Administrators also has the consumers role
                  - !grant
                    member: !group administrators
                    role: !group consumers
                  # Consumers can read and execute
                  - !permit
                    resource: *variables
                    privileges: [ read, execute ]
                    role: !group consumers
                  # Administrators can update (they have read and execute via the consumers group)
                  - !permit
                    resource: *variables
                    privileges: [ update ]
                    role: !group administrators
              POLICY
              expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
            end
            it 'generates a schema with the variable included' do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "annotations" => {
                    "description" => "Additional annotations",
                    "title" => "Annotations",
                    "type" => "object"
                  },
                  "branch" => {
                    "title" => "Policy Branch",
                    "description" => "Policy branch to apply this policy to",
                    "type" => "string"
                  },
                  "id" => {
                    "title" => "Resource Identifier",
                    "description" => '',
                    "type" => "string"
                  },
                  "variables" => {
                    "properties" => {
                      "foo" => {
                        "description" => "",
                        "title" => "Foo",
                        "type" => "string"
                      }
                    },
                    "required" => [],
                    "type" => "object"
                  }
                },
                "required" => ["branch", "id"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
        end
      end
      context 'policy_template_variables' do
        context 'for internal variables' do
          context 'id' do
            context 'when no configuration is provided' do
              let(:configuration) { {}.to_json }
              it 'generates a schema with the default title' do
                expect(subject['schema']['properties']['id']).to eq({
                  'title' => 'Resource Identifier',
                  'description' => '',
                  'type' => 'string'
                })
              end
            end
            context 'title' do
              context 'when title is provided' do
                let(:configuration) { { policy_template_variables: { id: { title: 'foo-bar' }} }.to_json }
                it 'generates a schema with the title overwritten' do
                  expect(subject['schema']['properties']['id']).to eq({
                    'title' => 'foo-bar',
                    'description' => '',
                    'type' => 'string'
                  })
                end
              end
            end
            context 'description' do
              context 'when description is provided' do
                let(:configuration) { { policy_template_variables: { id: { description: 'foo-bar' }} }.to_json }
                it 'generates a schema with the description overwritten' do
                  expect(subject['schema']['properties']['id']).to eq({
                    'title' => 'Resource Identifier',
                    'description' => 'foo-bar',
                    'type' => 'string'
                  })
                end
              end
            end
            context 'default' do
              context 'when default is provided' do
                let(:configuration) { { policy_template_variables: { id: { default: 'foo-bar' }} }.to_json }
                it 'generates a schema with the default set' do
                  expect(subject['schema']['properties']['id']).to eq({
                    'title' => 'Resource Identifier',
                    'description' => '',
                    'default' => 'foo-bar',
                    'type' => 'string'
                  })
                end
              end
            end
            context 'valid-values' do
              context 'when valid-values are provided' do
                let(:configuration) { { policy_template_variables: { id: { valid_values: ['foo', 'bar'] }} }.to_json }
                it 'generates a schema with the enum defined' do
                  expect(subject['schema']['properties']['id']).to eq({
                    'title' => 'Resource Identifier',
                    'description' => '',
                    'enum' => ['foo', 'bar'],
                    'type' => 'string'
                  })
                end
              end
            end
            context 'hidden' do
              context 'when hidden is set to true' do
                let(:configuration) { { policy_template_variables: { id: { hidden: true }} }.to_json }
                it 'generates a schema with readOnly set' do
                  expect(subject['schema']['properties']['id']).to eq({
                    'title' => 'Resource Identifier',
                    'description' => '',
                    'readOnly' => true,
                    'type' => 'string'
                  })
                end
              end
              context 'when hidden is set to false' do
                let(:configuration) { { policy_template_variables: { id: { hidden: false }} }.to_json }
                it 'generates a schema without readOnly set' do
                  expect(subject['schema']['properties']['id']).to eq({
                    'title' => 'Resource Identifier',
                    'description' => '',
                    'type' => 'string'
                  })
                end
              end
            end
          end
          context 'annotations' do
            context 'when no configuration is provided' do
              let(:configuration) { {}.to_json }
              it 'generates a schema with the default title' do
                expect(subject['schema']['properties']['annotations']).to eq({
                  'title' => 'Annotations',
                  'description' => 'Additional annotations',
                  'type' => 'object'
                })
              end
            end
            context 'title' do
              context 'when title is provided' do
                let(:configuration) { { policy_template_variables: { annotations: { title: 'foo-bar' }} }.to_json }
                it 'generates a schema with the title overwritten' do
                  expect(subject['schema']['properties']['annotations']).to eq({
                    'title' => 'foo-bar',
                    'description' => 'Additional annotations',
                    'type' => 'object'
                  })
                end
              end
            end
            context 'description' do
              context 'when description is provided' do
                let(:configuration) { { policy_template_variables: { annotations: { description: 'foo-bar' }} }.to_json }
                it 'generates a schema with the description overwritten' do
                  expect(subject['schema']['properties']['annotations']).to eq({
                    'title' => 'Annotations',
                    'description' => 'foo-bar',
                    'type' => 'object'
                  })
                end
              end
            end
            context 'default' do
              context 'when default is provided' do
                let(:configuration) { { policy_template_variables: { annotations: { default: 'foo-bar' }} }.to_json }
                it 'generates a schema with the default set' do
                  expect(subject['schema']['properties']['annotations']).to eq({
                    'title' => 'Annotations',
                    'description' => 'Additional annotations',
                    'default' => 'foo-bar',
                    'type' => 'object'
                  })
                end
              end
            end
            context 'valid-values' do
              context 'when valid-values are provided' do
                let(:configuration) { { policy_template_variables: { annotations: { valid_values: ['foo', 'bar'] }} }.to_json }
                it 'generates a schema with the enum defined' do
                  expect(subject['schema']['properties']['annotations']).to eq({
                    'title' => 'Annotations',
                    'description' => 'Additional annotations',
                    'enum' => ['foo', 'bar'],
                    'type' => 'object'
                  })
                end
              end
            end
            context 'hidden' do
              context 'when hidden is set to true' do
                let(:configuration) { { policy_template_variables: { annotations: { hidden: true }} }.to_json }
                it 'generates a schema with readOnly set' do
                  expect(subject['schema']['properties']['annotations']).to eq({
                    'title' => 'Annotations',
                    'description' => 'Additional annotations',
                    'readOnly' => true,
                    'type' => 'object'
                  })
                end
              end
              context 'when hidden is set to false' do
                let(:configuration) { { policy_template_variables: { annotations: { hidden: false }} }.to_json }
                it 'generates a schema without readOnly set' do
                  expect(subject['schema']['properties']['annotations']).to eq({
                    'title' => 'Annotations',
                    'description' => 'Additional annotations',
                    'type' => 'object'
                  })
                end
              end
            end
          end
          context 'branch' do
            context 'when no configuration is provided' do
              let(:configuration) { {}.to_json }
              it 'generates a schema with the default title' do
                expect(subject['schema']['properties']['branch']).to eq({
                  'title' => 'Policy Branch',
                  'description' => 'Policy branch to apply this policy to',
                  'type' => 'string'
                })
              end
            end
            context 'title' do
              context 'when title is provided' do
                let(:configuration) { { policy_template_variables: { branch: { title: 'foo-bar' }} }.to_json }
                it 'generates a schema with the title overwritten' do
                  expect(subject['schema']['properties']['branch']).to eq({
                    'title' => 'foo-bar',
                    'description' => 'Policy branch to apply this policy to',
                    'type' => 'string'
                  })
                end
              end
            end
            context 'description' do
              context 'when description is provided' do
                let(:configuration) { { policy_template_variables: { branch: { description: 'foo-bar' }} }.to_json }
                it 'generates a schema with the description overwritten' do
                  expect(subject['schema']['properties']['branch']).to eq({
                    'title' => 'Policy Branch',
                    'description' => 'foo-bar',
                    'type' => 'string'
                  })
                end
              end
            end
            context 'default' do
              context 'when default is provided' do
                let(:configuration) { { policy_template_variables: { branch: { default: 'foo-bar' }} }.to_json }
                it 'generates a schema with the default set' do
                  expect(subject['schema']['properties']['branch']).to eq({
                    'title' => 'Policy Branch',
                    'description' => 'Policy branch to apply this policy to',
                    'default' => 'foo-bar',
                    'type' => 'string'
                  })
                end
              end
            end
            context 'valid-values' do
              context 'when valid-values are provided' do
                let(:configuration) { { policy_template_variables: { branch: { valid_values: ['foo', 'bar'] }} }.to_json }
                it 'generates a schema with the enum defined' do
                  expect(subject['schema']['properties']['branch']).to eq({
                    'title' => 'Policy Branch',
                    'description' => 'Policy branch to apply this policy to',
                    'enum' => ['foo', 'bar'],
                    'type' => 'string'
                  })
                end
              end
            end
            context 'hidden' do
              context 'when hidden is set to true' do
                let(:configuration) { { policy_template_variables: { branch: { hidden: true }} }.to_json }
                it 'generates a schema with readOnly set' do
                  expect(subject['schema']['properties']['branch']).to eq({
                    'title' => 'Policy Branch',
                    'description' => 'Policy branch to apply this policy to',
                    'readOnly' => true,
                    'type' => 'string'
                  })
                end
              end
              context 'when hidden is set to false' do
                let(:configuration) { { policy_template_variables: { branch: { hidden: false }} }.to_json }
                it 'generates a schema without readOnly set' do
                  expect(subject['schema']['properties']['branch']).to eq({
                    'title' => 'Policy Branch',
                    'description' => 'Policy branch to apply this policy to',
                    'type' => 'string'
                  })
                end
              end
            end
          end
        end
        context 'for normal variables' do
          context 'when no configuration is provided' do
            let(:configuration) { { policy_template_variables: { foo: {} } }.to_json }
            it 'the title is a capitalized version of the id' do
              expect(subject['schema']['properties']['foo']).to eq({
                'title' => 'Foo',
                'description' => '',
                'type' => 'string'
              })
            end
          end
          context 'title' do
            context 'when title is provided' do
              let(:configuration) { { policy_template_variables: { foo: { title: 'foo-bar' }} }.to_json }
              it 'generates a schema with the title overwritten' do
                expect(subject['schema']['properties']['foo']).to eq({
                  'title' => 'foo-bar',
                  'description' => '',
                  'type' => 'string'
                })
              end
            end
          end
          context 'description' do
            context 'when description is provided' do
              let(:configuration) { { policy_template_variables: { foo: { description: 'foo-bar' }} }.to_json }
              it 'generates a schema with the description overwritten' do
                expect(subject['schema']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => 'foo-bar',
                  'type' => 'string'
                })
              end
            end
          end
          context 'required' do
            context 'when true' do
              let(:configuration) { { policy_template_variables: { foo: { required: true }} }.to_json }
              it 'generates a schema with the template variable required' do
                expect(subject['schema']['required']).to eq(['branch', 'id', 'foo'])
              end
            end
            context 'when false' do
              let(:configuration) { { policy_template_variables: { foo: { required: false }} }.to_json }
              it 'generates a schema with the template variable required' do
                expect(subject['schema']['required']).to eq(['branch', 'id'])
              end
            end
          end
          context 'default' do
            context 'when default is provided' do
              let(:configuration) { { policy_template_variables: { foo: { default: 'foo-bar' }} }.to_json }
              it 'generates a schema with the default set' do
                expect(subject['schema']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => '',
                  'default' => 'foo-bar',
                  'type' => 'string'
                })
              end
            end
          end
          context 'valid-values' do
            context 'when valid-values are provided' do
              let(:configuration) { { policy_template_variables: { foo: { valid_values: ['foo', 'bar'] }} }.to_json }
              it 'generates a schema with the enum defined' do
                expect(subject['schema']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => '',
                  'enum' => ['foo', 'bar'],
                  'type' => 'string'
                })
              end
            end
          end
          context 'hidden' do
            context 'when hidden is set to true' do
              let(:configuration) { { policy_template_variables: { foo: { hidden: true }} }.to_json }
              it 'generates a schema with readOnly set' do
                expect(subject['schema']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => '',
                  'readOnly' => true,
                  'type' => 'string'
                })
              end
            end
            context 'when hidden is set to false' do
              let(:configuration) { { policy_template_variables: { foo: { hidden: false }} }.to_json }
              it 'generates a schema without readOnly set' do
                expect(subject['schema']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => '',
                  'type' => 'string'
                })
              end
            end
          end
        end
      end
      context 'variables' do
        context 'when variables are not defined' do
          let(:configuration) { {}.to_json }
          it 'does not include variables in the schema' do
            expect(subject['schema']).to eq({
              "$schema" => "http://json-schema.org/draft-06/schema#",
              "description" => "",
              "properties" => {
                "annotations" => {
                  "description" => "Additional annotations",
                  "title" => "Annotations",
                  "type" => "object"
                },
                "branch" => {
                  "description" => "Policy branch to apply this policy to",
                  "title" => "Policy Branch",
                  "type" => "string"
                }, "id" => {
                  "description" => "",
                  "title" => "Resource Identifier",
                  "type" => "string"
                }
              },
              "required" => ["branch", "id"],
              "title" => "Policy Factory",
              "type" => "object"
            })
          end
        end
        context 'when variables are defined' do
          let(:configuration) { { variables: { foo: {} }}.to_json }
          context 'but not required' do
            it "does not include 'variables' as required" do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "annotations" => {
                    "description" => "Additional annotations",
                    "title" => "Annotations",
                    "type" => "object"
                  },
                  "branch" => {
                    "description" => "Policy branch to apply this policy to",
                    "title" => "Policy Branch",
                    "type" => "string"
                  }, "id" => {
                    "description" => "",
                    "title" => "Resource Identifier",
                    "type" => "string"
                  },
                  "variables" => {
                    "properties" => {
                      "foo" => {
                        "description" => "",
                        "title" => "Foo",
                        "type" => "string"
                      }
                    },
                    "required" => [],
                    "type" => "object"
                  },
                },
                "required" => ["branch", "id"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
          context 'when a variable is required' do
            let(:configuration) { { variables: { foo: { required: true } }}.to_json }
            it "includes 'variables' as required" do
              expect(subject['schema']).to eq({
                "$schema" => "http://json-schema.org/draft-06/schema#",
                "description" => "",
                "properties" => {
                  "annotations" => {
                    "description" => "Additional annotations",
                    "title" => "Annotations",
                    "type" => "object"
                  },
                  "branch" => {
                    "description" => "Policy branch to apply this policy to",
                    "title" => "Policy Branch",
                    "type" => "string"
                  }, "id" => {
                    "description" => "",
                    "title" => "Resource Identifier",
                    "type" => "string"
                  },
                  "variables" => {
                    "properties" => {
                      "foo" => {
                        "description" => "",
                        "title" => "Foo",
                        "type" => "string"
                      }
                    },
                    "required" => ["foo"],
                    "type" => "object"
                  },
                },
                "required" => ["branch", "id", "variables"],
                "title" => "Policy Factory",
                "type" => "object"
              })
            end
          end
        end
        context 'variable attributes' do
          context 'when no configuration is provided' do
            let(:configuration) { { variables: { foo: {} } }.to_json }
            it 'the title is a capitalized version of the id' do
              expect(subject['schema']['properties']['variables']['properties']['foo']).to eq({
                'title' => 'Foo',
                'description' => '',
                'type' => 'string'
              })
            end
          end
          context 'title' do
            context 'when title is provided' do
            let(:configuration) { { variables: { foo: { title: 'foo-bar' } } }.to_json }
              it 'generates a schema with the title overwritten' do
                expect(subject['schema']['properties']['variables']['properties']['foo']).to eq({
                  'title' => 'foo-bar',
                  'description' => '',
                  'type' => 'string'
                })
              end
            end
          end
          context 'description' do
            context 'when description is provided' do
            let(:configuration) { { variables: { foo: { description: 'foo-bar' } } }.to_json }
              it 'generates a schema with the description overwritten' do
                expect(subject['schema']['properties']['variables']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => 'foo-bar',
                  'type' => 'string'
                })
              end
            end
          end
          context 'default' do
            context 'when default is provided' do
            let(:configuration) { { variables: { foo: { default: 'bar-baz' } } }.to_json }
              it 'generates a schema with the default set' do
                expect(subject['schema']['properties']['variables']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => '',
                  'default' => 'bar-baz',
                  'type' => 'string'
                })
              end
            end
          end
          context 'valid-values' do
            context 'when valid-values are provided' do
            let(:configuration) { { variables: { foo: { valid_values: ['foo', 'bar'] } } }.to_json }
              it 'generates a schema with the enum defined' do
                expect(subject['schema']['properties']['variables']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => '',
                  'enum' => ['foo', 'bar'],
                  'type' => 'string'
                })
              end
            end
          end
          context 'hidden' do
            context 'when hidden is set to true' do
            let(:configuration) { { variables: { foo: { hidden: true} } }.to_json }
              it 'generates a schema with readOnly set' do
                expect(subject['schema']['properties']['variables']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => '',
                  'readOnly' => true,
                  'type' => 'string'
                })
              end
            end
            context 'when hidden is set to false' do
            let(:configuration) { { variables: { foo: { hidden: false} } }.to_json }
              it 'generates a schema without readOnly set' do
                expect(subject['schema']['properties']['variables']['properties']['foo']).to eq({
                  'title' => 'Foo',
                  'description' => '',
                  'type' => 'string'
                })
              end
            end
          end
        end
      end
      context 'with_variables_group' do
        context 'when variables are present' do
          context 'when it is set to true' do
            let(:configuration) { { with_variables_group: true, variables: { foo: {} }}.to_json }
            it 'includes a variable reference in the policy' do
              test_policy = <<~POLICY
              - !policy
                id: {{ id }}
                annotations:
                {{# annotations }}
                  {{ key }}: {{ value }}
                {{/ annotations }}

                body:
                - &variables
                  - !variable foo

                - !host foo-bar
              POLICY
              expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
            end
            context 'when wrap-with-template is false' do
              let(:configuration) { { wrap_with_policy: false, with_variables_group: true, variables: { foo: {} }}.to_json }
              it 'includes a variable reference but no policy' do
                test_policy = <<~POLICY
                - &variables
                  - !variable foo

                - !host foo-bar
                POLICY
                expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
              end
            end
            context 'when wrap-with-template is true' do
              let(:configuration) { { wrap_with_policy: true, with_variables_group: true, variables: { foo: {} }}.to_json }
              it 'includes a variable reference in the policy' do
                test_policy = <<~POLICY
                - !policy
                  id: {{ id }}
                  annotations:
                  {{# annotations }}
                    {{ key }}: {{ value }}
                  {{/ annotations }}

                  body:
                  - &variables
                    - !variable foo

                  - !host foo-bar
                POLICY
                expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
              end
            end
            context 'when no variables are present' do
              let(:configuration) { { with_variables_group: true }.to_json }
              it 'is ignored' do
                test_policy = <<~POLICY
                - !host foo-bar
                POLICY
                expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
              end
            end
          end
          context 'when it is set to false' do
            context 'when wrap-with-policy is not set' do
              let(:configuration) { { with_variables_group: false, variables: { foo: {} }}.to_json }
              it 'includes a variable reference' do
                test_policy = <<~POLICY
                - !policy
                  id: {{ id }}
                  annotations:
                  {{# annotations }}
                    {{ key }}: {{ value }}
                  {{/ annotations }}

                  body:
                  - !variable foo
                  - !host foo-bar
                POLICY
                expect(decoded_policy_template(subject['policy'])).to eq(test_policy.strip)
              end
            end
          end
        end
      end
    end
  end
end
