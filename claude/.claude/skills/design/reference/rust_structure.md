# Rust Project Structure

## Project Layout

```
src/
├── main.rs
├── app/
│   ├── mod.rs
│   ├── error.rs              # AppError — single error type returned by the server
│   ├── router.rs             # Route registration
│   ├── server.rs             # Server bootstrap
│   ├── state.rs              # AppState — shared application state
│   └── middleware/
│       ├── mod.rs
│       ├── auth.rs
│       ├── metrics.rs
│       ├── security_audit.rs
│       └── tracing.rs
├── config/
│   ├── mod.rs
│   └── <component>.rs        # One file per config domain (jwt, postgres, circuit breaker…)
├── utils/
│   ├── mod.rs
│   ├── validation.rs         # Input validation helpers
│   ├── health.rs             # Health check endpoint logic
│   └── repository/
│       ├── mod.rs
│       └── …                 # base, metrics, prepared_cache, query_builder
└── <domain>/
    ├── mod.rs
    ├── handler.rs             # HTTP/Input layer
    ├── service.rs             # Business logic layer
    ├── repository.rs          # Data access layer
    ├── queries.rs             # Raw SQL / query definitions
    ├── traits.rs              # Repository and service abstractions
    ├── model.rs               # Domain types
    └── dto/
        ├── mod.rs
        ├── request.rs
        └── response.rs
```

## Test Layout

Tests live in a `tests/` subdirectory at the same level as the module being tested. Never inline at the bottom of a source file.

```
<module>/
├── mod.rs                     # declares: #[cfg(test)] mod tests;
├── <file>.rs
└── tests/
    ├── mod.rs                 # declares each file as: #[cfg(test)] mod <name>_tests;
    └── <file>_tests.rs
```
