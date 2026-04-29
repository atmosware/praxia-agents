# Praxia Android — Engineering Standards

> Every fix applied by `praxia-android` MUST conform to every standard in this file.
> A change that violates these standards should be flagged as a suggestion instead of applied.

---

## 1. Universal Principles

### SOLID Applied to Android Code

| Principle | Android Rule |
|-----------|-------------|
| **Single Responsibility** | `Activity` / `Fragment` / `Composable` handles UI. `ViewModel` holds UI state and business-layer calls. `Repository` abstracts data sources. `UseCase` encapsulates a single business operation. |
| **Open / Closed** | Add new features via new classes. Extend ViewModel state via new sealed class variants — not by adding boolean flags to the existing state. |
| **Liskov Substitution** | Fake implementations of `Repository` interfaces used in tests must honour the full interface contract. |
| **Interface Segregation** | `ReadUserRepository` and `WriteUserRepository` are better than one `UserRepository` with 15 methods. Retrofit service interfaces should be split by feature domain. |
| **Dependency Inversion** | ViewModels receive repository interfaces via Hilt injection. Repositories receive data source interfaces. Concrete types are bound in Hilt modules. |

### DRY
- Shared UI patterns go in composable functions or custom Views — not duplicated in each screen.
- Shared business rules go in UseCase classes.
- Do not DRY up code that is coincidentally similar but changes independently.

### KISS
- Prefer a simple `when` expression over a factory pattern for simple variant dispatch.
- Prefer `StateFlow` with a sealed state class over multiple `LiveData` / `StateFlow` fields for a single screen's state.
- Avoid custom Coroutine dispatcher factories when `Dispatchers.IO` and `Dispatchers.Main` suffice.

### YAGNI
- Do not add Hilt qualifiers, Coroutine scopes, or extra Repository methods that the current fix does not require.
- Do not add build flavor-specific code unless explicitly requested.

### No Structural Changes Without Explicit Instruction
- Do not rename packages, files, or classes.
- Do not move files between modules.
- Do not change the Gradle module structure.
- Fix in place.

---

## 2. Kotlin Language Standards

### Kotlin Idioms (follow the official Kotlin Coding Conventions)
- Use `val` over `var`. Mutability must be justified.
- Use data classes for POJOs — never write `equals`, `hashCode`, `copy` by hand for data holders.
- Use `sealed class` / `sealed interface` for exhaustive state/result representation.
- Use `object` for singletons — never a class with a private constructor and `companion object getInstance()`.
- Use `apply`, `let`, `run`, `also` for scope functions — but only when they improve readability. Do not chain more than 2 scope functions.
- Extension functions: add to the type's companion file, not scattered across the codebase.
- Avoid `!!` (non-null assertion). Use `?:`, `let {}`, `requireNotNull()`, or `checkNotNull()`.

### Coroutines
- All network and disk operations use `Dispatchers.IO`.
- All UI state updates use `Dispatchers.Main` (via `viewModelScope` which is already Main).
- Use `runTest` in tests, never `runBlocking`.
- Use `async { } + awaitAll()` for parallel operations — never launch two coroutines and hope they finish in order.
- Structured concurrency: every coroutine is launched from a scope (`viewModelScope`, `lifecycleScope`, test scope) — never `GlobalScope`.
- Handle `CancellationException` correctly — never swallow it.

### Null Safety
- Nullable types require explicit handling — never assume a nullable will be non-null at runtime.
- Use `requireNotNull(value) { "message" }` at public API boundaries instead of `!!`.

---

## 3. Architecture Standards (MVVM + Clean Architecture)

### Layer Responsibilities
| Layer | Contains | Does NOT contain |
|-------|---------|-----------------|
| UI (Activity/Fragment/Composable) | Rendering, input collection, navigation | Business logic, direct data access |
| ViewModel | `UiState` StateFlow, user action handlers, lifecycle-aware operations | View references, direct DB/network calls |
| UseCase / Domain | Business rules, orchestration | Android framework imports |
| Repository | Data source abstraction | Business logic, ViewModels |
| Data Source | Network (Retrofit) / local (Room/DataStore) | Business logic |

### ViewModel Standards
- One ViewModel per screen/feature.
- Expose exactly one `UiState` sealed class via `StateFlow<UiState>`.
- Expose one-time events (navigation, toast) via `SharedFlow` or `Channel`.
- Accept all dependencies via constructor injection (Hilt `@HiltViewModel`).

### UI State
```kotlin
sealed class ScreenUiState {
    object Loading : ScreenUiState()
    data class Success(val data: List<Item>) : ScreenUiState()
    data class Error(val message: String) : ScreenUiState()
}
```
- Never expose raw mutable state: use `private val _state = MutableStateFlow<>()` and `val state = _state.asStateFlow()`.

---

## 4. Jetpack Compose Standards

### Composable Design
- Composables should be stateless where possible — accept state and callbacks as parameters.
- State hoisting: lift `remember {}` state to the lowest common ancestor that needs it.
- Use `@Stable` or `@Immutable` on ViewModel state data classes to prevent unnecessary recomposition.
- Use `key(id) { ... }` for items in `LazyColumn` / `LazyRow` to preserve state across reordering.
- Lambda parameters passed to composables should be remembered with `remember { }` or defined outside the composable to avoid recomposition.

### Side Effects
- `LaunchedEffect(key)`: for one-time or key-dependent side effects.
- `rememberCoroutineScope()`: for user-initiated coroutines (button click handlers).
- Never call `suspend` functions directly inside a composable body.

---

## 5. Material Design 3 Standards

- Use `MaterialTheme.colorScheme.*` tokens — never hardcode hex colours.
- Use `MaterialTheme.typography.*` — never hardcode `sp` values.
- Use `MaterialTheme.shapes.*` — never hardcode `dp` corner radii.
- Touch targets must be ≥ 48×48dp.
- Use `Scaffold`, `TopAppBar`, `NavigationBar` from Material 3 library for standard scaffolding.

---

## 6. Room Database Standards

- All `@Dao` methods that write data must be `suspend` functions.
- All `@Dao` methods that return live data must return `Flow<>`.
- Complex queries go in `@Dao` — never build query strings in the Repository.
- Use `@Transaction` for operations that must be atomic.
- Add `@Index` to all columns used in `WHERE` or `JOIN` clauses.

---

## 7. Code Quality Checklist

Before submitting any change:

- [ ] No `!!` (non-null assertion operator)
- [ ] No `GlobalScope.launch`
- [ ] No `runBlocking` in production code
- [ ] No `Thread.sleep()` in tests
- [ ] All coroutines launched from a structured scope
- [ ] `StateFlow` / `LiveData` is private mutable, public read-only
- [ ] No Android framework imports in UseCase or Domain layer
- [ ] No `Log.d` / `Log.v` outputting sensitive data
- [ ] Composable functions are stateless where possible
- [ ] All `@Dao` write methods are `suspend`
