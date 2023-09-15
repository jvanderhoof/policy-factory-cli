# frozen_string_literal: true

module Factories
    module Templates
      module Authenticators
        module V1
          class AuthnJwt < Factories::Base
            class << self
              def policy_template
                <<~TEMPLATE
                  - !policy
                    id: <%= id %>
                    annotations:
                      factory: authenticators/v1/authn-jwt
                    <% annotations.each do |key, value| -%>
                      <%= key %>: <%= value %>
                    <% end -%>
  
                    body:
                    - !webservice
  
                    - !variable jwks-uri
                    - !variable public-keys
                    - !variable ca-cert
                    - !variable token-app-property
                    - !variable identity-path
                    - !variable issuer
                    - !variable enforced-claims
                    - !variable mapping-claims
                    - !variable audience
  
                    - !group
                      id: authenticatable
                      annotations:
                        description: Group with permission to authenticate using this authenticator
  
                    - !permit
                      role: !group authenticatable
                      privilege: [ read, authenticate ]
                      resource: !webservice
  
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
                TEMPLATE
              end
  
              def policy_branch
                'conjur/authn-jwt'
              end
  
              def schema
                {
                  "title": "Authn-JWT Template",
                  "description": "Create a new Authn-JWT Authenticator",
                  "type": "object",
                  "properties": {
                    "id": {
                      "description": "Service ID of the Authenticator",
                      "type": "string"
                    },
                    "annotations": {
                      "description": "Additional annotations",
                      "type": "object"
                    },
                    "variables": {
                      "type": "object",
                      "properties": {
                        "jwks-uri": {
                          "description": "The resource for a set of JSON-encoded public keys, one of which corresponds to the key used to digitally sign the JWT. The keys must be encoded as a JWK Set (RFC7517).",
                          "type": "string"
                        },
                        "public-keys": {
                          "description": "When Conjur is unable to reach a remote JWKS URI endpoint, you can use this variable to provide a static JWKS to the JWT Authenticator.",
                          "type": "string"
                        },
                        "ca-cert": {
                          "description": "CA certificate used to verify the JWT signature",
                          "type": "string"
                        },
                        "token-app-property": {
                          "description": "JWT claim used to identify the host identity",
                          "type": "string"
                        },
                        "identity-path": {
                          "description": "The path that exists between host/ and the token-app-property claim value", 
                          "type": "string"
                        },
                        "issuer": {
                          "description": "The expected issuer of the JWT", 
                          "type": "string"
                        },
                        "enforced-claims": {
                          "description": "A list of claims that must be present in the JWT", 
                          "type": "string"
                        },
                        "mapping-claims": {
                          "description": "You can map claim names to more user-friendly aliases in your app ID's host annotations, instead of the actual claim name", 
                          "type": "string"
                        },
                        "audience": {
                          "description": "The expected audience of the JWT", 
                          "type": "string"
                        }
                      },
                      "required": %w[token-app-property issuer]
                    }
                  },
                  "required": %w[id variables]
                }
              end
            end
          end
        end
      end
    end
  end
  