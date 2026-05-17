# `rs-repository-utils` — Integration Reference

Source: `https://github.com/taekwondodev/rs-repository-utils` (private, not on crates.io)

Feature flags: `postgres`, `redis`, `health`, `full`.

## Exports

| Export | Feature | Purpose |
|---|---|---|
| `BaseRepository` | `postgres` | Wraps `deadpool-postgres` pool + circuit breaker. Use `execute_with_circuit_breaker` for all DB ops. |
| `BaseRedisRepository` | `redis` | Wraps `redis::ConnectionManager` + circuit breaker. |
| `FromRow` | `postgres` | Trait for mapping `tokio_postgres::Row → Result<Self, RepositoryError>`. Implement on domain models. |
| `SelectBuilder`, `InsertBuilder`, `UpdateBuilder`, `DeleteBuilder`, `OrderDirection` | `postgres` | Type-safe query builders. |
| `RepositoryMetrics` | `postgres` | Interface-only trait. No impl on `BaseRepository` — implement in the app if needed. |
| `CircuitBreaker`, `CircuitBreakerConfig` | always | Wraps `failsafe`. Constructed once per service, stored in `AppState`. |
| `CircuitBreakerState` | always | `Closed` / `Open`. Exposed via `CircuitBreaker::state()`, `BaseRepository::breaker_state()`, `BaseRedisRepository::breaker_state()`. Use to update Prometheus gauges. |
| `RepositoryError` | always | Library error type. Bridge to `AppError` via `From<RepositoryError> for AppError` in `src/app/error.rs`. Map `InvalidQuery → BadRequest`, `CircuitBreakerOpen → AppError::CircuitBreakerOpen`, everything else → `InternalServer`. |
| `ServiceHealth`, `HealthStatus` | `health` | Returned by `BaseRepository::check_health()` and `BaseRedisRepository::check_health()`. Bridge to the app's own `ServiceHealth` via `From` conversions in `dto/response.rs`. |

## Integration Rules

* `execute_with_circuit_breaker` closures return `Result<T, AppError>`. The `?` operator inside them still needs `From<PoolError>`, `From<tokio_postgres::Error>`, `From<redis::RedisError>` on `AppError` — do not remove those impls.
* Pool metrics: call `base.pool().status()` to get `size`/`available`/`max_size`, compute active/idle, then pass to your metrics function.
* Circuit breaker state for Prometheus: call `base.breaker_state()` and map `Closed → 0`, `Open → 1`.

## Checklist

* If `rs-repository-utils` is missing from `Cargo.toml`, REMIND the user to add it. **DO NOT show examples** unless explicitly asked.
* Verify `From<RepositoryError> for AppError` exists in `src/app/error.rs` before wiring any repository.
