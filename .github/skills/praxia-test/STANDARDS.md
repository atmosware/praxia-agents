# Praxia Test — Engineering Standards

> Every test written by `praxia-test` MUST conform to every standard in this file.
> A test that does not meet these standards must not be written — flag as a stub with TODO markers instead.

---

## 1. F.I.R.S.T. Principles

Every test in every language must satisfy all five properties:

| Property | Requirement |
|----------|------------|
| **Fast** | A unit test completes in < 50ms. A full unit test suite completes in < 30s. Slow tests are integration tests, not unit tests. |
| **Independent** | A test does not depend on the execution of another test. Shared mutable state between tests is a defect. |
| **Repeatable** | A test produces the same result every time, in any environment. No system clock dependency, no random data without seeds, no network calls. |
| **Self-validating** | A test has a clear pass/fail result determined by assertions — not by a human reading log output. |
| **Timely** | Tests are written with (or before) the code they cover, not months later. |

---

## 2. Test Pyramid

Write tests at the correct level. Too many end-to-end tests make suites slow and brittle.

```
        /\
       /  \     E2E / UI Tests: fewest, slowest, cover critical user journeys only
      /────\
     /      \   Integration Tests: moderate number, cover service/API/DB boundaries
    /────────\
   /          \  Unit Tests: most numerous, fast, cover individual functions/classes
  /────────────\
```

- **Unit tests**: test a single class/function in isolation. Mock all dependencies.
- **Integration tests**: test the interaction between components (service + DB, API endpoint + service). Use real implementations where practical (in-memory DB, test containers, MockWebServer).
- **E2E tests**: test complete user journeys through the deployed application. Minimum viable set covering critical paths only.

---

## 3. AAA — Arrange / Act / Assert

Every test follows the three-section structure with a blank line between sections:

```typescript
it('should return 404 when user does not exist', async () => {
  // Arrange
  const userId = 'non-existent-id';
  userRepository.findById.mockResolvedValue(null);

  // Act
  const response = await request(app).get(`/users/${userId}`);

  // Assert
  expect(response.status).toBe(404);
  expect(response.body.error).toBe('USER_NOT_FOUND');
});
```

- **Arrange**: Set up the system under test and its dependencies.
- **Act**: Execute exactly one operation — the thing being tested.
- **Assert**: Verify the expected outcome with targeted, specific assertions.

---

## 4. Test Naming Conventions

### Standard: `should_{expected behaviour}_when_{condition}`

```
should_return_user_when_valid_id_provided
should_throw_not_found_error_when_user_does_not_exist
should_send_welcome_email_when_registration_succeeds
should_reject_with_validation_error_when_email_is_missing
```

Or equivalently: `Given_[context]_When_[action]_Then_[outcome]`

### Rules
- Test names must describe observable behaviour, not implementation.
- Acceptable: `should_return_empty_array_when_no_orders_exist`
- Not acceptable: `test_getOrders`, `works`, `test1`, `it handles the case`

---

## 5. Assertion Standards

### Be Specific
```typescript
// WRONG — only proves no exception was thrown
expect(() => doWork()).not.toThrow();

// CORRECT — proves the specific expected outcome
expect(result).toEqual({ id: 'user-1', name: 'Alice', isActive: true });
expect(emailService.sendWelcome).toHaveBeenCalledWith('alice@example.com');
expect(response.status).toBe(201);
```

### Assert What Matters
- Assert the specific fields relevant to the test scenario, not entire large objects.
- Use `toMatchObject` for partial matching when only some fields matter.
- Use `toHaveBeenCalledWith` (not just `toHaveBeenCalled`) for mock assertions.
- Assert exactly one outcome per test. Multiple assertions are acceptable if they verify aspects of the same outcome.

### Negative Assertions
- Test what does NOT happen: `expect(auditLog.write).not.toHaveBeenCalled()` for an operation that should not trigger auditing.
- Test error paths: `expect(() => fn()).toThrow(ExpectedError)`.

---

## 6. Mocking Standards

### Mock at the Correct Boundary
| Test Type | What to Mock |
|-----------|-------------|
| Unit test | All external dependencies (DB, network, file system, time, random) |
| Integration test | External services only (third-party APIs, email service). Use real DB (in-memory or test container). |
| E2E test | Nothing (or external payment providers / email in staging). |

### Never Mock
- The subject under test itself
- Standard library functions (unless testing time-dependent behaviour)
- Simple data classes / value objects

### Mock Discipline
- Mocks verify interactions, not implementations. Assert that `emailService.send` was called with the correct arguments — not that it called its internal HTTP client.
- Reset mocks between tests. Never share mock state across tests.
- If setting up a mock requires > 10 lines of code, consider whether the production code is too complex.

---

## 7. Test Data Standards

### Fixtures and Factories
- Use factory functions or builder patterns for test data: `buildUser({ isAdmin: true })`.
- Fixtures are minimal: include only the fields the test cares about. Default everything else.
- Do not copy production data into test fixtures. Test data is synthetic.

### Deterministic Data
- Use fixed seeds for random data generators.
- Do not use `Date.now()` or `new Date()` in tests. Inject or mock the clock.
- Use meaningful values: `userId: 'test-user-1'` not `userId: 'abc123xyz'`.

---

## 8. Platform-Specific Standards

### TypeScript / JavaScript (Jest / Vitest)
- Use `jest.useFakeTimers()` for time-dependent tests.
- Use `@testing-library/user-event` over `fireEvent` for React component interaction tests.
- Use MSW (Mock Service Worker) for integration tests that need mocked HTTP at the network layer.
- Snapshot tests: only for intentionally stable, small UI outputs. Regenerate snapshots consciously, not automatically.

### Python (pytest)
- Use `pytest.fixture` with appropriate scope. Default to `function` scope.
- Use `pytest.mark.parametrize` for data-driven tests.
- Use `unittest.mock.patch` or `pytest-mock` for mocking.

### Go
- Table-driven tests for input/output variations.
- Use `t.Parallel()` for independent tests.
- Use interfaces for test doubles — not monkey-patching.

### Swift (XCTest)
- Use `XCTestExpectation` or `async/await` (`@MainActor` test methods) for async tests.
- Never use `sleep()` or `Thread.sleep()` — use expectations with `wait(for:timeout:)`.
- Use `XCTAssertEqual`, `XCTAssertNil`, `XCTAssertThrowsError` — not just `XCTAssert`.
- Inject dependencies via initialiser — never access `UserDefaults.standard` or singletons directly in tests.

### Kotlin / Android (JUnit + MockK)
- Use `runTest` from `kotlinx-coroutines-test` for coroutine tests. Never `runBlocking`.
- Use Turbine for `StateFlow` / `SharedFlow` assertions: `viewModel.state.test { ... }`.
- Use `@HiltAndroidTest` + `@TestInstallIn` to replace production DI bindings.
- Room tests: use `Room.inMemoryDatabaseBuilder` — never a real on-disk database.

---

## 9. Coverage Standards

### Target Coverage Levels
| Layer | Target | Notes |
|-------|--------|-------|
| Domain / Business Logic | ≥ 90% | Critical paths must be 100% |
| Service / Application Layer | ≥ 80% | Happy path + primary error paths |
| API Endpoints | 100% of routes have at least one integration test | Auth, validation, success, not-found |
| UI Components | ≥ 70% | Interaction and state tests; skip pure layout |

Coverage is a floor, not a goal. 100% coverage with no meaningful assertions is worthless.

---

## 10. Test Quality Checklist

Before submitting any test:

- [ ] Test name follows `should_{behaviour}_when_{condition}` convention
- [ ] Follows AAA structure with blank lines between sections
- [ ] Has at least one specific, targeted assertion (not just "does not throw")
- [ ] Tests both the happy path AND at least one error/edge case
- [ ] All dependencies are mocked at the correct boundary
- [ ] No `sleep()` / `Thread.sleep()` / `wait(2)` hardcoded delays
- [ ] No shared mutable state between tests
- [ ] Test data is minimal, deterministic, and meaningful
- [ ] Test is independently runnable (passes when run alone)
- [ ] Test fails when the behaviour it tests is broken (verify by temporarily breaking the code)
