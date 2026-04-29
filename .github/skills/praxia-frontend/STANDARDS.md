# Praxia Frontend — Engineering Standards

> Every fix applied by `praxia-frontend` MUST conform to every standard in this file.
> A change that violates these standards should be flagged as a suggestion instead of applied.

---

## 1. Universal Principles

### SOLID Applied to Frontend Components

| Principle | Frontend Rule |
|-----------|--------------|
| **Single Responsibility** | A component renders one thing or does one thing. A `UserProfileCard` does not also fetch user data, handle logout, and manage notification preferences. |
| **Open / Closed** | Extend components through props, slots, or composition — not by adding conditionals to existing components for each new use case. |
| **Liskov Substitution** | A `PrimaryButton` must work everywhere a `Button` is used. Components that extend shared base components must not break the base's contract. |
| **Interface Segregation** | Prefer small, specific prop interfaces. A `ListItem` should not accept all 30 props that any of its 10 consumers might theoretically need. |
| **Dependency Inversion** | Components receive data and callbacks as props — they do not reach into global stores or call APIs directly (unless they are a container/page-level component by design). |

### DRY
- Extract shared logic to hooks or composables, not shared global state.
- Shared UI patterns go in the component library. Do not duplicate a `Badge` across 4 feature components.
- Do not DRY up components that are visually similar but evolve independently.

### KISS
- A component with fewer than 50 lines is a good component.
- Prefer conditional rendering (`{show && <X />}`) over complex state machines for simple visibility cases.
- Avoid render-prop patterns and HOCs unless the project already uses them; prefer hooks.

### YAGNI
- Do not add props that no current consumer uses.
- Do not add animation, transitions, or micro-interactions beyond what the fix requires.

### No Structural Changes Without Explicit Instruction
- Do not move components between directories.
- Do not rename component files or exports.
- Do not change the routing structure.
- Do not change the state management topology (e.g. lift state to a new store).

---

## 2. Component Design Standards

### Component Responsibilities
| Type | Responsibility | May Call API? | May Access Global State? |
|------|---------------|--------------|--------------------------|
| UI / Shared | Pure rendering, no business logic | No | No |
| Feature | Domain-specific UI logic | Via custom hook | Read-only via selector |
| Page / Route | Compose features, handle top-level state | Via custom hook | Yes |
| Layout | Structure only | No | No |

### Props Design
- Use TypeScript interfaces (not `type`) for component props.
- Required props carry no default. Optional props carry sensible defaults.
- Never pass entire objects when a component only needs one field: `userId` not `user`.
- Do not use prop spreading (`{...props}`) on DOM elements — it leaks non-DOM attributes and hides the component's interface.

### State Management
- Colocate state as close to where it is used as possible.
- URL state (filters, pagination, selected item) belongs in the URL, not component state.
- Server cache state (data from APIs) belongs in `react-query` / `swr` / equivalent — not in a global Redux/Zustand store.
- Avoid global state for UI state (modals, tooltips, hover) — keep it local.

---

## 3. React Specific Standards

### Hooks
- `useEffect` must have a complete dependency array. Never suppress the exhaustive-deps lint rule without a documented reason.
- Never run a side effect inside `useMemo` or `useCallback`.
- Custom hooks are named `use{Noun}` — `useUserProfile`, `useCartItems`.
- Custom hooks encapsulate one concern. `useForm` handles form state; it does not also submit the form and navigate.

### Memoisation — When to Use
| Use | When |
|-----|------|
| `React.memo` | Component renders frequently with stable props AND the render is expensive (complex DOM tree, calculations) |
| `useMemo` | A calculation is genuinely expensive (sorting, filtering large arrays) AND its inputs are stable |
| `useCallback` | A callback is passed to a memoised child component AND changing it would cause unnecessary re-renders |

Do NOT sprinkle `memo` / `useMemo` / `useCallback` everywhere as a default. Measure first.

### Key Props
- `key` in lists must be stable, unique identifiers — never array index unless the list is static and never reordered.

---

## 4. Accessibility Standards (WCAG 2.1 AA — Minimum)

Every applied change must not decrease accessibility. Every new interactive element must meet these standards:

| Requirement | Standard |
|------------|---------|
| Colour contrast (text) | ≥ 4.5:1 (normal text), ≥ 3:1 (large text ≥ 18pt) |
| Colour contrast (UI components) | ≥ 3:1 |
| Focus indicator | Visible on all interactive elements; never `outline: none` without a replacement |
| Keyboard navigability | All interactive elements reachable and operable via keyboard alone |
| Images | `alt` attribute present; decorative images use `alt=""` |
| Form inputs | Associated `<label>` or `aria-label` on every input |
| Dynamic content | `aria-live` region for content that updates without page reload |
| Error messages | Not conveyed by colour alone; associated with the field via `aria-describedby` |
| Headings | Logical hierarchy (h1 → h2 → h3); no skipped levels |
| Modal / Dialog | Focus trapped inside when open; focus restored to trigger on close |

---

## 5. Performance Standards

### Performance Budget (applies to all applied changes)
- A change must not increase the initial JS bundle by more than 5 KB (gzipped) without justification.
- A change must not add a synchronous operation on the main thread > 50ms.
- Images added or referenced must use optimised formats (WebP/AVIF preferred) with explicit width/height.

### Rendering Performance
- Long lists (> 50 items) MUST use a virtualised list component.
- Components that re-render on every keystroke must not perform expensive synchronous calculations inline — debounce or memoize.
- Avoid layout thrash: do not read layout properties (offsetWidth, getBoundingClientRect) and write DOM properties in the same synchronous block.

---

## 6. CSS Standards

- Use design token variables — never hardcode colour hex, spacing, or font-size values.
- Use the project's established CSS methodology (CSS Modules / BEM / utility-first) — do not mix methodologies.
- Do not add `!important` except to override a third-party library with no alternative.
- Do not use inline styles for anything other than truly dynamic values (e.g. width set from a calculation).

---

## 7. Code Quality Checklist

Before submitting any change:

- [ ] No new TypeScript `any` without justification
- [ ] No commented-out JSX blocks
- [ ] Component renders correctly in empty state, loading state, and error state
- [ ] No event handlers defined inline inside JSX that should be extracted
- [ ] All new props have TypeScript types
- [ ] Accessibility: interactive elements have accessible names
- [ ] No hardcoded colours, spacing, or breakpoints
- [ ] No `console.log` statements left in production code
