# `rs-repository-utils` — Integration Reference

Source: `https://github.com/taekwondodev/rs-repository-utils` (private, not on crates.io)

Feature flags: `postgres`, `redis`, `health`, `full`.

## Exports

| Export | Feature | Purpose |
|---|---|---|
| `BaseRepository` | `postgres` | Wraps `deadpool-postgres` pool + circuit breaker + observer. Use `execute_with_circuit_breaker` for all DB ops. |
| `BaseRedisRepository` | `redis` | Wraps `redis::ConnectionManager` + circuit breaker + observer. |
| `FromRow` | `postgres` | Trait mapping `tokio_postgres::Row → Result<Self, RepositoryError>`. Implement on domain models. |
| `RepositoryObserver` | always | Trait with `on_db_query` and `on_redis_op`. Implement in `src/utils/observer.rs` as `PrometheusObserver`. |
| `SelectBuilder`, `InsertBuilder`, `UpdateBuilder`, `DeleteBuilder`, `OrderDirection` | `postgres` | Type-safe query builders. Available but not required. |
| `CircuitBreaker`, `CircuitBreakerConfig` | always | Wraps `failsafe`. Constructed once per service, stored in `AppState`. |
| `CircuitBreakerState` | always | `Closed` / `Open`. Via `CircuitBreaker::state()`, `BaseRepository::breaker_state()`, `BaseRedisRepository::breaker_state()`. Use to update Prometheus gauges. |
| `RepositoryError` | always | Lib error type. Bridge via `From<RepositoryError> for AppError` in `src/app/error.rs`. Map `InvalidQuery → BadRequest`, `CircuitBreakerOpen → AppError::CircuitBreakerOpen`, else → `InternalServer`. |
| `ServiceHealth`, `HealthStatus` | `health` | From `check_health()`. Bridge to app's `ServiceHealth` via `From` in `dto/response.rs`. |

## Constructors

Both take `Option<Arc<dyn RepositoryObserver>>` as third arg.

```rust
BaseRepository::new(db, circuit_breaker, prometheus_observer())
BaseRedisRepository::new(conn_manager, circuit_breaker, prometheus_observer())
```

`prometheus_observer()` in `src/utils/observer.rs`, returns `Some(Arc::new(PrometheusObserver))`.

## `execute_with_circuit_breaker` Signatures

Closures get pool/connection **by value** (Arc-backed, O(1) clone):

```rust
// Postgres
base.execute_with_circuit_breaker("op", "table", |db: Pool| async move { ... }).await

// Redis
base.execute_with_circuit_breaker("op", |mut conn: ConnectionManager| async move { ... }).await
```

Never use `&Pool` / `&ConnectionManager` — causes "lifetime may not live long enough" in async closures.

## Transaction Pattern

`execute_transaction` removed. Inline manually:

```rust
let mut client = self.base.pool().get().await?;
let tx = client.transaction().await?;
let result = async {
    // operations using &tx
    Ok::<(), AppError>(())
}.await;
match result {
    Ok(()) => tx.commit().await.map_err(AppError::from),
    Err(e) => { let _ = tx.rollback().await; Err(e) }
}
```

## Observer Pattern

`RepositoryObserver` auto-called by `execute_with_circuit_breaker` after each op. Implement in `src/utils/observer.rs`:

```rust
pub struct PrometheusObserver;

impl RepositoryObserver for PrometheusObserver {
    fn on_db_query(&self, op: &str, table: &str, duration_secs: f64, success: bool) { ... }
    fn on_redis_op(&self, op: &str, duration_secs: f64, success: bool) { ... }
}
```

No macro-based metrics — removed.

## Integration Rules

* Closures return `Result<T, AppError>`. `?` needs `From<PoolError>`, `From<tokio_postgres::Error>`, `From<redis::RedisError>` on `AppError` — don't remove those impls.
* Pool metrics: `base.pool().status()` → `size`/`available`/`max_size` → compute active/idle.
* Circuit breaker for Prometheus: `base.breaker_state()` → `Closed=0`, `Open=1`.

## Checklist

* `rs-repository-utils` missing from `Cargo.toml`? REMIND user. **DO NOT show examples** unless asked.
* Verify `From<RepositoryError> for AppError` in `src/app/error.rs` before wiring repo.
* Always pass `prometheus_observer()` as third arg to `new()`.
