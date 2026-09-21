# Next.js / React Code Review Rules

These rules extend the common code review rules for Next.js and React projects.

Focus on correctness, rendering behavior, server/client boundaries, performance, security, accessibility, maintainability, and production reliability.

---

## 1. Server Components vs Client Components

Check for:

- unnecessary `"use client"`
- Client Components placed too high in the component tree
- Server-only modules imported into Client Components
- browser-only APIs used in Server Components
- server-only APIs used in Client Components
- incorrect sharing of modules between server and client boundaries
- accidental client bundle expansion
- sensitive server-side logic exposed to the browser

Pay special attention to errors such as:

`This module cannot be imported from a Client Component module. It should only be used from a Server Component.`

Verify whether the module boundary is correct before reporting the issue.

Prefer Server Components by default unless client-side interactivity is required.

---

## 2. Rendering Strategy

Check whether the implementation correctly uses:

- SSR
- SSG
- ISR
- CSR
- streaming
- client-side fetching

Check for:

- unnecessary CSR where server rendering would be more appropriate
- server rendering used for highly interactive data without clear benefit
- duplicate data fetching between server and client
- incorrect assumptions about when code runs
- unnecessary hydration
- page content flashing because of avoidable client-side fetches

Do not recommend SSR or CSR blindly.

Evaluate the actual requirements of the page.

---

## 3. Hydration

Check for hydration mismatch risks such as:

- using Date or time values differently on server and client
- random values during render
- accessing window during render
- accessing localStorage during initial server render
- browser-dependent formatting
- inconsistent conditional rendering
- invalid HTML nesting
- client state differing from server-rendered content

Examples of risky patterns include:

- Math.random() during render
- new Date() producing different output between server and client
- checking window directly in render logic

When reporting hydration issues, explain the actual mismatch risk.

---

## 4. React Hooks

Check for:

- incorrect dependency arrays
- missing dependencies
- unnecessary dependencies
- effects causing infinite loops
- stale closures
- duplicated state
- unnecessary useEffect
- state updates after unmount
- async side effects without cleanup
- subscriptions not cleaned up
- timers not cleaned up

Check whether a useEffect is actually necessary.

Prefer deriving values directly when possible instead of storing duplicated derived state.

Do not report exhaustive-deps-style issues without checking the intended behavior.

---

## 5. State Management

Check for:

- duplicated state
- state stored too high in the component tree
- state stored too low causing duplication
- unnecessary global state
- inconsistent sources of truth
- derived values stored as independent state
- race conditions between async state updates
- stale data
- excessive prop drilling where it meaningfully harms maintainability

For Zustand, Redux, Context, or similar solutions, check whether global state is actually justified.

Do not recommend adding a state management library unless the complexity requires it.

---

## 6. Data Fetching

Check for:

- duplicate requests
- waterfall requests
- unnecessary client-side requests
- missing error handling
- missing loading states
- missing cancellation when applicable
- incorrect cache usage
- stale data
- inconsistent server/client data
- unbounded retries
- request loops
- race conditions

For Next.js fetch behavior, inspect:

- cache configuration
- revalidation behavior
- dynamic vs static rendering implications

For SWR or React Query, inspect:

- cache key correctness
- stale data behavior
- revalidation
- retry behavior
- dependent queries
- mutation consistency

Do not report duplicate fetching without verifying the actual request path.

---

## 7. Next.js Caching

Check for:

- incorrect cache assumptions
- stale content
- missing revalidation
- inappropriate `no-store`
- inappropriate aggressive caching
- cache behavior inconsistent with business requirements
- user-specific data accidentally cached globally
- authentication-sensitive data being reused incorrectly

Pay special attention to personalized or sensitive data.

User-specific responses must not be accidentally shared between users.

---

## 8. Route Handlers and Server Actions

Check for:

- missing authentication
- missing authorization
- missing input validation
- trusting client-provided identifiers
- sensitive information returned to the client
- unsafe database access
- missing error handling
- inconsistent response contracts
- side effects without idempotency when appropriate

For Server Actions, verify:

- authorization is checked server-side
- client input is treated as untrusted
- secrets remain server-side
- revalidation is handled correctly when data changes

Do not assume that hiding a control in the UI provides authorization.

---

## 9. Security

Check for:

- XSS
- unsafe dangerouslySetInnerHTML
- unsanitized HTML
- client-side exposure of secrets
- insecure environment variables
- authorization implemented only in the frontend
- sensitive API responses
- unsafe redirects
- open redirect risks
- insecure cookies
- token leakage
- storing sensitive tokens in localStorage when inappropriate
- CSRF concerns where applicable

For environment variables:

Only variables intentionally exposed to the browser should use client-visible prefixes.

Never expose server secrets through client bundles.

---

## 10. dangerouslySetInnerHTML

If dangerouslySetInnerHTML is used, check:

- where the HTML comes from
- whether the content is trusted
- whether sanitization exists
- whether user-controlled data can reach it
- whether JSON-LD or structured data is being rendered safely

Do not automatically report all uses as vulnerabilities.

For structured data such as JSON-LD, ensure the implementation cannot be used to inject arbitrary executable markup.

---

## 11. Forms and Input Validation

Check for:

- missing validation
- client-only validation without server validation
- incorrect form state
- race conditions on submit
- duplicate submissions
- missing disabled/loading state
- error messages not displayed
- unsafe assumptions about client input
- incorrect number/date parsing

Business-critical operations should guard against repeated submissions when duplicate requests could cause side effects.

---

## 12. Navigation and Routing

Check for:

- incorrect use of router
- unnecessary full-page reloads
- broken navigation
- invalid dynamic route assumptions
- incorrect route params
- missing not-found handling
- missing error boundaries
- incorrect redirect behavior
- redirect loops
- client navigation exposing restricted pages

Do not treat client-side route guards as sufficient authorization.

---

## 13. Error Handling

Check for:

- missing error boundaries
- swallowed errors
- generic errors without useful context
- raw internal errors shown to users
- unhandled promise rejections
- errors causing blank pages
- network failures not handled
- missing fallback UI

Check whether errors are handled at the appropriate layer.

---

## 14. Loading States

Check for:

- missing loading feedback
- duplicate loading indicators
- layout shifts
- indefinite loading states
- requests that can remain unresolved
- loading states that block unrelated content

In App Router projects, inspect whether loading UI and streaming behavior are appropriate.

---

## 15. Performance

Check for:

- unnecessary client components
- unnecessary re-renders
- large client bundles
- importing heavy libraries into client code
- expensive calculations during render
- repeated calculations without need
- excessive DOM rendering
- rendering very large lists without pagination or virtualization
- duplicate network calls
- inefficient image handling
- unnecessary JavaScript shipped to the browser

Do not recommend memoization everywhere.

Only suggest memoization when there is a realistic performance benefit.

---

## 16. React Rendering

Check for:

- unstable keys
- using array index as key when items can reorder
- unnecessary component remounting
- mutations of props or state
- state updates during render
- conditional hooks
- components with excessive responsibilities
- expensive child trees re-rendering unnecessarily

Do not report index keys when the list is static and cannot reorder unless there is a real risk.

---

## 17. Images

For Next.js Image or standard images, check:

- incorrect sizing
- layout shift risk
- loading oversized assets
- missing responsive sizing
- inappropriate priority usage
- unnecessary high-resolution images
- broken remote image configuration
- missing meaningful alt text

Do not require alt text for purely decorative images if they are correctly marked as decorative.

---

## 18. Accessibility

Check for:

- interactive divs instead of semantic buttons or links
- missing labels
- inaccessible form controls
- missing keyboard access
- incorrect tab behavior
- inaccessible modals
- missing focus management
- inaccessible dropdowns
- missing meaningful alternative text
- color being the only state indicator
- improper heading structure

Focus on meaningful accessibility problems.

Do not create excessive low-value accessibility findings.

---

## 19. SEO and Metadata

When applicable, check:

- missing or incorrect metadata
- duplicate page titles
- incorrect canonical URLs
- missing structured data
- malformed JSON-LD
- incorrect Open Graph data
- client-only rendering of critical SEO content
- robots configuration
- sitemap implications

Only apply SEO concerns to pages where SEO is relevant.

Do not report SEO issues for internal authenticated applications unless there is a real requirement.

---

## 20. Environment Configuration

Check for:

- secrets exposed to the browser
- hard-coded URLs
- environment-specific assumptions
- missing configuration validation
- production behavior differing unexpectedly from development
- unsafe fallback values

Pay attention to:

- API base URLs
- authentication endpoints
- analytics keys
- feature flags
- CDN paths

Public identifiers are not automatically secrets.

---

## 21. Authentication and Authorization

Check for:

- authentication enforced only in client components
- authorization checks missing on server-side APIs
- user-controlled IDs used without ownership validation
- restricted data returned before authorization is verified
- tokens exposed in URLs
- sensitive information stored insecurely
- inconsistent session handling

A hidden button does not provide authorization.

Authorization must be enforced on the server.

---

## 22. API Calls

Check for:

- calling private/internal services directly from the browser when inappropriate
- leaking credentials
- incorrect headers
- missing timeout behavior
- duplicate API requests
- missing error handling
- inconsistent response typing
- client-side exposure of internal infrastructure

Where appropriate, consider whether a server-side layer should proxy sensitive backend interactions.

Do not recommend proxying every request without reason.

---

## 23. TypeScript

Check for:

- unnecessary any
- unsafe type assertions
- incorrect optional properties
- incorrect union handling
- missing null checks
- runtime assumptions not guaranteed by TypeScript
- misuse of enums
- incorrect generic constraints
- non-exhaustive handling of important unions
- API types diverging from runtime data

Remember that TypeScript does not validate runtime input.

External data may still require runtime validation.

---

## 24. Runtime Validation

For external input such as:

- API responses
- forms
- route parameters
- environment variables
- third-party responses

Check whether runtime validation is needed.

Possible tools may include schema validators, but do not recommend a library unless it provides clear value.

---

## 25. Component Design

Check for:

- very large components
- mixed responsibilities
- business logic tightly coupled to presentation
- repeated UI logic
- duplicated fetching logic
- side effects mixed deeply into rendering code
- difficult-to-test logic

Do not split components merely to reduce line count.

Recommend extraction only when it improves responsibility, reuse, testability, or readability.

---

## 26. Server / Browser Boundaries

Check for accidental usage of browser APIs such as:

- window
- document
- localStorage
- sessionStorage
- navigator

inside server execution paths.

Also check for server-only dependencies accidentally bundled into client code.

Pay attention to shared utility modules imported from both server and client components.

---

## 27. Third-Party Scripts

Check for:

- blocking scripts
- scripts loaded too early
- missing cleanup
- duplicate script loading
- global side effects
- security risks
- performance impact
- assumptions about script availability
- dependency on external scripts without error handling

When integrating third-party scripts, consider whether changes can be deployed without rebuilding the application if that is a project requirement.

---

## 28. Event Listeners

Check for:

- listeners registered multiple times
- listeners not removed
- global listeners added unnecessarily
- stale closures inside handlers
- expensive handlers on high-frequency events
- incorrect passive listener assumptions

---

## 29. Timers

Check for:

- intervals not cleared
- timeouts not cleared
- duplicate timers
- stale state captured by timers
- unnecessary polling
- polling continuing after component unmount

---

## 30. Lists and Large Data Sets

Check for:

- rendering very large lists at once
- missing pagination
- missing infinite-scroll safeguards
- duplicated pages
- incorrect pagination keys
- race conditions during incremental loading
- stale pagination state
- loading the same page multiple times

For infinite scrolling, inspect:

- loading state
- end-of-data handling
- deduplication
- race conditions
- query changes resetting the list correctly

---

## 31. Internationalization

When the project supports multiple locales, check for:

- hard-coded user-facing text
- incorrect locale assumptions
- incorrect date formatting
- incorrect number formatting
- timezone issues
- layout assumptions that break with longer translations

Do not report hard-coded text when internationalization is not part of the application requirements.

---

## 32. Date and Time

Check for:

- browser/server timezone mismatch
- implicit local timezone usage
- date-only values shifted by timezone conversion
- inconsistent parsing
- locale-dependent parsing
- incorrect UTC conversion

Date and time behavior should be explicit when business behavior depends on timezone.

---

## 33. Testing Expectations

Depending on the change, consider:

- component tests
- unit tests
- integration tests
- API/route handler tests
- rendering tests
- user interaction tests
- regression tests
- permission tests
- loading/error state tests

Focus on changed behavior.

Do not request every possible test type.

---

## 34. Review Priorities

When review time is limited, prioritize:

1. Correctness
2. Security and authorization
3. Server/client boundary
4. Data consistency
5. Rendering/hydration issues
6. API and integration behavior
7. Performance
8. Test gaps
9. Accessibility
10. Maintainability

---

## 35. False Positive Prevention

Do not report issues solely because a pattern looks unusual.

Inspect surrounding code and runtime context.

Examples:

- Do not report `"use client"` as a problem unless it unnecessarily expands the client boundary or causes another issue.
- Do not report useEffect automatically; verify whether the effect is actually unnecessary or incorrect.
- Do not report index keys if the list is static and never reordered.
- Do not report hydration problems unless server/client output can genuinely differ.
- Do not report missing memoization without realistic performance evidence.
- Do not report client-side fetching as wrong merely because server fetching is possible.
- Do not report dangerouslySetInnerHTML automatically when the content is controlled and safe.
- Do not report missing SEO metadata for internal applications where SEO is irrelevant.

When evidence is incomplete, mark the finding as:

Needs verification

Explain exactly what needs to be verified.

---

## 36. Review Scope

The reviewer may inspect:

- changed components
- related hooks
- related utilities
- route handlers
- server actions
- API clients
- types
- configuration
- related pages/layouts
- direct callers
- direct dependencies
- relevant tests

Do not recursively inspect the entire repository unless the change genuinely requires broad impact analysis.

The goal is to understand enough context to identify realistic production risks.