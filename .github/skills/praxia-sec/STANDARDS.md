# Praxia Security — Engineering Standards

> Every fix applied by `praxia-sec` MUST conform to every standard in this file.
> A change that closes one vulnerability while introducing another is NOT acceptable.

---

## 1. Core Security Principles

### Secure by Default
- The default configuration must be the most secure configuration.
- Features, endpoints, and permissions are disabled unless explicitly enabled.
- New endpoints are authenticated by default — not public by default.

### Principle of Least Privilege
- Code runs with the minimum permissions required. Database users have only the grants they need.
- API tokens have the narrowest scope that satisfies the use case.
- Admin / privileged functionality is separated from user functionality.

### Defence in Depth
- Do not rely on a single layer of security. Validate input at the boundary AND enforce access control at the service layer AND restrict at the database level.
- A vulnerability in one layer should not be sufficient for a complete breach.

### Fail Secure
- When a security check fails (auth service down, token invalid, permission check error), deny access — do not default to permitting it.
- Error handling must not degrade security posture.

### No Structural Changes Without Explicit Instruction
- Do not refactor code unrelated to the security fix.
- Do not change file/module structure.
- Do not change authentication architecture end-to-end in a single pass — flag as a suggestion with a migration plan.

---

## 2. Input Validation Standards

### Validate at Every Boundary
- All input that crosses a trust boundary (HTTP request, message queue payload, file upload, third-party API response) must be validated before use.
- Whitelist (allowlist) validation is always preferred over blacklist (denylist).

### Parameterised Queries — Non-Negotiable
- String-concatenated SQL/NoSQL queries with user input are never acceptable.
- Use parameterised queries, prepared statements, or ORM methods that prevent injection.

```typescript
// WRONG
const result = await db.query(`SELECT * FROM users WHERE email = '${email}'`);

// CORRECT
const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
```

### Command Injection
- Never pass user-supplied input directly to `exec`, `spawn`, `subprocess`, `eval`, or shell commands.
- Use allowlisted argument arrays, not string interpolation: `spawn('git', ['log', '--oneline'])`.

---

## 3. Authentication Standards

### Password Storage
- Use `bcrypt` (cost ≥ 12) or `argon2id` for password hashing. Never MD5, SHA1, SHA256 alone.
- Never store plaintext passwords. Never store passwords encrypted with symmetric keys.

### JWT Standards
- Algorithm: `RS256` or `ES256` (asymmetric). Never `HS256` with a short secret. Never `none`.
- Claims: `exp` (expiry) is mandatory. `iss` (issuer) and `aud` (audience) must be validated.
- Never put sensitive data in JWT payload — it is base64-encoded, not encrypted.

### Session Standards
- Session cookies: `HttpOnly=true`, `Secure=true`, `SameSite=Strict` (or `Lax` for cross-site OAuth flows).
- Regenerate session ID on privilege elevation (login, role change).
- Invalidate session completely on logout — not just clear the client-side cookie.

### Rate Limiting on Auth Endpoints
Every auth-related endpoint must have rate limiting:
- Login: max 5 attempts per IP per minute
- Password reset request: max 3 per email per hour
- OTP verification: max 3 attempts per session before invalidation

---

## 4. Authorisation Standards

### Object-Level Authorisation
- Every endpoint that accesses a resource by ID must verify the requesting user owns or has permission for that resource.
- Never trust a resource ID from user input without ownership verification.

```typescript
// WRONG — IDOR vulnerability
const order = await ordersRepo.findById(req.params.id);

// CORRECT
const order = await ordersRepo.findByIdAndUserId(req.params.id, req.user.id);
if (!order) throw new NotFoundError();
```

### Function-Level Authorisation
- Every route that requires a role or permission must have middleware that enforces it — not just assumes it.
- Middleware placement: apply guards as close to the route as possible — not only at the application entry point.

---

## 5. Sensitive Data Standards

### Secrets
- No API keys, passwords, tokens, or connection strings in source code.
- No real credentials in `.env.example` or documentation.
- Reference secrets via environment variables; load them at startup.

### Logging
- Never log passwords, tokens, credit card numbers, SSNs, or health data.
- Partially mask sensitive identifiers: `email: "j***@example.com"`, `card: "****1234"`.
- Log the event (authentication failure, access denied) but not the sensitive input that triggered it.

### PII in Responses
- API responses must not include fields the requesting party does not need.
- User profile responses do not include `passwordHash`, internal flags, or other users' data.

---

## 6. Transport Security Standards

- All production traffic uses HTTPS (TLS 1.2 minimum, TLS 1.3 preferred).
- HSTS header: `Strict-Transport-Security: max-age=31536000; includeSubDomains`.
- HTTP requests are redirected to HTTPS — not served in parallel.
- Certificate pinning: required for mobile apps handling financial or health data.

---

## 7. Security Headers (HTTP)

All web-serving backends must emit:

| Header | Recommended Value |
|--------|------------------|
| `Content-Security-Policy` | Restrictive policy; no `unsafe-inline` / `unsafe-eval` without justification |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` |
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` or `SAMEORIGIN` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | Restrict unused browser features |

---

## 8. Mobile-Specific Security Standards

### iOS
- Sensitive data (tokens, credentials, PII): Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- Never `UserDefaults` for sensitive data.
- `NSAllowsArbitraryLoads: false` in ATS. No blanket ATS exceptions.
- `NSLog` / `print` must not output tokens, PII, or sensitive data.

### Android
- Sensitive data: Android Keystore system.
- `SharedPreferences` is not encrypted by default — do not store sensitive data there.
- `android:allowBackup="false"` for apps handling sensitive data.
- `Log.d` / `Log.v` must not output tokens, PII, or sensitive data.
- `android:exported` on components must be explicitly `false` unless inter-app communication is required.

---

## 9. Dependency Security

- Check for known CVEs before accepting a dependency version.
- Enforce `npm audit --audit-level=high` / `safety check` / `govulncheck` in CI.
- Do not pin to a version with a known high/critical CVE without a documented exception.

---

## 10. Security Fix Quality Checklist

Before submitting any security fix:

- [ ] Fix does not introduce a new vulnerability while closing the reported one
- [ ] No user input reaches a SQL/shell/eval call without parameterisation
- [ ] No sensitive data written to logs
- [ ] No hardcoded secrets remaining in source code
- [ ] All new endpoints have auth middleware applied
- [ ] All resource-by-ID lookups verify ownership
- [ ] Security headers are present on HTTP responses
- [ ] Passwords are hashed with bcrypt/argon2 (cost ≥ 12)
- [ ] Session cookies have HttpOnly, Secure, SameSite attributes
- [ ] Fix compiles and does not break existing functionality
