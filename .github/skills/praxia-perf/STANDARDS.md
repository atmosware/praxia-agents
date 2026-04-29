# Praxia Performance — Engineering Standards

> Every fix applied by `praxia-perf` MUST conform to every standard in this file.
> A fix that improves one metric while degrading another must be flagged — not silently applied.

---

## 1. Universal Principles

### Measure Before Optimising
- Never apply a performance fix based on intuition alone.
- Every fix must reference a specific bottleneck identified in the cognia-perf report.
- After applying, state what profiling tool and metric should be used to verify the improvement.

### Optimise the Right Thing First
Priority order (fix bottlenecks in this sequence):
1. **Algorithmic complexity** (O(n²) → O(n log n)) — no infrastructure change delivers this gain
2. **I/O reduction** (eliminate unnecessary DB queries, network calls, disk reads)
3. **I/O parallelism** (serial → parallel calls)
4. **Caching** (cache results, not code paths)
5. **Data transfer reduction** (pagination, projection, compression)
6. **Rendering optimisation** (lazy loading, memoisation, virtualisation)

### No Structural Changes Without Explicit Instruction
- Do not change file/module structure.
- Do not introduce new infrastructure components (Redis, CDN, message queue) in code — flag as suggestion.
- Do not change DB schema (table structure, column types) — flag index additions that require migration as suggestions.
- Fix in place using the project's existing patterns.

### DRY / KISS / YAGNI for Performance Code
- A caching layer should be as simple as possible — do not build a general-purpose cache framework for one use case.
- Performance fixes must be readable. A clever optimisation that another developer cannot understand is a maintenance liability.

---

## 2. Backend Performance Standards

### Database Query Standards
- **N+1 is always a defect.** One HTTP request must not trigger more than one DB roundtrip per relationship level.
- All list queries must have a `LIMIT` clause. No unbounded `SELECT * FROM orders`.
- `SELECT *` is banned in production code. List only the columns you need.
- Indexes: any column used in `WHERE`, `ORDER BY`, or `JOIN ON` on a table > 10K rows needs an index. Composite indexes follow selectivity order (most selective first).
- Query analysis: check the query plan (EXPLAIN ANALYZE) before and after adding an index.

### Caching Standards
- Cache at the correct level: method result (in-process), HTTP response (CDN/proxy), or distributed (Redis/Memcached).
- Every cached value must have a TTL. No eternal caches.
- Cache keys must be deterministic and unique: `users:{userId}:profile`, not `user_data`.
- Cache invalidation strategy must be explicit: time-based, event-based, or version-tagged.
- Do not cache data that changes on every request or that contains per-user security context (unless keyed by user).

### Async / Concurrency Standards
- Sequential awaits on independent operations are a defect. Use `Promise.all`, `asyncio.gather`, `async let`, or equivalent.
- A blocking synchronous call inside an async handler is a defect.
- Connection pools must be sized: pool_size = (core_count × 2) + effective_spindle_count as a starting heuristic.

### Payload Standards
- All list/collection endpoints must be paginated. Default page size: ≤ 50 items.
- Response payloads must not contain fields that no client consumes.
- Enable gzip/brotli compression on all text/JSON responses.

---

## 3. Frontend Performance Standards

### Bundle Size Budget
- Initial JS bundle (gzipped): target < 200 KB for a landing/auth page; < 500 KB for a complex dashboard.
- A single change must not increase the initial bundle by > 5 KB (gzipped) without justification.
- Use `import()` dynamic imports for everything not needed on the initial render.

### Core Web Vitals Targets
| Metric | Good | Needs Improvement | Poor |
|--------|------|------------------|------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | 2.5–4.0s | > 4.0s |
| INP (Interaction to Next Paint) | ≤ 200ms | 200–500ms | > 500ms |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | 0.1–0.25 | > 0.25 |

- LCP: largest above-the-fold asset must be preloaded (`<link rel="preload">`).
- CLS: all images and embeds must have explicit `width` and `height`.
- INP: event handlers must complete within 200ms; defer work with `requestIdleCallback` or `setTimeout(fn, 0)`.

### Rendering Standards
- A re-render must not perform synchronous DOM measurements followed by writes (layout thrash).
- Components that re-render on every keystroke must debounce heavy operations.
- Virtual lists are required for any list that may exceed 50 items.
- Memoisation is applied where re-render cost is confirmed, not speculatively.

---

## 4. iOS Performance Standards

### Main Thread
- Zero synchronous network, disk, or database operations on the main thread.
- Zero `DispatchQueue.main.sync` calls (deadlock risk).
- UI rendering and layout must complete within 16ms per frame (60 FPS target).

### Memory
- Images displayed at less than their native size must be decoded at display size — not at native size.
- Collections displaying cells must use cell reuse (`dequeueReusableCell`).
- All closures capturing `self` in async contexts use `[weak self]`.

### Profiling Tools Reference
| Issue | Tool |
|-------|------|
| CPU hotspots | Instruments → Time Profiler |
| Memory leaks | Instruments → Leaks |
| Main thread blocks | Instruments → Thread Performance Checker |
| Rendering | Instruments → Core Animation |

---

## 5. Android Performance Standards

### Main Thread
- Zero network, disk, or database operations on `Dispatchers.Main`.
- Zero `runBlocking` in production code that executes on the main thread.
- Render frame budget: 16ms (60 FPS). Expensive operations on UI thread = jank.

### RecyclerView
- Always use `DiffUtil` / `ListAdapter` — never `notifyDataSetChanged()`.
- Never perform network calls or image decoding in `onBindViewHolder`.
- Use `setHasFixedSize(true)` when item sizes do not change.

### Compose
- Every ViewModel state class exposed to Compose must be annotated `@Stable` or `@Immutable`.
- Lambda parameters passed to composables must be stable (defined outside composable or wrapped in `remember {}`).
- Use `derivedStateOf` for computed state derived from other state to prevent redundant recomposition.

### Profiling Tools Reference
| Issue | Tool |
|-------|------|
| Startup time | Android Studio → App Startup Profiler |
| Frame drops | Android Studio → Profiler → CPU → System Trace |
| Memory leaks | LeakCanary, Memory Profiler |
| Recomposition | Layout Inspector → Recomposition Counts |

---

## 6. Performance Fix Quality Checklist

Before submitting any performance fix:

- [ ] Fix addresses a specific finding from the cognia-perf report — not a speculative optimisation
- [ ] Fix does not introduce N+1 queries
- [ ] Fix does not introduce synchronous blocking in async contexts
- [ ] Caching fix has a defined TTL and invalidation strategy
- [ ] Lazy loading fix has a defined Suspense/fallback UI
- [ ] No `SELECT *` introduced
- [ ] All list queries are paginated
- [ ] Profiling tool and metric are specified for post-fix verification
- [ ] Fix leaves the codebase in a runnable, buildable state
