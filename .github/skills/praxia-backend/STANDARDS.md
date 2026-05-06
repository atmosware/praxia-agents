# Praxia Backend — Engineering Standards

> Standards are divided into two tiers:
> - **Hard Gate** — a change that violates this must be flagged as a suggestion instead of applied. Covers: safety, security, data loss, buildability, and API compatibility.
> - **Guidance** — apply when reasonable; note the violation in the proposal but do not block the fix. Covers: style preferences, size heuristics, and design patterns.
>
> Items marked `[Guidance]` are heuristics. All unmarked items are Hard Gates.

---

## 1. Universal Principles

### SOLID

| Principle | Rule for Backend Code |
|-----------|----------------------|
| **Single Responsibility** | Each class, service, or module has exactly one reason to change. A `UserService` handles user business logic — not email delivery, not persistence, not HTTP. |
| **Open / Closed** | Extend behaviour through new classes or strategies, not by modifying existing ones. Add a payment provider via a new `PaymentProvider` implementation, not by adding an `if stripe / if paypal` branch. |
| **Liskov Substitution** | Subtypes must be fully substitutable for their base types. An `AdminUser` extending `User` must behave correctly everywhere `User` is accepted. Never narrow pre-conditions or widen post-conditions. |
| **Interface Segregation** | Prefer narrow, focused interfaces over large all-purpose ones. A `ReadableRepository` and `WritableRepository` are better than one `Repository` with 15 methods. |
| **Dependency Inversion** | Depend on abstractions (interfaces, abstract classes), not on concrete implementations. Inject the database client — never instantiate it inside a service. |

### DRY (Don't Repeat Yourself)
- Consolidate logic that changes for the same reason in the same place.
- Do NOT DRY up code that is coincidentally similar but changes independently.
- Two endpoints returning the same fields do not automatically justify a shared response DTO unless the contract is intentionally identical.

### KISS (Keep It Simple)
- Prefer a flat conditional over a chain of design patterns for simple cases.
- The correct abstraction level is the one that makes the next change easiest, not the one that looks most impressive.
- If a reviewer has to think for more than 10 seconds about what a line does, simplify it.

### YAGNI (You Aren't Gonna Need It)
- Do not add parameters, config switches, or extension points that the current fix does not require.
- Do not generalise a fix to handle imaginary future cases.

### No Structural Changes Without Explicit Instruction
- Do not rename files, classes, or modules.
- Do not move code between files or change directory structure.
- Do not introduce a new architectural layer (e.g. add a use-case layer to a service-controller codebase).
- Fix in place. Structural refactoring is a separate, explicitly requested task.

---

## 2. Architecture & Layering

### Clean Architecture Boundaries
When layers are already established, respect them strictly:

| Layer | Allowed Dependencies | Forbidden |
|-------|---------------------|-----------|
| Domain / Core | None (pure business logic) | Framework imports, ORM models, HTTP types |
| Application / Use Cases | Domain only | Framework imports, HTTP types |
| Infrastructure | Domain + Application | Direct business logic |
| Presentation / HTTP | Application layer only | Direct DB calls, business logic |

Never add framework imports to domain logic. Never add business logic to controllers/handlers.

### Repository Pattern
- Services depend on a repository interface, not on a concrete ORM class.
- Repository methods express business intent: `findActiveUsersByTenantId(tenantId)`, not `findAll({ where: { tenantId, status: 'active' } })` called from the service.

---

## 3. REST API Design Standards

### Endpoint Naming
- Use nouns, not verbs: `/users`, `/orders/{id}` — not `/getUser`, `/createOrder`
- Use plural for collections: `/users`, not `/user`
- Nest sub-resources max one level deep: `/orders/{id}/items` — not `/orders/{id}/items/{itemId}/notes/{noteId}`

### HTTP Status Codes
| Scenario | Correct Code |
|---------|-------------|
| Successful read | 200 OK |
| Resource created | 201 Created + `Location` header |
| Accepted async operation | 202 Accepted |
| No content (DELETE success) | 204 No Content |
| Validation error | 422 Unprocessable Entity |
| Authentication required | 401 Unauthorized |
| Forbidden (authenticated but no permission) | 403 Forbidden |
| Not found | 404 Not Found |
| Conflict (duplicate) | 409 Conflict |
| Server error | 500 Internal Server Error |

Never return 200 with an error body. Never return 400 for a missing resource.

### Error Response Shape (consistent across all endpoints)
```json
{
  "error": "VALIDATION_ERROR",
  "message": "Human-readable description",
  "details": [{ "field": "email", "message": "must be a valid email" }]
}
```

### Pagination
All list endpoints MUST support cursor or offset pagination. Never return unbounded arrays.
```json
{
  "data": [...],
  "meta": { "total": 100, "page": 1, "pageSize": 20, "nextCursor": "..." }
}
```

---

## 4. Database Standards

### Query Discipline
- Select only the columns you need — never `SELECT *` in production queries.
- Every query on a table > 10K rows should use an indexed column in `WHERE`.
- N+1 is always a defect. Use eager loading, data loaders, or batched queries.

### Naming Conventions
- Tables: `snake_case`, plural nouns — `user_accounts`, `order_items`
- Columns: `snake_case` — `created_at`, `is_active`, `tenant_id`
- Boolean columns: prefix with `is_`, `has_`, `can_` — `is_verified`, `has_subscription`
- Foreign keys: `{referenced_table_singular}_id` — `user_id`, `order_id`
- Index names: `idx_{table}_{columns}` — `idx_orders_user_id_created_at`

### Migration Standards
- Migrations must be reversible (include `up` and `down`).
- Never drop columns in the same migration that removes their application usage — deprecate first.
- Additive changes (new column with default) are zero-downtime. Destructive changes require a maintenance plan.

---

## 5. Error Handling Standards

- Never silently swallow exceptions. Either handle them or re-throw.
- Distinguish between operational errors (user input, resource not found) and programming errors (null pointer, type error). Only catch operational errors at the boundary.
- Translate infrastructure errors (DB errors, network errors) into domain errors before they reach the HTTP layer.
- Never expose stack traces, internal paths, or DB error messages in API responses.

---

## 6. Logging Standards

- Log at entry and exit of significant operations at `debug` level.
- Log errors with full context (user ID, request ID, input parameters — never passwords or tokens).
- Use structured logging (JSON) — never string interpolation in log messages.
- Wrap high-frequency log calls with a level guard: `if (logger.isDebugEnabled())`.

---

## 7. Code Quality Checklist

Before submitting any change, verify:

- [ ] No new `any` types (TypeScript) or untyped variables without justification
- [ ] No magic numbers or strings — use named constants
- [ ] No commented-out code
- [ ] No TODO comments without a ticket reference
- [ ] Function/method has a single, clear purpose
- [ ] `[Guidance]` No function longer than 40 lines without strong justification
- [ ] `[Guidance]` No deeply nested conditionals (max 3 levels) — use early returns
- [ ] All new branches and error paths are exercised by existing or new tests
- [ ] Public API surface is documented (JSDoc/docstring) if the project convention requires it
