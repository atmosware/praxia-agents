# Praxia UX — Engineering Standards

> Every fix applied by `praxia-ux` MUST conform to every standard in this file.
> Track A changes (direct code fixes) must meet these standards before being applied.
> Track B specifications must reference these standards in their acceptance criteria.

---

## 1. Universal Principles

### No Structural Changes Without Explicit Instruction
- Do not reorganise page/component file structure.
- Do not change routing structure or navigation hierarchy.
- Do not change the design system's token architecture.
- Apply targeted fixes — do not redesign while fixing.

### Usability Heuristics (Nielsen's 10)
Every applied fix must not violate these heuristics:

| Heuristic | What to check |
|-----------|-------------|
| **Visibility of system status** | Loading states, progress indicators, success/error feedback present |
| **Match between system and real world** | Labels use user's language, not technical jargon |
| **User control and freedom** | Undo/cancel available for destructive actions |
| **Consistency and standards** | Same action always looks and behaves the same way |
| **Error prevention** | Confirmation for destructive actions; validation before submission |
| **Recognition over recall** | Options are visible; users don't have to remember information |
| **Flexibility and efficiency** | Keyboard shortcuts and power-user paths available |
| **Aesthetic and minimalist design** | No irrelevant or redundant information |
| **Help recognise, diagnose, and recover from errors** | Error messages are plain-language, specific, and constructive |
| **Help and documentation** | Complex tasks have contextual help |

---

## 2. Accessibility Standards — WCAG 2.1 AA (Minimum)

These are hard requirements for every Track A change. Do not apply a fix that introduces a WCAG violation.

### Colour Contrast
| Context | Minimum Ratio |
|---------|--------------|
| Normal text (< 18pt / < 14pt bold) | 4.5:1 |
| Large text (≥ 18pt / ≥ 14pt bold) | 3:1 |
| UI components and graphical objects | 3:1 |

Verify at [webaim.org/resources/contrastchecker](https://webaim.org/resources/contrastchecker/).

### Keyboard Navigation (WCAG 2.1.1, 2.1.2)
- All interactive elements reachable via `Tab` key.
- All interactive elements operable via `Enter` / `Space`.
- No keyboard trap except in modals (which must be dismissible via `Escape`).
- Logical tab order matches the visual reading order.

### Focus Indicators (WCAG 2.4.7, 2.4.11)
- All focusable elements have a visible focus ring.
- Never use `outline: none` or `outline: 0` without providing a custom focus indicator that meets 3:1 contrast.
- `:focus-visible` is the correct pseudo-class for keyboard-only focus rings.

### Semantic HTML
- Use semantic elements: `<button>` for buttons, `<a>` for links, `<nav>` for navigation, `<main>` for main content.
- Heading hierarchy must be logical (no skipped levels: h1 → h2 → h3).
- Lists of items use `<ul>` / `<ol>` / `<li>` — not `<div>` stacks.

### Images (WCAG 1.1.1)
- All informational images: `alt="descriptive text"`.
- Decorative images: `alt=""` (empty string — screen readers skip).
- Never `alt="image"` or `alt="logo.png"`.

### Forms (WCAG 1.3.1, 3.3.1, 3.3.2)
- Every input has an associated `<label>` (via `for`/`id` or `aria-labelledby`).
- `placeholder` text is NOT a label substitute.
- Error messages associated with inputs via `aria-describedby`.
- Required fields indicated via `required` attribute AND visible label indicator.
- `autocomplete` attributes set for standard fields (name, email, password, tel, address-line1).

### Dynamic Content (WCAG 4.1.3)
- Content that updates without a page reload: use `aria-live="polite"` for non-critical updates, `aria-live="assertive"` only for critical alerts.
- Status messages (success, error, toast) must be announced by screen readers.

### Modals & Dialogs (WCAG 2.1.2)
- Focus is trapped inside the modal while open.
- `Escape` key dismisses the modal.
- Focus returns to the trigger element when the modal closes.
- Modal root has `role="dialog"` and `aria-labelledby` pointing to the modal title.

---

## 3. Copy & Microcopy Standards

### Labels
- Labels describe the field's content, not its format: "Email address" not "Enter your email address here".
- Button labels describe the action outcome: "Save changes", "Delete account" — not "Submit", "OK", "Yes".
- Avoid "Click here" — describe what happens: "View your invoice" not "Click here to view invoice".

### Error Messages
Must answer three questions:
1. **What went wrong**: "Your password is too short" not "Invalid input".
2. **Why it went wrong**: "Passwords must be at least 8 characters" not "Password requirements not met".
3. **How to fix it**: "Add more characters and try again" — or just the above two are sufficient for simple cases.

### Empty States
Every empty state must include:
- What is empty: "No orders yet"
- Why it's empty (if not obvious)
- What the user can do: "Place your first order" with a CTA button

### Loading States
- Show a loading indicator for any operation > 300ms.
- Use skeleton screens for content that has a known layout.
- Never show a blank screen without a loading indicator.

---

## 4. Interaction & Motion Standards

### Affordances
- Buttons look like buttons. Links look like links. Do not style them the same.
- Clickable / tappable elements have a cursor change or hover state.
- Disabled elements have reduced opacity (≥ 40%) AND are excluded from tab order (`disabled` attribute or `aria-disabled`).

### Feedback Timing
| Action | Feedback within |
|--------|----------------|
| Button click (any action) | 100ms — visual response (loading state) |
| Form submission | 300ms — loading indicator |
| Toast / success message | Visible for 4–6 seconds |
| Error message | Persistent until resolved (not auto-dismissing) |

### Motion & Animation
- Respect `prefers-reduced-motion` media query — skip or minimize animations when set.
- Avoid motion that covers more than a third of the viewport.
- Animation duration: micro-interactions 100–200ms; page transitions 200–400ms; never > 500ms.

---

## 5. Responsive Design Standards

| Breakpoint | Width | Required behaviour |
|-----------|-------|-------------------|
| Mobile | < 768px | Single-column layout; touch targets ≥ 44px |
| Tablet | 768–1024px | Two-column where appropriate; touch or pointer |
| Desktop | ≥ 1024px | Full layout; hover states expected |

- Content must not overflow its container at any breakpoint.
- Scrollable containers must have visible scroll indicators or be accompanied by navigation controls.
- No horizontal scrolling at mobile breakpoint (except intentional scroll areas like carousels).

---

## 6. Track A Change Checklist

Before applying any Track A (code) UX fix:

- [ ] Fix does not introduce a WCAG contrast violation
- [ ] All interactive elements remain keyboard-accessible
- [ ] Focus management is correct (trapped in modals, restored on close)
- [ ] All new images have `alt` attributes
- [ ] Error messages are specific and constructive
- [ ] Empty states have content and a CTA
- [ ] No `outline: none` without a replacement focus indicator
- [ ] `aria-live` or `role="status"` present for dynamically updated content
- [ ] Touch targets ≥ 44×44 CSS pixels (mobile) or ≥ 44×44 pt (iOS)
- [ ] Motion respects `prefers-reduced-motion`
