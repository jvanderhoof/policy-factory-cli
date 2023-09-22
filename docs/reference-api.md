# Policy Factory API

All Policy Factory API endpoints require authentication and follow the existing Conjur API patterns.

## List

Display all available Factories grouped by factory classification:

```
GET /factories/<account>
```

### Sample Response

```json
{
    "authenticators": [
        {
            "name": "authn_iam",
            "namespace": "authenticators",
            "full-name": "authenticators/authn_iam",
            "current-version": "v1",
            "description": "Create a new Authn-IAM authenticator"
        },
        {
            "name": "authn_jwt_jwks",
            "namespace": "authenticators",
            "full-name": "authenticators/authn_jwt_jwks",
            "current-version": "v1",
            "description": "Create a new Authn-JWT Authenticator using a JWKS endpoint"
        },
        {
            "name": "authn_jwt_public_key",
            "namespace": "authenticators",
            "full-name": "authenticators/authn_jwt_public_key",
            "current-version": "v1",
            "description": "Create a new Authn-JWT Authenticator that validates using a public key"
        },
        {
            "name": "authn_oidc",
            "namespace": "authenticators",
            "full-name": "authenticators/authn_oidc",
            "current-version": "v1",
            "description": "Create a new Authn-OIDC Authenticator"
        }
    ],
    "connections": [
        {
            "name": "database",
            "namespace": "connections",
            "full-name": "connections/database",
            "current-version": "v1",
            "description": "All information for connecting to a database"
        }
    ],
    "core": [
        {
            "name": "grant",
            "namespace": "core",
            "full-name": "core/grant",
            "current-version": "v1",
            "description": "Assigns a Role to another Role"
        },
        {
            "name": "group",
            "namespace": "core",
            "full-name": "core/group",
            "current-version": "v1",
            "description": "Creates a Conjur Group"
        },
        {
            "name": "managed_policy",
            "namespace": "core",
            "full-name": "core/managed_policy",
            "current-version": "v1",
            "description": "Policy with an owner group"
        },
        {
            "name": "policy",
            "namespace": "core",
            "full-name": "core/policy",
            "current-version": "v1",
            "description": "Creates a Conjur Policy"
        },
        {
            "name": "user",
            "namespace": "core",
            "full-name": "core/user",
            "current-version": "v1",
            "description": "Creates a Conjur User"
        }
    ]
}
```

### Response Codes

| Code | Description |
|-|-|
| 200 | Factories returned as a JSON list |
| 401 | The request lacks valid authentication credentials |
| 403 | The authenticated role lacks the necessary privilege |

## View

View the details of a Factory

```
/factories/<account>/<classification/<optional-version>/<factory_id>
```

### Sample Response

```json
{
    "title": "Authn-IAM Template",
    "version": "v1",
    "description": "Create a new Authn-IAM authenticator",
    "properties": {
        "id": {
            "description": "Resource Identifier",
            "type": "string"
        },
        "annotations": {
            "description": "Additional annotations",
            "type": "object"
        }
    },
    "required": [
        "id"
    ]
```

### Response Codes

| Code | Description |
|-|-|
| 200 | Factory details returned as JSON |
| 401 | The request lacks valid authentication credentials |
| 403 | The authenticated role lacks the necessary privilege |
| 404 | The factory does not exist, or it has not been set |


## Create

Create resources using a Factory

```
POST /factory/<account>/<classification>/<optional version>/<factory_id>
```

### Sample Request

```
# POST /factories/demo/connections/database

{
    "id": "myapp-database",
    "branch": "root",
    "variables": {
        "url": "https://foo.bar.baz.com",
        "port": "5432",
        "username": "myapp",
        "password": "supersecretP@ssW0rd"
    }
}
```

### Sample Response

```json
{
    "created_roles": {},
    "version": 1
}
```

| Code | Description |
|-|-|
| 201 | Policy and variables were set successfully |
| 400 | Request body is invalid (missing fields, malformed, etc.) |
| 401 | Policy creation or variable setting not permitted |
| 403 | The authenticated role lacks the necessary privilege to use the factory |
| 404 | The factory does not exist, or it has not been set |
