# Hexagonal Architecture

Hexagonal architecture, also called ports and adapters, isolates application and domain behavior from external systems.

## Shape

- The domain or application core owns business rules and ports.
- Inbound adapters translate external input into domain commands or queries.
- Outbound adapters implement ports for databases, networks, queues, and other systems.
- The composition root wires concrete adapters to ports.

## Use When

Use this structure when a real boundary needs independent replacement, testing, or protection from framework and infrastructure details. It is useful when several adapters exist, the domain has meaningful behavior, or external systems change independently.

## Costs

The pattern adds interfaces, mappings, and composition work. Do not use it when the boundary is artificial, the behavior is trivial, or the extra indirection does not protect a real change axis.

## Decision Questions

- What domain rule must remain independent of the adapter?
- Which external systems can vary independently?
- Which port expresses a business capability rather than generic infrastructure?
- Where are wire, persistence, and domain types mapped?
- Which package owns composition?

Hexagonal is a candidate structure, not a universal repository rule. Record the reason when choosing or rejecting it.
