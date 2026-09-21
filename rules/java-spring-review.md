# Java / Spring Boot Code Review Rules

These rules extend the common code review rules for Java and Spring Boot projects.

Focus on production behavior, scalability, data consistency, concurrency, reliability, security, and maintainability.

---

## 1. Java Language

Check for:

- incorrect null handling
- unsafe Optional usage
- incorrect equals/hashCode implementation
- mutable shared state
- unsafe casting
- incorrect collection choice
- misuse of streams
- resource leaks
- incorrect exception handling
- swallowed exceptions
- incorrect date/time handling
- BigDecimal precision or comparison mistakes
- thread-safety problems
- unnecessary object creation in hot paths

Pay attention to:

- immutable vs mutable objects
- defensive copying when needed
- misuse of static mutable fields
- incorrect use of parallel streams
- inappropriate use of synchronized
- incorrect generics usage
- misuse of checked and unchecked exceptions

---

## 2. Spring Dependency Injection

Check for:

- incorrect bean scope
- circular dependencies
- field injection where it creates testing or lifecycle problems
- manually creating objects that should be Spring-managed
- multiple ambiguous bean implementations
- incorrect @Qualifier usage
- configuration classes with unexpected side effects
- Spring beans holding unsafe mutable state

Prefer constructor injection unless there is a clear reason not to.

---

## 3. Transaction Management

Pay special attention to:

- missing @Transactional
- transaction boundary too large
- transaction boundary too small
- self-invocation bypassing Spring proxy
- incorrect propagation
- incorrect isolation level
- read-only transaction misuse
- long-running remote calls inside transactions
- rollback behavior
- checked exceptions not triggering rollback when expected
- nested transaction assumptions
- unexpected flush behavior
- transaction boundaries spanning unnecessary work

Check whether external API calls happen while a database transaction is open.

Example risk:

Database update -> external HTTP call -> second database update

Consider:

- what happens if the remote call fails
- what happens if the database commit fails after the remote call succeeds
- whether the operation can leave external systems and the database inconsistent
- whether retries can duplicate side effects

---

## 4. JPA / Hibernate

Check for:

- N+1 query problems
- LazyInitializationException risk
- unnecessary eager fetching
- excessive entity graph loading
- incorrect cascade configuration
- orphanRemoval misuse
- incorrect bidirectional relationship management
- entity equality problems
- detached entity problems
- unintended persistence caused by dirty checking
- missing pagination
- loading large collections into memory
- save() usage when unnecessary
- flush behavior issues
- incorrect JPQL
- inefficient Criteria queries
- unnecessary entity loading when projections would be more appropriate

Be careful with:

- @OneToMany
- @ManyToOne
- @ManyToMany
- FetchType.EAGER
- FetchType.LAZY
- cascade = ALL
- orphanRemoval = true

Do not report an N+1 issue unless the actual call path reasonably supports it.

---

## 5. SQL / Repository Layer

Check for:

- full table scans on potentially large tables
- missing filtering
- unbounded result sets
- incorrect joins
- duplicate rows
- incorrect DISTINCT usage
- unnecessary queries
- queries executed inside loops
- missing pagination
- expensive ORDER BY
- database functions preventing index usage
- inappropriate native queries
- fetching unnecessary columns or entities
- repeated query execution for identical data

For modifying queries check:

- transaction boundaries
- optimistic locking
- pessimistic locking
- affected row count validation
- consistency after bulk update/delete operations

When relevant, consider whether suitable indexes exist for:

- WHERE clauses
- JOIN columns
- ORDER BY
- frequently queried business keys

Do not recommend indexes without reasonable evidence that they are needed.

---

## 6. Concurrency and Data Consistency

Pay special attention to business-critical operations.

Check for:

- race conditions
- check-then-act bugs
- duplicate processing
- lost updates
- concurrent inserts
- double spending
- duplicated business actions
- missing optimistic locking
- missing unique constraints
- unsafe distributed locking
- incorrect synchronized usage
- assumptions that only one application instance exists
- read-modify-write sequences that are not atomic

Example pattern requiring attention:

Check if record exists -> record not found -> insert record

This can fail under concurrent requests unless the database also enforces the invariant.

Consider whether protection exists at:

- application level
- distributed lock level
- database level

Prefer database guarantees for critical invariants where appropriate.

---

## 7. Idempotency

For commands that may be retried, check:

- duplicate HTTP requests
- message re-delivery
- client retries
- API gateway retries
- scheduled retry jobs
- manual retry operations

Business-critical operations should be safe against duplicate execution when appropriate.

Check for:

- idempotency keys
- unique constraints
- processed-event tracking
- atomic updates
- business-level duplicate detection

Do not assume that retries happen only once.

Pay particular attention to:

- payment operations
- transfers
- disbursement
- notification sending
- account creation
- order creation
- external API requests with side effects

---

## 8. Redis and Caching

Check for:

- cache stampede
- cache penetration
- cache avalanche
- inconsistent TTL
- stale cache
- missing cache invalidation
- race conditions during cache refresh
- incorrect serialization
- distributed lock expiration
- lock ownership validation
- deleting another request's lock
- missing fallback behavior when Redis is unavailable
- excessive Redis calls
- large cached objects

Pay special attention when:

- TTL is about to expire
- many requests can arrive simultaneously
- cached data is expensive to regenerate
- multiple application instances access the same key

Consider whether an appropriate protection mechanism exists, such as:

- mutex or distributed lock
- stale-while-revalidate
- request coalescing
- randomized TTL

Do not recommend these mechanisms automatically; use them only when the traffic and failure pattern justify them.

---

## 9. Kafka / Messaging

Check producers for:

- duplicate publishing
- missing delivery acknowledgement
- serialization compatibility
- transactional consistency
- publishing before DB commit
- publishing after DB commit with failure risk
- incorrect key selection when ordering matters
- oversized messages

Check consumers for:

- duplicate delivery handling
- idempotency
- retry side effects
- poison messages
- dead-letter handling
- offset commit timing
- ordering assumptions
- partial processing
- long-running handlers
- blocking calls that affect consumer throughput
- unsafe concurrency

Example pattern requiring attention:

Consume event -> update database -> call external API -> exception -> message retried

Check whether repeated execution is safe.

Consider whether the consumer can process the same event multiple times.

---

## 10. REST APIs

Check controllers for:

- missing validation
- incorrect HTTP status codes
- leaking internal exceptions
- exposing sensitive data
- incorrect request binding
- excessively large payloads
- missing pagination
- API compatibility issues
- missing ownership or authorization checks
- accepting unsafe or unexpected input

For outbound REST calls check:

- connection timeout
- read timeout
- retries
- circuit breaker
- fallback
- bulkhead where relevant
- response validation
- error mapping
- handling of partial or malformed responses

Do not recommend retries blindly.

Retries can amplify failures and duplicate side effects.

---

## 11. Exception Handling

Check for:

- empty catch blocks
- logging and rethrowing causing duplicate logs
- converting exceptions without preserving the cause
- overly broad catch(Exception) usage
- exposing stack traces to clients
- incorrect exception mapping
- missing business error codes
- retrying non-retryable failures
- silently swallowing errors
- returning success after a partial failure

Check whether exceptions correctly reflect:

- business failure
- validation failure
- technical failure
- temporary failure

---

## 12. Logging

Check for:

- passwords
- access tokens
- refresh tokens
- API keys
- customer PII
- full request/response logging
- secrets
- card or payment data
- excessive logging inside loops
- incorrect log level
- expensive string construction
- logging complete entities or DTOs containing sensitive fields

Avoid logging sensitive objects directly.

Consider whether log statements provide enough context to diagnose production issues without exposing protected data.

---

## 13. Security

In addition to the common security rules, check:

- Spring Security configuration
- endpoint authorization
- method-level security
- missing ownership checks
- JWT validation
- expired token handling
- role/authority mistakes
- CSRF where applicable
- CORS configuration
- unsafe actuator exposure
- insecure management endpoints
- mass assignment risks
- user-controlled identifiers accessing another user's data

Check IDOR risks carefully.

Example:

GET /accounts/{accountId}

Verify that the caller is authorized to access that specific account, not merely authenticated.

---

## 14. Async / Thread Pools

Check for:

- unbounded thread pools
- CompletableFuture using the common pool unintentionally
- blocking calls inside async execution
- missing exception handling
- lost MDC/logging context
- thread-local leakage
- tasks silently rejected
- missing shutdown behavior
- inappropriate queue size
- thread pool exhaustion
- uncontrolled parallelism

For @Async, inspect whether the intended executor is used.

Check whether async execution changes transaction or security context assumptions.

---

## 15. Scheduled Jobs

Check for:

- multiple application instances executing the same job
- missing distributed locking where required
- duplicate processing
- long-running scheduled tasks
- overlapping executions
- lack of idempotency
- timezone assumptions
- failure causing silent loss of processing
- large batch processing without pagination
- retry behavior

Do not assume a scheduled method runs on only one application instance.

---

## 16. Configuration

Check for:

- hard-coded environment values
- secrets in application.yml or application.properties
- unsafe defaults
- incorrect profile configuration
- missing timeout settings
- configuration changes breaking existing environments
- differences between local and production behavior
- configuration values without validation
- risky feature flags
- incorrect environment variable fallback

Pay attention to configuration affecting:

- database pools
- HTTP clients
- Kafka
- Redis
- thread pools
- scheduled jobs
- security

---

## 17. API / Event Compatibility

Check changes to:

- REST DTOs
- Kafka schemas
- JSON field names
- enum values
- database schema expectations
- shared libraries
- serialized objects

Potentially breaking changes include:

- removing fields
- renaming fields
- changing field types
- making optional fields mandatory
- changing enum semantics
- changing default values
- changing endpoint behavior without changing the contract

Assume downstream consumers may not be deployed at the same time.

---

## 18. Database Migration

If schema changes exist, check:

- backward compatibility
- zero-downtime deployment risk
- nullable vs non-null changes
- default values
- large table migration impact
- index creation impact
- rollback strategy
- application version compatibility
- long-running locks
- destructive migration
- changing column types
- dropping columns too early

Consider deployment order.

Typical production deployment may look like:

DB migration -> old application instances still running -> rolling deployment -> new application instances

The schema may temporarily need to support both old and new application versions.

---

## 19. Connection Pool and Resource Usage

Check for:

- database connections held longer than necessary
- remote calls while holding database connections
- HikariCP pool exhaustion risks
- large transaction scopes
- streams or resources not closed
- excessive connection usage during batch operations

Pay particular attention to loops that execute database or external operations.

---

## 20. Batch Processing

For batch operations check:

- loading all records into memory
- missing pagination
- transaction size
- retry behavior
- partial failure handling
- duplicate processing
- long-running locks
- restartability
- idempotency

Large jobs should not assume that all data can safely be processed in one transaction.

---

## 21. Test Expectations

For Java/Spring changes, consider whether tests should include:

- unit tests
- repository tests
- integration tests
- controller/API tests
- concurrency tests
- transaction rollback tests
- retry/idempotency tests
- Kafka consumer tests
- Redis cache tests
- negative scenarios
- boundary cases

Focus test recommendations on the behavior affected by the change.

Do not request every test type for every pull request.

---

## 22. Review Priorities

When review time is limited, prioritize in this order:

1. Correctness
2. Transaction and data consistency
3. Concurrency and idempotency
4. Security
5. Database and JPA behavior
6. External integration reliability
7. Performance and scalability
8. Test gaps
9. Maintainability

Do not spend significant review effort on formatting unless it meaningfully affects readability, correctness, or maintainability.

---

## 23. False Positive Prevention

Do not report an issue simply because a potentially dangerous pattern exists.

Inspect the surrounding implementation first.

Examples:

- Do not report N+1 without checking how the relationship is actually loaded and used.
- Do not report missing @Transactional without verifying whether a transaction is actually required or already created by the caller.
- Do not report missing idempotency for a read-only operation.
- Do not report missing distributed locking when database constraints already guarantee correctness.
- Do not report a missing index without reasonable evidence that the query and expected data volume require it.
- Do not report thread-safety issues for request-scoped local variables.
- Do not report retry concerns when no retry mechanism exists in the call path.

When evidence is incomplete, mark the finding as:

Needs verification

Explain exactly what should be verified.

---

## 24. Review Scope

The reviewer may inspect:

- changed Java files
- related interfaces
- related implementations
- direct callers
- direct dependencies
- repositories
- entities
- DTOs
- relevant configuration
- migrations
- related tests

Do not recursively inspect the entire repository unless the change genuinely requires broad impact analysis.

The goal is to understand the change sufficiently to identify realistic production risks.