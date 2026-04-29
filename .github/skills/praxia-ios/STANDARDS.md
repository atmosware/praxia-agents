# Praxia iOS — Engineering Standards

> Every fix applied by `praxia-ios` MUST conform to every standard in this file.
> A change that violates these standards should be flagged as a suggestion instead of applied.

---

## 1. Universal Principles

### SOLID Applied to iOS Code

| Principle | iOS Rule |
|-----------|---------|
| **Single Responsibility** | A `ViewController` / `View` presents UI. A `ViewModel` holds UI state and exposes actions. A `Service` performs business operations. A `Repository` accesses data. Never mix. |
| **Open / Closed** | Use protocols to extend behaviour. Add a new `AuthProvider` implementation — do not add an `if apple / if google` chain to the existing one. |
| **Liskov Substitution** | A mock `UserRepository` used in tests must behave identically to the real one from the protocol's perspective. Never narrow the protocol contract in a mock. |
| **Interface Segregation** | Define narrow protocols: `UserReadable`, `UserWritable` are better than one `UserRepository` protocol with 12 methods that every conformer must implement. |
| **Dependency Inversion** | ViewModels depend on protocol-typed repositories. Coordinators depend on protocol-typed navigation interfaces. Concrete types are injected at the composition root. |

### DRY
- Extract shared view logic into reusable `ViewModifiers` or custom `View` components.
- Shared business logic goes in services, not duplicated across ViewModels.
- Do not DRY up view code that looks similar but represents different domain concepts.

### KISS
- Prefer `if let` / `guard let` over custom error-handling infrastructure for simple optional unwrapping.
- Prefer `async/await` over completion handlers for new code.
- Avoid reactive chains longer than 5 operators without intermediate named variables.

### YAGNI
- Do not add protocol conformances that no current consumer requires.
- Do not add generic type parameters that the current fix does not need.

### No Structural Changes Without Explicit Instruction
- Do not rename files, classes, or protocols.
- Do not move types between files or change the folder structure.
- Do not introduce a new architectural layer (e.g. add a Coordinator where none exists).
- Fix in place.

---

## 2. Swift Language Standards

### Swift API Design Guidelines (Apple)
- **Clarity at the point of use**: `users.remove(at: index)` not `users.removeAtIndex(index)`.
- **Omit needless words**: `users.first` not `users.firstUser`.
- Names are camelCase for types/properties/methods (`UserProfile`, `fetchUserData`).
- Boolean properties and methods read as assertions: `isEmpty`, `canProceed`, `isVisible`.
- Factory methods begin with `make`: `makeDefaultSession()`.
- Methods with side effects use imperative verbs: `sort()`, `append()`. Pure methods use noun phrases: `sorted()`, `appending()`.

### Value Types vs Reference Types
- **Prefer `struct`** for data models, view state, and value objects.
- Use `class` only for identity semantics, when inheritance is required, or for `ObservableObject`.
- Use `final class` when a class is not designed for inheritance.

### Memory Management
- **Closures must capture `self` weakly** when `self` outlives the closure's execution and is not guaranteed to outlive the closure: `{ [weak self] in self?.doSomething() }`.
- **Delegate properties must be `weak`**: `weak var delegate: SomeDelegate?`.
- **Notification observers must be removed in `deinit`** or by storing the observation token.
- Never use `unowned` unless you can prove the reference cannot become nil while the closure exists.

### Optionals
- Never force-unwrap (`!`) in production code. Use `guard let`, `if let`, or `??`.
- Avoid `try!` in production code. Handle errors explicitly.
- Implicitly unwrapped optionals (`var thing: Type!`) are only acceptable for `@IBOutlet` and properties set before first use in `viewDidLoad`.

---

## 3. Architecture Standards (MVVM)

### Layer Responsibilities
| Layer | Contains | Does NOT contain |
|-------|---------|-----------------|
| View (SwiftUI View / UIViewController) | Layout, presentation, user input dispatch | Business logic, network calls, data transformation |
| ViewModel | UI state (`@Published`), user actions, input validation | UIKit/SwiftUI imports, direct data access |
| Service / Use Case | Business rules, orchestration | UI state, persistence details |
| Repository | Data access (network + local) | Business logic, UI concerns |

### ViewModel Standards
- All `@Published` properties are named to describe UI state: `isLoading`, `errorMessage`, `users`.
- ViewModels do not import `SwiftUI` or `UIKit`.
- ViewModels accept all dependencies via initialiser injection.
- Async operations use `Task { }` inside the ViewModel; the Task is cancelled in `deinit` if appropriate.

### Navigation
- Navigation decisions belong to the Coordinator (if used) or to the View layer — never inside a ViewModel.
- ViewModels emit navigation events as output signals/callbacks, not navigation calls.

---

## 4. Concurrency Standards (Swift Concurrency)

- **Prefer `async/await`** over GCD for new code.
- UI updates must occur on `@MainActor`. Mark ViewModels and View-touching methods with `@MainActor`.
- Do not call `DispatchQueue.main.sync` — it risks deadlocks. Use `await MainActor.run { }`.
- Background work goes on `Task { }` or `Task.detached { }` with explicit `Dispatchers` where needed.
- Cancel Tasks when the owning ViewController/ViewModel is deallocated.

---

## 5. Core Data Standards

- Fetch requests must set `fetchBatchSize` (typically 20–50) on all fetch requests for large datasets.
- Perform Core Data operations on the appropriate context (background context for writes, view context for reads on main thread).
- Use `NSFetchedResultsController` for table/collection views displaying Core Data content.
- Never perform heavyweight migrations synchronously on the main thread.

---

## 6. Apple HIG Compliance

- Touch targets must be ≥ 44×44 pt.
- Use standard system controls before building custom ones.
- Support Dynamic Type — use `Font.body`, `Font.headline` etc.; never hardcode font sizes.
- Support Dark Mode — use semantic colours (`Color(.systemBackground)`, `Color(.label)`) not hardcoded hex values.
- Destructive actions require confirmation (alert / action sheet).

---

## 7. Code Quality Checklist

Before submitting any change:

- [ ] No force-unwrap (`!`) in production code
- [ ] No `try!` in production code
- [ ] All closures that capture `self` use `[weak self]` where appropriate
- [ ] All delegate references are `weak`
- [ ] All `@Published` properties are meaningful names describing UI state
- [ ] No UIKit/SwiftUI imports in ViewModel or lower layers
- [ ] No business logic in View layer
- [ ] Async operations use `async/await` where the project convention allows
- [ ] No `print()` statements in production code (use `os_log` / `Logger`)
