# Factory Policy Reference

Policy Factory `policy.yml` files are processed through Ruby's [ERB templating engine](https://docs.ruby-lang.org/en/3.2/ERB.html).  This allows us to create more dynamic policy.

## Variable Substitution

The following is an example of how to use variables in the `policy.yml` file:

```yml
- !group
  id: <%= id %>
  annotations:
    factory: core/v1/group
```

The tag `<%= my_variable %>` performs string interpolation, writing the value of `my_variable` to the rendered policy file.

## Basic Logic

The tags `<% -%>` allow templates to arbitrarily execute Ruby code within a template. This is helpful for performing simple logic.  For example, to optionally print the owner only if both the owner role and owner type are present:

```yml
- !group
  id: <%= id %>
<% if defined?(owner_role) && defined?(owner_type) -%>
  owner: !<%= owner_type %> <%= owner_role %>
<% end -%>
  annotations:
    factory: core/v1/group
```

*Note: the dash in the closing tag `-%>` means the line will be completely ignored when rendered.  Without the dash, the template will render with a newline after this template is rendered.*

## Looping

Annotations are a special input.  They are a hash (or dictionary for those more familiar with Python). The following is an example of how one would loop through annotations, printing keys and values:

```yml
- !group
  id: <%= id %>
  annotations:
    factory: core/v1/group
<% annotations.each do |key, value| -%>
    <%= key %>: <%= value %>
<% end -%>
```
