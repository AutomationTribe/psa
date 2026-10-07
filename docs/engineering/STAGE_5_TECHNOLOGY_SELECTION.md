# Stage 5 — Technology Selection

Status: Approved
Date: 2026-10-06

## Recommended stack

| Area | Selection | Reason |
|---|---|---|
| Android | Kotlin + Jetpack Compose | Direct access to foreground services, location, permissions, notifications, audio and battery controls. |
| iPhone | Swift + SwiftUI | Direct access to Core Location, background execution, audio and Apple permission behavior. |
| Shared contracts | OpenAPI-generated mobile clients | Shares API contracts without hiding platform-specific safety behavior. |
| Backend | Kotlin + Spring Boot modular monolith | Strong JVM typing, mature transactions/security/observability and alignment with the high-criticality profile. |
| Dashboard | TypeScript + React/Next.js | Mature dashboard ecosystem, accessibility support and shared TypeScript contracts. |
| Primary database | PostgreSQL + PostGIS | Transactional incident data plus geospatial queries and indexing. |
| Cache/coordination | No required external cache initially; add managed Redis only when measured need justifies it | Keeps the first deployment cheaper and avoids making Redis part of critical state. |
| Durable messaging | PostgreSQL transactional outbox + Railway worker | Provides retry-safe asynchronous processing without an additional paid queue during the controlled pilot. |
| Object storage | S3-compatible encrypted storage | Audio and controlled incident evidence with lifecycle rules. |
| Local development | Docker Compose | Runs backend dependencies locally without hosting charges. |
| Shared backend/dashboard hosting | Railway | Hosts Kotlin/Spring Boot API, workers and dashboard with incremental deployments. |
| Shared database | Neon PostgreSQL + PostGIS | Managed serverless PostgreSQL for development and controlled pilot workloads. |
| Later production infrastructure | Select after measured usage exceeds approved Railway/Neon limits | Live safety operations may later require stronger regional redundancy and recovery. |
| Observability | OpenTelemetry + managed logs, metrics, traces and alerts | Vendor-neutral instrumentation with operational evidence. |
| API specification | OpenAPI | Versioned partner and mobile contracts with generated clients and contract tests. |

## Mobile decision

Use native Android and iOS applications for version 1. Background location, low-battery operation, audio capture, notification behavior and permission recovery are core product functions and differ materially by platform.

Do not introduce Flutter, React Native or Kotlin Multiplatform into the critical runtime for version 1. Reconsider shared UI or domain code after the pilot produces maintenance and delivery evidence.

## Backend shape

Start as a Kotlin/Spring Boot modular monolith with independently executable API and worker processes. Keep clear modules for identity, circles/families, consent, trips/check-ins, incidents, location, notifications, audio/evidence, subscriptions, operator workflow, audit and partner API.

Do not start with microservices. Extract a module only when measured scaling, isolation or ownership needs justify it.

## Provider boundaries

Use internal provider interfaces for SMS, push notifications, maps/geocoding, payments, email and object storage. Provider acceptance and delivery evidence must remain separate states. No provider is selected by this stage without live Nigerian delivery, price and support evidence.

## Data and reliability rules

- PostgreSQL is the source of truth for users, consent, trips, incidents, subscriptions and audit references.
- PostGIS stores and queries geospatial data; every location retains capture time, accuracy, source and freshness state.
- A PostgreSQL transactional outbox and Railway worker handle alert attempts and retries using idempotency keys.
- Redis loss must not delete or corrupt an incident.
- Audio uses encrypted object storage; access and retention are controlled through backend authorization.
- Practice and live incidents use explicit data classification and cannot be confused in operator views.

## Deployment recommendation

- Containerized modular monolith and workers on a managed container platform.
- Managed PostgreSQL with backups and point-in-time recovery.
- Managed durable queue, Redis and encrypted object storage.
- Maintain two environments only: Local development/testing and hosted Pilot. Use separate credentials, databases and provider configuration; isolate practice and live incidents within Pilot.
- Infrastructure as code, automated migrations, secret manager and deployment rollback.

## Free-first development and delivery plan

- Kotlin, Spring Boot, Swift, Xcode, Android Studio, PostgreSQL, PostGIS, Redis, MinIO, Docker-compatible local tools, OpenAPI and Terraform are available without licence fees.
- Existing ChatGPT/Claude subscriptions may assist development; the product does not require paid LLM APIs.
- Run backend, database, cache and object-storage emulators locally on the development Mac.
- Deploy the backend, workers and monitoring dashboard to Railway.
- Use Neon for shared PostgreSQL/PostGIS data.
- Deploy each completed and tested vertical feature slice; do not wait for a big-bang release.
- Keep Local and Pilot configuration separated. Pilot practice incidents must use test routing and must not invoke real authority escalation; live incidents use approved live-provider routing.
- Use Firebase Cloud Messaging for push notifications at no charge.
- Use email and SMS sandbox/test credits first; purchase only a small Nigerian SMS balance for real-device delivery checks.

## Later paid-cloud reference cost

- Local development is expected to use the developer's existing hardware and free tools; Pilot hosting cost will be controlled and measured against the approved budget.
- Controlled pilot: approximately USD 150–350 monthly.
- Later high-availability hosting at larger scale: approximately USD 350–800 monthly before SMS, maps, payment fees, support and large audio/data usage. This is a possible upgrade to the Pilot environment, not a third required environment.

AWS Cape Town is only a later comparison option. It would run infrastructure in Amazon data centres in South Africa; it does not provide monitoring operators, emergency response, GPS or SMS.

These are planning ranges, not a quote. AWS is not selected. Reassessment is triggered by measured load, reliability needs, provider limits, regional latency, data governance or recovery requirements.

## Options deliberately rejected for version 1

| Option | Decision |
|---|---|
| Cross-platform mobile UI | Rejected initially because critical background behavior still requires native implementation and testing. |
| Microservices | Rejected because operational complexity exceeds current evidence and team needs. |
| Serverless-only backend | Rejected for the whole system; selective functions may be used, but incident workflows need predictable state and observability. |
| Self-hosted databases/queues on one VPS | Rejected for live safety operations because it creates excessive recovery and availability risk. |
| Redis as job or incident source of truth | Rejected because critical state requires durable persistence. |

## Decisions still required before approval

1. Native mobile delivery is approved; the selected tools have no development licence fee.
2. Kotlin with Spring Boot is approved; the selected tools have no development licence fee.
3. Railway plus Neon and incremental feature-slice deployment are approved. Production migration remains a later evidence-based decision.

## Exit gate

APPROVED on 2026-10-06. Proceed to architecture and engineering standards.
