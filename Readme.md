# Policy Factory Loader

This project aims to simplify the creation and loading of policy factories.

## Operations

There are four key bits of information required for loading data:

| Value | Environment Variable | Comments |
|-|-|-|
| URL | CONJUR_URL | Full URL of the Conjur Leader |
| Account| ACCOUNT | The account the factories should be loaded into |
| Username | CONJUR_USERNAME | Username to use when logging into Conjur |
| Password | | Password for the user. This is collected via the CLI |

As an example, to load Factories into Conjur Intro, run:

```sh
CONJUR_URL=https://localhost ACCOUNT=demo CONJUR_USERNAME=admin bin/load
```

### Behind the Scene

#### Organization

This tool looks for Factory files in `lib/templates`. Within the templates folder, folder names matter. They allow factories to be organized and versioned. They have the following convention:

```
<classification>/<version>/<factory>
```

#### Factory Templates

Please review the existing factories in this project for examples. All Factory Templates have two required and one optional class methods:

- `policy_template` - Ruby ERB template of the policy to be applied.
- `policy_branch` - [OPTIONAL] String or ERB template of policy branch for this factory's generated policy. By default, the policy branch will be `<%= branch %>`.
- `schema` - JSON Schema to define this factory's inputs and variables.
