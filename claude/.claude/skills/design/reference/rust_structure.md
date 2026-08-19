# Rust Project Structure: Cargo Workspace / Hexagonal

## Crate Layout

One crate per architectural role. Dependency direction is a hard rule, verified by `cargo build --workspace`. A stray import in the wrong direction is a compile error, not a review comment.

```
crates/domain-shared    shared-kernel identifiers/value objects only (e.g. a UserId newtype).
                        No business rules. Depended on by every domain-<name> crate that needs
                        to reference another context's entity by id.
crates/domain-<name>    one bounded context: entities, ports (traits), the context's Service,
                        its own error enum. Depends on domain-shared only. Zero infra/HTTP deps:
                        no axum, no tokio-postgres, no redis, no framework of any kind.
crates/infra-<tech>     port implementation for one piece of infra (Postgres repo, Redis/JWT
                        service, a payment gateway client, ...). Depends on its one domain-<name>
                        crate and nothing else in the workspace.
crates/http             (or the web framework's name) axum/etc. adapter: generic AppState<R, J, ...>,
                        handlers, wire DTOs, the adapter-local error wrapper. Depends on domain-<name>
                        crates only. It NEVER names an infra-<tech> concrete type. Only the bin
                        crate picks concrete types.
<bin>                   composition root. Depends on everything. The only crate that monomorphizes
                        Service<ConcreteRepo, ConcreteOther> and wires AppState.
```

Rule of thumb: `domain-*` crates depend on nothing infra/HTTP-flavored, ever. `infra-*`/`http` crates depend on their one `domain-*` crate and nothing else in workspace (never on each other). A shared internal library (health checks, observability primitives) is one external exception every layer is allowed to reach for. Bin crate only place allowed to know every concrete type at once.

Second bounded context (payments, notifications, ...) = parallel `crates/domain-<name2>` + own `infra-<tech>` crates, never module added to first context's crate. If needs reference entity from context #1, depends on `domain-shared` for id type, not on `domain-<name1>` wholesale.

## Ports Stay Generic: `dyn Trait` Is the Exception, Not the Default

`AuthService<R: AuthRepository, J: JwtService>` and adapter crate's `AppState<R, J>` are monomorphized generics (or `impl Future<Output = T> + Send` return position for async trait methods). This provides zero-cost static dispatch, resolved entirely at composition root. Don't introduce `Box`/`Arc<dyn Trait>` for "flexibility"; crate boundary already gives swappable adapter at compile time, no runtime indirection needed.

One legitimate exception: genuinely open-ended, heterogeneous set of things to call polymorphically at runtime: health-check indicators across arbitrary dependencies (DB, cache, payment gateway, queue), or observer/hook list. There trait must be written dyn-safe by hand (`fn check(&self) -> Pin<Box<dyn Future<Output = T> + Send + '_>>` instead of `impl Future` in return position, since RPITIT isn't object-safe) and used as `Arc<dyn HealthIndicator>`. Don't reach for `async-trait` unless trait has enough methods that hand-written boilerplate genuinely outweighs a small, well-known dependency. For a one-or-two-method trait, hand-write it.

## Test Layout

Tests in `tests/` subdirectory inside each crate, never inline at file bottom. Keep them per-crate, not centralized. The crate that owns code owns its tests.

```
crates/<name>/src/
├── <module>.rs
├── mod.rs (or lib.rs)        # declares: #[cfg(test)] mod tests;
└── tests/
    ├── mod.rs                 # declares each file as: #[cfg(test)] mod <name>_tests;
    └── <file>_tests.rs
```

## Cargo.toml Wiring

* Root `[workspace]` lists all members; `[workspace.dependencies]` centralizes versions, including `path = "crates/..."` entries for internal crates.
* Feature flags fan out from root, not hardcoded per-crate: `strict = ["domain-auth/strict", "infra-postgres/strict", ...]` declared once at root, each crate re-declares `strict = []` to receive it.
* On shared external dependency with optional features (e.g. `rs-repository-utils`'s `postgres`/`redis`/`health`), enable **only what each crate actually needs**. The `domain-<name>` crate should request the narrowest feature subset (e.g. `health` only), never inherit a blanket feature set across all workspace members. Keeps domain crate infra-agnostic despite technically sharing dependency with infra crates.
* Root package (bin) is simultaneously workspace root and workspace member. This "workspace root that's also a package" layout is normal, not a workaround.
