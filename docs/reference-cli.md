# CLI

The following CLIs are available in this project:

- `bin/create` - generates factory stubs
- `bin/inspect` - generates and displays the JSON Schema and Policy template.
- `bin/load` - loads factories

## Create Factory Stubs

### Overview

To create a new Factory, run the following:

```sh
bin/create <factory-name>
```

This will create two stub files in `factories/custom/<factory-name>/v1`:

- `config.json` - defines the variables for the factory
- `policy.yml` - defines the Factory's Conjur Policy

Optionally, the factory with a classification and/or a version:

```sh
bin/create \
  --classification authenticators \
  --version 2 \
  <factory-name>
```

The above command will create the factory stub files in the directory: `lib/custom/authenticators/<factory-name>/v2`.

### Create Reference

View all options via the help flag:

```sh
bin/create --help

A tool that generates Policy Factory starting templates.

Synopsis: bin/create [command options] <factory-name>

Usage: bin/create [options] <factory-name>:

    -c, --classification <name> Classification for a factory.  By default, the classification will be 'default'

    -h, --help                  Shows this help message.

    -v, --version <version>     Version for a factory. By default, the version will be 'v1'.
```

## Inspecting Factories

Before loading a new Factory it's helpful to view the JSON Schema and Policy template
that will be pushed to Conjur. The following command allows you to inspect any Factory:

```
bin/inspect <path-to-factory>
```

As an example, let's look at the `default/core/host/v1` Factory:

```sh
bin/inspect factories/default/core/host/v1
```

It results in the following:

```sh
Factory Schema:
{
  "version": "v1",
  "policy": "LSAhaG9zdAogIGlkOiA8JT0gaWQgJT4KPCUgaWYgZGVmaW5lZD8ob3duZXJfcm9sZSkgJiYgZGVmaW5lZD8ob3duZXJfdHlwZSkgLSU+CiAgb3duZXI6ICE8JT0gb3duZXJfdHlwZSAlPiA8JT0gb3duZXJfcm9sZSAlPgo8JSBlbmQgLSU+CjwlIGlmIGRlZmluZWQ/KGlwX3JhbmdlKSAtJT4KICByZXN0cmljdGVkX3RvOiA8JT0gaXBfcmFuZ2UgJT4KPCUgZW5kIC0lPgogIGFubm90YXRpb25zOgo8JSBhbm5vdGF0aW9ucy5lYWNoIGRvIHxrZXksIHZhbHVlfCAtJT4KICAgIDwlPSBrZXkgJT46IDwlPSB2YWx1ZSAlPgo8JSBlbmQgLSU+Cg==",
  "policy_branch": "{{ branch }}",
  "schema": {
    "$schema": "http://json-schema.org/draft-06/schema#",
    "title": "Host Template",
    "description": "Creates a Conjur Host",
    "type": "object",
    "properties": {
      "id": {
        "description": "Resource Identifier",
        "type": "string"
      },
      "annotations": {
        "description": "Additional annotations",
        "type": "object"
      },
      "branch": {
        "description": "Policy branch to apply this policy to",
        "type": "string"
      },
      "owner_role": {
        "description": "The role identifier that will own this host",
        "type": "string"
      },
      "owner_type": {
        "description": "The resource type of the owner of this host",
        "type": "string"
      },
      "ip_range": {
        "description": "Limits the network range the host is allowed to authenticate from",
        "type": "string"
      }
    },
    "required": [
      "branch",
      "id"
    ]
  }
}

Factory Policy:
- !host
  id: {{ id }}
{{# owner_role }}
  {{# owner_type }}
  owner: !{{ owner_type }} {{ owner_role }}
  {{/ owner_type }}
{{/ owner_role }}
{{# ip_range }}
  restricted_to: {{ ip_range }}
{{/ ip_range }}
  annotations:
    factory: core/v1/host
  {{# annotations}}
    {{ key }}: {{ value }}
  {{/ annotations}}
```

This is verbose, but gives some detail into the JSON Schema (used by Conjur's
implementation of Policy Factories).

### Inspect Reference

View all options with the help flag:

```sh
bin/inspect --help

A tool that shows the JSON Schema and corresponding Policy generated and loaded into Conjur.

Synopsis: bin/inspect [command options] <factory-path>

Usage: bin/inspect [options] <factory-path>:

    -h, --help                  Shows this help message.
```

## Loading Factories

There are a few key bits of information required to load Factories:

| Value | Environment Variable | Comments |
|-|-|-|
| URL | CONJUR_URL | Full URL of the Conjur Leader |
| Account| ACCOUNT | The account the factories should be loaded into |
| Username | CONJUR_USERNAME | Username to use when logging into Conjur |
| API Key | API_KEY | [Optional] API key to use instead of a password |
| Password | | Password for the user. This is collected via the CLI if the API key is not present |
| Auth Token | CONJUR_AUTH_TOKEN | [Optional] Authenticate using a previously generated Conjur Auth Token. This takes precedence over the API key or password. Auth Token should be used with Conjur SaaS. |
| Target Policy | TARGET_POLICY | [Optional] The policy to load Factories into. By default, this is `conjur/factories`. This setting is required for Conjur SaaS, and must match the defined Conjur SaaS Policy Factory configuration. |

*Note: The role used to load factories must have permission to add policy into the `root` namespace.*


### Flags

| Flag | Comments |
|-|-|
| `--all <default or custom>` | Loads all the locally available Factories |
| `--insecure` | Skips the TLS check during the policy apply |

### Loading a specific Factory

```sh
CONJUR_URL=https://<conjur-url> ACCOUNT=<account> CONJUR_USERNAME=<role> bin/load default/core/v1/host

```


### Loading default Factories

This CLI comes with a set of Policy Factories. These are intended to speed up the
development of new Factories and provide a solid set of Factories for customers
to use.

To load default Factories:

```sh
CONJUR_URL=https://<conjur-url> ACCOUNT=<account> CONJUR_USERNAME=<role> bin/load --all default
```

### Loading custom Factories

To load custom Factories:

```sh
bin/load --all custom
```

#### With a username/password

This following is an example run against Conjur running via Conjur Intro:

```sh
CONJUR_URL=https://localhost ACCOUNT=demo CONJUR_USERNAME=admin bin/load --all custom
```

You'll be prompted for your password prior to performing the load.

#### With an API Key

Alternatively, a user can use a role's API key:

```sh
API_KEY=21mjk4v31pbfr94zpzhbght4v5380zwd02hbjgj4t8geya1wqbhzj CONJUR_URL=https://localhost ACCOUNT=demo CONJUR_USERNAME=admin bin/load --all custom
```

When using an API key, you will not be prompted for a password.

#### With an Auth Token

```sh
auth_token='eyJwcm90ZWN0ZWQiOiJleUpoYkdjaU9pSmpiMjVxZFhJdWIzSm5MM05zYjNOcGJHOHZkaklpTENKcmFXUWlPaUkxT0dRME5qTm1OVE14Wm1Vd056QmtNMlJtT0RNNFlqTmxabU00T0dJM1pURTNNR00xWkdReE5qRmxOMkZsTmpaallqQXlNelptWWpBd1l6TTBZVEprSW4wPSIsInBheWxvYWQiOiJleUp6ZFdJaU9pSmhaRzFwYmlJc0ltVjRjQ0k2TVRjd09UWTJNekF6Tml3aWFXRjBJam94TnpBNU5qWXlOVFUyZlE9PSIsInNpZ25hdHVyZSI6Ik8xZlR3X2tQMTVCNVVhQUJXQ3EyeDJ2UnZmTUNoMEw2Z1I5elVXR2xwUU9jUm42RnNXQi1uZDAzNDEyeWpDM1dPalRBSnNnRXJHa1AzZE90VXZ4MUdjTnI3aFk0YVk3X1BjUXE1Y1Bya05KVmtIdUpCN3VqUFRQdTR2NWgxc2I3X2xVWGwyNGZUZDRYOWZZODRwSnhYbDRjRkNtaVJPUHJhYTVpbm5WUzl0WHBmbWtFUjE2dk10OHdJaFpvMFpCWGZTbXBhM285S0RhQWl2Wjc3U0VSaGxSYmVRZVBRRVBlTmU1bzgzN2NpMWlPYTlFRjF4TG1HYUM1ME5tS2FqOWltTGRzVjdMTHlCUDB4UkJqeGxvM01TQlRJRW45NW1lVnN5SWdwaEcyQm5sbXJUMk42RmFLQWdDcXVmS3JrR3dWbGliejBEcUpxSEVnMzNaR1ZSQ0FtSEpBblhDU1paVGNSXzZ3RHVpdzh6UXgxazBJd1JuN29MMG1zVmx0N2g3eCJ9'
CONJUR_URL=http://localhost:3000 ACCOUNT=cucumber CONJUR_USERNAME=admin CONJUR_AUTH_TOKEN=$auth_token bin/load --all custom
```

When using an Auth token, you will not be prompted for a password.
