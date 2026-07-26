# SQL Query Externalization

## Rule

`queries.rs` holds only `pub const` declarations. SQL body lives in sibling `sql/` dir, loaded via `include_str!`.

## Why

Editor SQL syntax highlighting. No Rust-string indentation artifacts. Query text diffable on its own.

## Layout

```
crates/infra-<tech>/src/
├── queries.rs
└── sql/
    ├── <submodule>_<query_name>.sql
    └── ...
```

Queries live in the `infra-*` crate, not the `domain-*` crate — SQL is an infra concern by definition.

Flat. No subfolders — file count per domain stays small (single digits to low tens); nesting adds path noise for no gain at that scale.

## Naming

`{submodule}_{query_name}.sql`, lowercase snake_case, one file per `pub const`. Prefix by submodule to avoid collisions (e.g. two submodules both defining `INSERT`).

## File content

- Reformat to plain left-aligned SQL — no leading indentation carried over from Rust literal.
- Trailing `;` on every file (harmless to Postgres, keeps file valid as standalone statement for linters/`psql \i`).

## queries.rs wiring

```rust
pub mod users {
    pub const UPSERT: &str = include_str!("sql/users_upsert.sql");
}
```

`include_str!` path resolves relative to `queries.rs`'s own directory (same rule as `mod`). Call sites elsewhere (`repo.rs` etc.) don't change — same `pub const &str` type and name, only initializer changes.

## Scope

Applies to raw-SQL repositories (`tokio-postgres`, `deadpool-postgres`). If using `sqlx`, prefer native `query_file!`/`query_file_as!` macros over rolling `include_str!` by hand — same one-file-per-query convention, less wiring.
