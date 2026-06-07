# Rust String Types — Field & Return Type Guide

## Decision Table

| Context | Type | Notes |
|---|---|---|
| Compile-time constant / string literal | `&'static str` | Zero cost. Use for `const`, static messages, client-visible error variants |
| Loaded from `.env` / built once, then immutable | `Box<str>` | No capacity field (3 words → 2 words vs `String`). Use in config structs |
| Function / method parameter | `&str` | Borrow. Never own at boundary |
| Built at runtime, mutated or grown | `String` | Only when mutation needed |
| Shared across threads | `Arc<str>` | Shared ownership without copy |
| Static literal OR runtime-built | `Cow<'static, str>` | `Cow::Borrowed` = zero alloc, `Cow::Owned` = dynamic. Use in response DTOs receiving both |

## `Box<str>` Conversion Patterns

```rust
// from &str
let s: Box<str> = "hello".into();

// from String (env var, format!, DB result)
let s: Box<str> = some_string.into_boxed_str();

// from Option<String> (nullable DB column)
let role: Option<Box<str>> = opt_string.map(String::into_boxed_str);

// DB row (tokio-postgres doesn't deserialize into Box<str> directly)
username: row.try_get::<_, String>("username")?.into_boxed_str(),
role: row.try_get::<_, Option<String>>("role")?.map(String::into_boxed_str),
```

## `Cow<'static, str>` Patterns

```rust
use std::borrow::Cow;

// static (zero alloc)
MessageResponse { message: Cow::Borrowed("Operation completed successfully") }

// dynamic
MessageResponse { message: Cow::Owned(format!("Error: {}", detail)) }

// via Into
let c: Cow<'static, str> = "literal".into();       // → Borrowed
let c: Cow<'static, str> = dynamic_string.into();  // → Owned
```

## `normalize_domain` — Zero-Alloc Transform

Strip prefix with no alloc when unchanged:

```rust
fn normalize_domain(domain: &str) -> Cow<'_, str> {
    match domain.strip_prefix("www.") {
        Some(stripped) => Cow::Borrowed(stripped),
        None => Cow::Borrowed(domain),
    }
}
```

## `AppError` Security Pattern

`&'static str` for client-visible variants: compile-time guarantee no runtime string (DB error, JWT detail) reaches HTTP body:

```rust
pub enum AppError {
    // Logged only — dynamic content OK
    InternalServer(Box<str>),
    ServiceUnavailable(Box<str>),
    CircuitBreakerOpen(Box<str>),

    // Client-visible — only compile-time literals allowed
    NotFound(&'static str),
    AlreadyExists(&'static str),
    Unauthorized(&'static str),

    // Client-visible but validation messages are safe
    BadRequest(Box<str>),
}
```

Sanitize all `From<ExternalError>` impls producing client-visible variants:

```rust
// BAD
impl From<jsonwebtoken::errors::Error> for AppError {
    fn from(e: ...) -> Self { AppError::Unauthorized(e.to_string()) }
}

// GOOD
impl From<jsonwebtoken::errors::Error> for AppError {
    fn from(_: ...) -> Self { AppError::Unauthorized("Invalid token") }
}

// GOOD — sanitize JSON rejection (reveals schema otherwise)
impl From<axum::extract::rejection::JsonRejection> for AppError {
    fn from(_: ...) -> Self { AppError::BadRequest("Malformed request body".into()) }
}
```

## PartialEq with `Box<str>` in Tests

```rust
// Box<str> vs &str — explicit deref required
assert_eq!(&*msg, "expected string");
assert_eq!(msg.as_ref(), "expected string");

// Option<Box<str>> vs Option<&str>
assert_eq!(opt.as_deref(), Some("expected"));

// Box<str> vs Box<str> — works directly
assert_ne!(jti1, jti2);

// method calls via auto-deref — no explicit deref needed
assert!(msg.contains("some substring"));
```

## Struct Field Checklist

When adding string fields, ask:

1. Always compile-time literal? → `&'static str`
2. Loaded once from env/config, never mutated? → `Box<str>`
3. Deserialized (serde/DB), read-only after? → `Box<str>`
4. Receives both static AND dynamic values? → `Cow<'static, str>`
5. Truly mutated after construction? → `String`
6. Shared across threads? → `Arc<str>`
