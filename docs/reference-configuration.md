# Reference

## Configuration File

The following is a full set of valid configuration elements:

```json
{
  // Defines a Factory's Title. This is displayed in the UI.
  "title": "Group Template",

  // Description for this Factory. This is displayed in the UI.
  "description": "Creates a Conjur Group",

  // By default, the policy defined in the `policy.yml` file is wrapped in
  // a parent policy. This wrapping simplifies the factory construction. If
  // your factory policy does not require wrapping (ex. to create Conjur primatives
  // like a host or a user), set this to false.
  //
  // Valid options are `true` and `false`. Defaults to `true`.
  //
  // Note: Setting `wrap_with_policy` to false ignores the variables block below.
  //
  "wrap_with_policy": false,

  // If all created resources should go into a particular policy, define that policy
  // here. If users are free to choose the destination policy, leave this blank.
  //
  // Note: if this is blank, the `branch` attribute will be required to create
  // resources with this factory.
  //
  "default_policy_branch": "/conjur/authn-jwt",

  // This section defines template variables which become available for use in the
  // `policy.yml` file. Mark all required variables with the required attribute set
  // to true.
  //
  // Note: Policy Template Variables must be Snake Case (foo_bar).
  //
  "policy_template_variables": {
    "id": {
      "required": true,
      "description": "Group Identifier"
    },
    "owner_role": { "description": "The Conjur Role that will own this group" },
  },

  // This section defines the Conjur Variables that will be created. Mark all required
  // variables with the required attribute set to true.
  //
  // Note: Variable names should be dasherized (foo-bar)
  //
  // Note: Variables are only present if `wrap_with_policy` is set to `true`.
  //
  "variables": {
    "url": {
      "required": true,
      "description": "API URL"
    },
    "api-key": {
      "required": true,
      "description": "API authentication key"
    }
  }
}
```
