# Layered Architecture

Layered architecture groups responsibilities by dependency direction, commonly presentation, application, domain, and infrastructure.

## Use When

Use it when the system has clear dependency direction and the layers protect meaningful responsibilities without requiring replaceable ports at every boundary.

## Costs

Layers can become pass-through wrappers or temporal stages. Reject the structure when ownership follows execution order instead of domain knowledge, or when callers must understand several layers to perform one operation.

## Decision Questions

- Does each layer own a distinct rule or boundary?
- Can dependencies point in one clear direction?
- Are mappings and error conversions located at real boundaries?
- Does the structure reduce reader load rather than add ceremony?

Layered architecture is a candidate structure. Compare it with other candidates against the actual system.
