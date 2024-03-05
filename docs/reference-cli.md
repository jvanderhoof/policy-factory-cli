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

#### With an Auth Token

```sh
auth_token='eyJwcm90ZWN0ZWQiOiJleUpoYkdjaU9pSmpiMjVxZFhJdWIzSm5MM05zYjNOcGJHOHZkaklpTENKcmFXUWlPaUkxT0dRME5qTm1OVE14Wm1Vd056QmtNMlJtT0RNNFlqTmxabU00T0dJM1pURTNNR00xWkdReE5qRmxOMkZsTmpaallqQXlNelptWWpBd1l6TTBZVEprSW4wPSIsInBheWxvYWQiOiJleUp6ZFdJaU9pSmhaRzFwYmlJc0ltVjRjQ0k2TVRjd09UWTJNekF6Tml3aWFXRjBJam94TnpBNU5qWXlOVFUyZlE9PSIsInNpZ25hdHVyZSI6Ik8xZlR3X2tQMTVCNVVhQUJXQ3EyeDJ2UnZmTUNoMEw2Z1I5elVXR2xwUU9jUm42RnNXQi1uZDAzNDEyeWpDM1dPalRBSnNnRXJHa1AzZE90VXZ4MUdjTnI3aFk0YVk3X1BjUXE1Y1Bya05KVmtIdUpCN3VqUFRQdTR2NWgxc2I3X2xVWGwyNGZUZDRYOWZZODRwSnhYbDRjRkNtaVJPUHJhYTVpbm5WUzl0WHBmbWtFUjE2dk10OHdJaFpvMFpCWGZTbXBhM285S0RhQWl2Wjc3U0VSaGxSYmVRZVBRRVBlTmU1bzgzN2NpMWlPYTlFRjF4TG1HYUM1ME5tS2FqOWltTGRzVjdMTHlCUDB4UkJqeGxvM01TQlRJRW45NW1lVnN5SWdwaEcyQm5sbXJUMk42RmFLQWdDcXVmS3JrR3dWbGliejBEcUpxSEVnMzNaR1ZSQ0FtSEpBblhDU1paVGNSXzZ3RHVpdzh6UXgxazBJd1JuN29MMG1zVmx0N2g3eCJ9'
CONJUR_URL=http://localhost:3000 ACCOUNT=cucumber CONJUR_USERNAME=admin CONJUR_AUTH_TOKEN=$auth_token bin/load
```

When using an Auth token, you will not be prompted for a password.
