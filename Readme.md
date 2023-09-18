# Policy Factory Loader

This project aims to simplify the creation and loading of policy factories.  It
includes a small set of Factories to serve as a starting point and as an example.

For a customer engagement, it's strongly suggested you clone this repository and use
a customer specific branch. This will allow you to generate factories to meet customer
specific needs.

## Operations

There are four key bits of information required for loading Factories:

| Value | Environment Variable | Comments |
|-|-|-|
| URL | CONJUR_URL | Full URL of the Conjur Leader |
| Account| ACCOUNT | The account the factories should be loaded into |
| Username | CONJUR_USERNAME | Username to use when logging into Conjur |
| API Key | API_KEY | [Optional] API key to use instead of a password |
| Password | | Password for the user. This is collected via the CLI |

As an example, to load Factories into Conjur Intro, run:

```sh
CONJUR_URL=https://localhost ACCOUNT=demo CONJUR_USERNAME=admin bin/load
```

To load Factories into a local Conjur development environment:

```sh
API_KEY=<api-key> CONJUR_URL=<http://localhost:3000> ACCOUNT=cucumber CONJUR_USERNAME=admin  bin/load
```

### Behind the Scene

#### Organization

This tool looks for Factory files in `lib/templates`. Within the templates folder, folder names matter. They allow factories to be organized and versioned. They have the following convention:

```
<classification>/<version>/<factory>
```

**Classifications** - provides a mechanism for organizing to factories. Create a classification by creating a new folder in the `lib/templates` directory. The classification must be part of the the Factory file as a `module`.

**Version** - enables factories to be versioned. By default, all factories must have
at least one version (`v1`).  Versions must follow the convention `v<integer>` (ex. `v1`, `v2`...`v12`).  The version must be part of the the Factory file as a `module`.

**Factory** - name of the factory you're creating. The file name must be unique and the name should correspond with the Factory Class name. All factories must inherit from `Factories::Base` to ensure the factory loads successfully.

#### Factory Templates

Please review the existing factories in this project for examples. All Factory Templates have two required and one optional class methods:

- `policy_template` - Ruby ERB template of the policy to be applied.
- `policy_branch` - [OPTIONAL] String or ERB template of policy branch for this factory's generated policy. By default, the policy branch will be `<%= branch %>`.
- `schema` - JSON Schema to define this factory's inputs and variables.
