# `rs-repository-utils` — Integration Reference

Source: `https://github.com/taekwondodev/rs-repository-utils` (private, not on crates.io)

Feature flags: `postgres`, `redis`, `health`, `full`. In workspace, enable only what each crate needs — `infra-postgres` crate wants `["postgres", "health"]`, `infra-jwt`/redis crate wants `["redis", "health"]`, `domain-<name>` crate needing nothing from this library just doesn't depend on it.

## Exports

| Export | Feature | Purpose |
|---|---|---|
| `BaseRepository` | `postgres` | Wraps `deadpool-postgres` pool + circuit breaker + observer. `execute_with_circuit_breaker` for all DB ops. |
| `BaseRedisRepository` | `redis` | Wraps `redis::ConnectionManager` + circuit breaker + observer. |
| `FromRow` | `postgres` | Trait mapping `tokio_postgres::Row → Result<Self, RepositoryError>`. Implement on infra crate's shadow row struct, **not** on domain entity directly (see Boundary DTO Rule in `SKILL.md` — domain entity in own crate can't carry this impl anyway once out of crate that owns `tokio-postgres`). |
| `RepositoryObserver` | always | Trait with `on_db_query` and `on_redis_op`. Implement as `PrometheusObserver` wherever constructed (typically each `infra-*` crate, passed into `BaseRepository::new`/`BaseRedisRepository::new`). Cross-cutting like health checks — don't place inside `domain-<name>` crate. |
| `SelectBuilder`, `InsertBuilder`, `UpdateBuilder`, `DeleteBuilder`, `OrderDirection` | `postgres` | Type-safe query builders. Available but not required. |
| `CircuitBreaker`, `CircuitBreakerConfig` | always | Wraps `failsafe`. Constructed once per adapter, owned by whichever `infra-*` crate needs it (or built in composition root and passed in). |
| `CircuitBreakerState` | always | `Closed` / `Open`. Via `CircuitBreaker::state()`, `BaseRepository::breaker_state()`, `BaseRedisRepository::breaker_state()`. To update Prometheus gauges. |
| `RepositoryError` | always | Lib error type. In workspace, infra crate method bodies wrap operations in internal `anyhow::Result`; at public trait-method boundary, downcast to `RepositoryError` to recover specific cases needing specific `DomainError` variant, fall through to `DomainError::Internal` otherwise (see Boundary Conversion Pattern below). |
| `ServiceHealth`, `HealthStatus` | `health` | Result of a single health check. |
| `HealthIndicator` | `health` | Trait: `fn name(&self) -> &'static str; fn check(&self) -> Pin<Box<dyn Future<Output = ServiceHealth> + Send + '_>>`. Implement directly on infra adapter type (`Repository`, `Jwt`, ...) alongside its real port impl — don't add `check_*` method to domain-facing repository/service trait itself. |
| `HealthReport`, `check_all` | `health` | `check_all(&[Arc<dyn HealthIndicator>]) -> HealthReport` runs every indicator concurrently (`tokio::task::JoinSet`, needs `rt` feature on `tokio`) and aggregates by `name()`. No timestamp on `HealthReport` by design — presentation concern for whichever layer turns it into HTTP response, not something this library needs time-formatting dependency for. |

## Constructors

Both take `Option<Arc<dyn RepositoryObserver>>` as third arg.

```rust
BaseRepository::new(db, circuit_breaker, prometheus_observer())
BaseRedisRepository::new(conn_manager, circuit_breaker, prometheus_observer())
```

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
    Ok::<(), anyhow::Error>(())
}.await;
match result {
    Ok(()) => tx.commit().await.map_err(Into::into),
    Err(e) => { let _ = tx.rollback().await; Err(e) }
}
```

## Observer Pattern

`RepositoryObserver` auto-called by `execute_with_circuit_breaker` after each op:

```rust
pub struct PrometheusObserver;

impl RepositoryObserver for PrometheusObserver {
    fn on_db_query(&self, op: &str, table: &str, duration_secs: f64, success: bool) { ... }
    fn on_redis_op(&self, op: &str, duration_secs: f64, success: bool) { ... }
}
```

No macro-based metrics — removed.

## Boundary Conversion Pattern (Workspace)

Infra crate method bodies use inner `anyhow::Result` so every underlying error auto-converts via anyhow's blanket `From`, then exactly one classification function per crate handles boundary:

```rust
fn classify_repo_error(e: anyhow::Error) -> DomainError {
    match e.downcast::<RepositoryError>() {
        Ok(RepositoryError::CircuitBreakerOpen(msg)) => DomainError::ServiceUnavailable(msg.to_string()),
        Ok(RepositoryError::InvalidQuery(_)) => DomainError::BadRequest("Invalid query parameters".into()),
        Ok(other) => DomainError::Internal(anyhow::anyhow!(other)),
        Err(e) => DomainError::Internal(e),
    }
}
```

Called once via `.map_err(classify_repo_error)` per public trait method — not per `?` call site inside method body.

## Integration Rules

* Pool metrics: `base.pool().status()` → `size`/`available`/`max_size` → compute active/idle.
* Circuit breaker for Prometheus: `base.breaker_state()` → `Closed=0`, `Open=1`.
* `HealthIndicator::check()` is where pool-stats/circuit-breaker-gauge updates happen too (same body that used to sit on `check_db`/`check_redis` port method) — moving health-check out of domain port doesn't mean losing that instrumentation, just relocating into `HealthIndicator` impl.

## Checklist

* `rs-repository-utils` missing from `Cargo.toml`? REMIND user. **DO NOT show examples** unless asked.
* Verify boundary classification function exists in infra crate before wiring repo/service into it.
* Always pass `prometheus_observer()` as third arg to `new()`.
* Health-checkable adapter added? Confirm it `impl HealthIndicator` and pushed into composition root's indicator list — don't let default onto domain port method.
