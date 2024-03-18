# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Nothing should go in this section, please add to the latest unreleased version
  (and update the corresponding date), or add a new version.

## [1.0.0] - 2024-03-05
### Added
  - Ability to load Factories using a Conjur Auth Token using the `CONJUR_AUTH_TOKEN`
    environment variable
  - Ability to define the target Policy branch using `TARGET_POLICY` environment
    variable.
  - Factory DSL Changes:
    - Support for variable-set and authenticator boilerplate policy.
    - Support for dropping the Factory resource identifier (for non-resource Factories).
    - Support for dropping the Factory annotations (for non-resource Factories).
    - Support for setting default values.
    - Support for defining permitted values.
  - Additional Default Factories:
    - Core: Delete, Deny, Grant, Layer, Permit, Revoke, and Webservice
    - Authenticators: Authn-Azure, Authn-GCP

## [0.3.0] - 2024-01-18
### Added
- Core Factories: Host, User, Policy, Group, and User.

## [0.2.0] - 2024-01-18
### Added
- Adds preliminary support for variables.

## [0.1.0] - 2023-09-22
### Added
- Simplified policy and configuration system for generating factories with:
  - CLI for load factories.
  - CLI for generating factory stubs.
  - Documentation
