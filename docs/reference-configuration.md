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

  // If all created resources should go into a particular policy branch, define that
  // policy branch here. If users are free to choose the destination policy, leave this
  // blank.
  //
  // Note: if this is blank, the `branch` attribute will be required to create
  // resources with this factory.
  //
  "default_policy_branch": "/conjur/authn-jwt",

  // Policy Type definitions reduce the need to write boilerplate code for common resource
  // creation. Currently, this CLI includes support for `variable-sets` and `authenticator`.
  //
  // When a policy_type is defined and a Factory does not have a `policy.yml` file, the policy
  // template can be defined. There are two types of templates available:
  //
  // 1. 'variable-set' - includes two groups:
  //     - Consumers: have view/execute permission on all variables
  //     - Administrator: have view/execute/update permissions on all variables
  //  2. 'authenticator' - includes:
  //     - Authenticator Webservice
  //     - Status Webservice
  //     - Authenticatable group with read/authenticate permission on the Authenticator Webservice
  //     - Operators group with read permission on the Status webservice
  //
  // Note: If a `policy.yml` file is present, it takes priority over the `policy_type` attribute.
  "policy_type": "<template>",

  // Factories automatically generate an "id" input. If your Factory does not require an ID (ex.
  // if creating a Factory that adds/removes roles or adds/removes permissions), remove the ID
  // with the following:
  //
  // Valid options are `true` and `false`. Defaults to `true`.
  //
  "include_identifier": false,

  // Factories automatically generate inputs for annotations. If your Factory does not
  // require annotations (for example, if creating a Factory that adds/removes roles or
  // adds/removes permissions), remove the annotations with the following:
  //
  // Valid options are `true` and `false`. Defaults to `true`.
  //
  "include_annotations": false

  // This section defines template variables which become available for use in the
  // `policy.yml` file.
  //
  // Mark all required variables with the `required` attribute set to true.
  //
  // Note: Policy Template Variables must be Snake Case (foo_bar).
  "policy_template_variables": {
    "id": {
      "required": true,
      "description": "Group Identifier",
      "default": "foo-bar"
    },
    "owner_role": { "description": "The Conjur Role that will own this group" },
  },

  // This section defines the Conjur Variables that will be created. Mark all required
  // variables with the required attribute set to true.
  //
  // Note: Variable names should be dasherized (foo-bar)
  //
  // Note: Variables are only present if `wrap_with_policy` is set to `true`.
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

### Variable Attributes

In the above configuration, `policy_template_variables` and `variable` sets include the same
set of valid attribute definitions.  They are as follows:

```json
"<variable-identifier>": {
  // Marks the input value as required.
  //
  // Valid options are `true` and `false`. Defaults to `false`.
  "required": true,

  // Short description of the Variable. The description is important as it is used in the UI.
  "description": "description of this variable",

  // Allows a default value to be defined for an input. This default value will be used to
  // populate the UI Factory form field. If a Factory resource is created through the API,
  // the default value will be applied only if the value is empty or missing from the request.
  "default": "default-value-if-empty",

  // Limits inputs to the values listed in the array.
  //
  // Note: values are case sensitive
  "valid_values": ["option-1", "option-2", ...]
}
```
