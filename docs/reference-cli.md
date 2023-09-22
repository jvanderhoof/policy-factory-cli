# CLI

The following CLIs are available in this project:

- `bin/create` - generates factory stubs
- `bin/load` - loads factories

## Create Factory Stubs

### Overview

To create a new Factory, run the following:

```sh
bin/create <factory-name>
```

This will create two stub files in `lib/templates/default/<factory-name>/v1`:

- `config.json` - defines the variables for the factory
- `policy.yml` - defines the Factory's Conjur Policy

Optionally, the factory with a classification and/or a version:

```sh
bin/create \
  --classification authenticators \
  --version 2 \
  <factory-name>
```

The above command will create the factory stub files in the directory: `lib/templates/authenticators/<factory-name>/v2`.

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

## Load Factories

There are four key bits of information required for loading Factories:

| Value | Environment Variable | Comments |
|-|-|-|
| URL | CONJUR_URL | Full URL of the Conjur Leader |
| Account| ACCOUNT | The account the factories should be loaded into |
| Username | CONJUR_USERNAME | Username to use when logging into Conjur |
| API Key | API_KEY | [Optional] API key to use instead of a password |
| Password | | Password for the user. This is collected via the CLI |

*Note: The role used to load factories must have permission to add policy into the `root` namespace.*

### Loading custom Factories

By default, calling `bin/load` loads factories from `lib/templates`.

*Note: This command loads ALL factories present in the `lib/templates`.*

#### With a username/password

This following is an example run against Conjur running via Conjur Intro:

```sh
CONJUR_URL=https://localhost ACCOUNT=demo CONJUR_USERNAME=admin bin/load
```

You'll be prompted for your password prior to performing the load.

#### With an API Key

Alternatively, a user can use a role's API key:

```sh
API_KEY=21mjk4v31pbfr94zpzhbght4v5380zwd02hbjgj4t8geya1wqbhzj CONJUR_URL=https://localhost ACCOUNT=demo CONJUR_USERNAME=admin bin/load
```

When using an API key, you will not be prompted for a password.
