# Factory Policy Reference

Policy Factory `policy.yml` files are processed through the [Mustache templating library](https://mustache.github.io/mustache.5.html).  This allows us to create more dynamic policy.

## Variable Substitution

The following is an example of how to use variables in the `policy.yml` file:

```yml
- !group
  id: {{ id }}
  annotations:
    factory: core/v1/group
```

The tag `{{ my_variable }}` performs string interpolation, writing the value of `my_variable` to the rendered policy file.

## Basic Logic

Looping and "if" logic can be applied using the list tags: `{{# }}` and `{{/ }}`.

### "If" Logic

Print if the `my_value` is set:

```
{{# my_value }}
  {{ my_value }}
{{/ my_value }}
```

### Render Hash/Dictionary


Hash/Dictionary values are key/value pairs. Conjur Factories offer a small extension to the default Mustache behavior to simplify
rendering hashes like Annotations. When the variable is a hash, its key will be assigned the variable name `key`, and the value
assigned the variable name `value`. This allows us to render a hash with the following:

```
{{# annotations }}
  {{ key }}: {{ value }}
{{/ annotations }}

```
