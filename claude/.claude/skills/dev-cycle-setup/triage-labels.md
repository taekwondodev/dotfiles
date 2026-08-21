# Issue Labels

The workflow speaks in terms of canonical category, state, and workflow-marker roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

### Category labels

`bug` and `enhancement` are fixed category labels in this workflow. They are not part of the configurable triage-state mapping.

### Triage state labels

| Canonical role    | Label in this tracker |
| ------------------ | ---------------------- |
| `needs-triage`      | `needs-triage`          |
| `needs-info`        | `needs-info`            |
| `ready-for-agent`   | `ready-for-agent`       |
| `ready-for-human`   | `ready-for-human`       |
| `wontfix`           | `wontfix`               |

### Workflow markers

| Canonical marker | Label in this tracker |
| ---------------- | ---------------------- |
| `needs-grilling` | `needs-grilling`       |

`needs-grilling` marks a quick issue that is intentionally waiting for a future grilling session. It may coexist with one category label and one triage state label; it is not itself a triage state.

When a skill mentions a role or marker, use the corresponding label string from this table. Edit the right-hand column if this repo's tracker already uses different names. Don't create duplicate labels for the same role.
