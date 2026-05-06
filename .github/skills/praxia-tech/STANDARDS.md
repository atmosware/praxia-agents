# Praxia Tech — Engineering Standards

> Standards are divided into two tiers:
> - **Hard Gate** — a change that violates this must be flagged as a suggestion instead of applied. Covers: safety, security, data loss, buildability, and API compatibility.
> - **Guidance** — apply when reasonable; note the violation in the proposal but do not block the fix. Covers: style preferences, size heuristics, and design patterns.
>
> Items marked `[Guidance]` are heuristics. All unmarked items are Hard Gates.

---

## 1. Universal Principles

These principles apply to all platforms and languages when applying technical debt fixes.

### SOLID
Every change must leave the code more SOLID-compliant than it was:
- **Single Responsibility**: One class/function does one thing and has one reason to change.
- **Open/Closed**: Code is open for extension, closed for modification. Add — don't patch.
- **Liskov Substitution**: Subtypes behave correctly wherever their parent type is used.
- **Interface Segregation**: Small, focused interfaces are better than large ones.
- **Dependency Inversion**: Depend on abstractions, inject concrete implementations.

### DRY
- Eliminate duplication where the duplicated logic has the same reason to change.
- Do not DRY up coincidentally similar code that belongs to different domains.
- `[Guidance]` Extract a shared function/class only when there are ≥ 3 usages that change together.

### KISS
- The simplest correct solution is the best solution.
- Complexity must be justified by a clear problem it solves.
- If a reviewer needs to look up documentation to understand a line, simplify it.

### YAGNI
- Every line of code added must serve a current, confirmed requirement.
- No future-proofing, no speculative generality, no unused extension points.

### No Structural Changes Without Explicit Instruction
- Do not rename or move files.
- Do not change directory structure or module boundaries.
- Do not change architectural patterns (e.g. switch from MVC to MVVM).
- Do not reorganise import paths across the codebase.
- Fix the specific item — no "while I'm here" refactoring.

---

## 2. Naming Standards

### Universal Naming Rules
- Names must communicate intent — avoid abbreviations except universally understood ones (`id`, `url`, `html`, `api`).
- Boolean variables/properties: use `is`, `has`, `can`, `should` prefix: `isLoading`, `hasPermission`.
- Functions/methods: use verb phrases describing the action: `fetchUserById`, `validateEmail`, `calculateTotal`.
- Constants: use `SCREAMING_SNAKE_CASE` (most languages) or `PascalCase` (Swift/Kotlin when idiomatic).
- Collection variables: use plural nouns: `users`, `orderItems`, `eventHandlers`.

### Language-Specific
| Language | Classes | Functions | Variables | Constants |
|----------|---------|-----------|-----------|----------|
| TypeScript/JS | PascalCase | camelCase | camelCase | UPPER_SNAKE or camelCase `const` |
| Python | PascalCase | snake_case | snake_case | UPPER_SNAKE |
| Go | PascalCase (exported) / camelCase (unexported) | same | camelCase | same |
| Swift | PascalCase | camelCase | camelCase | camelCase `let` |
| Kotlin | PascalCase | camelCase | camelCase | UPPER_SNAKE in companion |
| Java | PascalCase | camelCase | camelCase | UPPER_SNAKE |

---

## 3. Function / Method Design

### Size
- `[Guidance]` A function should fit on one screen (max ~40 lines). If it does not, look for extraction opportunities.
- One function, one level of abstraction. Do not mix high-level orchestration with low-level implementation details.

### Parameters
- `[Guidance]` Max 4 parameters. More → introduce a parameter object.
- Avoid boolean flags as parameters: `send(email, true)` → `sendWithAttachment(email)` or use an options object.
- Avoid output parameters. Return values instead.

### Return Values
- Functions return one type of thing. Do not return a value on success and `null` on failure — use a `Result<T, E>` type or throw an exception.
- Pure functions (same input → same output, no side effects) are preferred over impure ones.

---

## 4. Code Complexity Standards

### Cyclomatic Complexity
- `[Guidance]` Target ≤ 10 per function/method. Above 15 is a strong refactor signal — extract sub-functions.
- Deeply nested code (> 3 levels of `if`/`for`/`try`) is a refactor candidate — use early returns and guard clauses.

### Early Returns
```typescript
// Before (arrow-head anti-pattern)
function process(user) {
  if (user) {
    if (user.isActive) {
      if (user.hasPermission) {
        doWork(user);
      }
    }
  }
}

// After (early return / guard clause)
function process(user) {
  if (!user) return;
  if (!user.isActive) return;
  if (!user.hasPermission) return;
  doWork(user);
}
```

---

## 5. Dependency Management

### Dependency Hygiene
- Dependencies must be used. Remove unused packages from the manifest.
- Pin to minimum required version, not latest (`^` is acceptable for minor/patch; avoid `*`).
- Prefer actively maintained packages with clear ownership and a security policy.
- Major version upgrades require a separate, planned change — not done during a tech-debt pass.

### Version Pinning
- `devDependencies` / test dependencies can use `^` (compatible minor versions).
- Production runtime dependencies: pin exact versions in lock files; use `^` in manifest only.

---

## 6. Error Handling

- Errors are explicit. Never swallow them silently.
- Distinguish error types: operational (expected, user-caused) vs programmer (unexpected, bug).
- Only catch errors you can meaningfully handle. Re-throw what you cannot handle.
- Error messages must be actionable: "User not found with id 42" not "Error occurred".

---

## 7. Dead Code

### What to Remove
- Unused imports, variables, function parameters
- Functions and classes with no callers (verified by static analysis, not by assumption)
- Commented-out code blocks (they should be in git history, not the source)
- Unreachable code paths (after unconditional `return`, `throw`, `break`)

### What NOT to Remove Without Investigation
- Code with `// TODO` or `// FIXME` comments — note as a suggestion, do not auto-remove
- Entry points discovered only at runtime (event handlers, plugin hooks) — confirm before removing
- Code that appears unused but may be called via reflection or dynamic dispatch

---

## 8. Code Quality Checklist

Before submitting any change:

- [ ] No unused imports
- [ ] No commented-out code
- [ ] No magic numbers or magic strings — use named constants
- [ ] `[Guidance]` All functions ≤ 40 lines
- [ ] `[Guidance]` Cyclomatic complexity ≤ 10 per function
- [ ] No deeply nested conditionals (> 3 levels)
- [ ] No TODO comments without a ticket reference
- [ ] Error handling is explicit — no silent `catch {}`
- [ ] Naming follows the project's established convention
- [ ] All removed code was confirmed unused (not just visually unlikely)
