# Vision

This document is an attempt to capture how we can break customer outcomes into cohesive, reusable Policy Factories to create the necessary primitives in Conjur.


**Note**:
*As the process of applying policy to Conjur often requires applying the policy to a specific policy, I believe this document will additionally outline the requirements of "Factory of Factories", or the ability the chain and combine the set of policy changes required to achieve the higher-level outcome.*


## Assumptions

- Applications run in Kubernetes.
- Each application has multiple environments (ex. Backstage, Staging, Integration, Production) that it moves through for testing, reviewing, and verifying.
- A single development team is responsible for building and maintaining an application.
- An operations team is responsible for provisioning and maintaining Kubernetes as well as creating Namespaces.
- An application runs in a Namespace.
- Each application environment has a single policy branch where all credentials needed by that application is stored.
- Each application environment runs in a separate Kubernetes cluster.
- The Operations team is responsible for provisioning application support services (databases, etc.).
- The service provisioning process includes loading credentials into a vault (Conjur or PAM/PCloud).

## Goal

Provide a seamless, secure, and automated provisioning and deployment experience for releasing work.

## Lifecycles

### Initial Deployment

Initial deployment covers the initial setup (provisioning the environments, support services, and initial deployment). Following the initial setup, a new application is running in production.

### Ongoing Operations

Ongoing operations covers the release of new features and functionality of the application, as well as maintenance of hardware end platform environment.

### Decommissioning

Decommissioning covers the process of removing the application from usage. Following decommission, the application is no longer available to anyone.

## Blueprint

### Initial Deployment

#### Outcomes

- A Kubernetes cluster is provisioned for each environment (backstage, staging, integration, production).
  - Each cluster will be registered with Conjur (as an authenticator).
- A PAM/PCloud Safe will be created for each application environment.
  - Data from a Safe will be synced to Conjur at the path `/vault/data/<app-name>-<environment>`
- A Kubernetes namespace will be created for the application.
  - Each namespace will be registered with Conjur (as a host).
  - All Safe data is available to the application in the form of environment variables
- An application is deployed into Kubernetes Namespace via a deployment manifest.

#### Conjur

To achieve the above outcomes, we'll need to perform the following activities in Conjur:

1. Set up the necessary policy to support authenticators.
2. Create an authenticator for each Kubernetes cluster.
3. Create an application for each environment.
4. Create a Conjur host for each application environment namespace.
5. Create the policy (structure to mimic that created by the Vault Synchronizer) to store credentials for that application environment.
6. Grant the Conjur host permission to the corresponding Safe.

##### Sample Policy

1. Setup
    ```
    # Applied to /root

    - !policy
      id: conjur
      body:
      - !policy
        id: authn-jwt
      - !policy
        id: authn-azure
      - !policy
        id: authn-iam
      - !policy
        id: authn-gcp
      - !policy
        id: authn-oidc
      # Note: I'm intentionally leaving ldap and k8s off this list

    - !group auditor

    # Vault Setup
    - !group vault-admin
    - !policy
      id: vault
      owner: !group vault-admin
      body:
      - !policy
        id: data

    # Application Setup
    - !policy
      id: applications
    ```
2. Onboard a new Kubernetes cluster(s)
    For this example, we're creating four new clusters (one for each environment). As an example, let's assume the following correlation:

    - `cluster-1` - Backstage
    - `cluster-2` - Staging
    - `cluster-3` - Integration
    - `cluster-4` - Production

    The following is an example of a potential authenticator:

    ```
    # Applied to `/conjur/authn-jwt`
    - !policy
      id: cluster-1
      annotations:
        region: us-east-1
        environment: backstage
      body:
        - !webservice

        - !variable jwks-uri
        - !variable ca-cert
        - !variable token-app-property
        - !variable identity-path
        - !variable issuer
        - !variable enforced-claims
        - !variable mapping-claims
        - !variable audience

        - !group
          id: authenticatable

        - !permit
          role: !group authenticatable
          privilege: [ read, authenticate ]
          resource: !webservice

        - !webservice
          id: status

        - !group
          id: operators

        - !permit
          role: !group operators
          privilege: [ read ]
          resource: !webservice status
    ```
3. Create Application environments

    ```
    # Applied to `/applications`

    - !policy
      id: <my-application>
      body:
      - !policy
        id: backstage
        body:
        - !group
          id: application
      - !policy
        id: staging
        body:
        - !group
          id: application
      - !policy
        id: integration
        body:
        - !group
          id: application
      - !policy
        id: production
        body:
        - !group
          id: application
    ```

4. Create Host and allow it to use the appropriate authenticator
    ```
    # Applied to `/applications/<my-application>/backstage

    - !host
      id: cluster1
      annotations:
        authn-jwt/backstage/namespace-id: <namespace>

    - !grant
      member: !host cluster1
      role: !group application
    ```

    Grant authentication permission:

    ```
    # Applied to /conjur/authn-jwt/cluster-1
    - !grant
      member !host /applications/<my-application>/backstage/cluster1
      role: !group authenticatable
    ```

5. Vault Synchronizer Safe

    This is the bones of a Safe, based off the Policy Factory work done by Ben.

    ```
    # Applied to `/vault/data`

    - !group safe-owner
    - !policy
      id: application1-backstage
      owner: !group safe-owner
      body:
      - !policy
        id: delegation
        body:
        - !group consumers
        - !group viewers

        - !grant
          member: !group consumers
          role: !group viewers
    ```

    Example of Account

    ```
    # Applied to /vault/data/<safe-name>`

    - !policy
      id: <account-identifier>
      body:
      - &variables
        - !variable username
        - !variable password

    - !permit
      role: delegation/consumers
      privileges: [ execute ]
      resource: *variables

    - !permit
      role: delegation/viewers
      privileges: [ view ]
      resource: *variables
    ```

6. Grant application permission to safe

    ```
    # Applied to `/vault/data/application1-backstage/delegation
    - !grant
      member: !group /applications/application1/backstage/application
      role: !group consumers
    ```



### Ongoing Operations

#### Outcomes

- New services are added to the application
  - Data added to an application environment safe is available when the application is deployed (assumes the application is deployed after data is added to the safe).

### Decommissioning

#### Outcomes

- Kubernetes cluster is removed
  - Related Conjur resources are removed (host, policy, authenticator, etc.).
  - PAM/PCloud safe is no longer synchronized.
