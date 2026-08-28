**AROGYAMITRA**

**Product Requirements Document (PRD)**

_Multilingual, Interoperable Care Navigation & Referral Platform_

| **Document**       | **Value**                                         |
| ------------------ | ------------------------------------------------- |
| Version            | 1.0                                               |
| Status             | Implementation-ready product baseline             |
| Primary stack      | Dart + Flutter                                    |
| Backend            | Dart server architecture                          |
| Database           | PostgreSQL                                        |
| Interoperability   | FHIR / ABDM adapters                              |
| Channels           | Citizen, ASHA/ANM, Facility MO, DHO/State         |
| Primary deployment | Android + Flutter Web; Docker, later Kubernetes   |
| Target geography   | India; adaptable to state/district health systems |

**Product principle:** ArogyaMitra owns care-navigation workflows and orchestration. Government and ecosystem platforms such as ABDM, Bhashini, eSanjeevani and authorized ambulance systems are connected through replaceable integration adapters.

# 1\. Executive Summary

ArogyaMitra is a multilingual digital care-navigation platform designed to connect citizens, ASHA/ANM workers, health facilities, medical officers and district/state administrators through a single workflow. The platform identifies care needs, performs symptom-based triage, finds suitable nearby facilities, evaluates facility readiness, manages referrals, coordinates emergency escalation, supports teleconsultation, tracks follow-up and collects citizen feedback.

The product is intentionally designed as an orchestration platform rather than a replacement for national health infrastructure. ArogyaMitra maintains operational workflow data and integrates with authorized external systems using isolated adapters. This prevents external API changes from leaking into the core domain and allows the platform to operate with mocks during development and approved government integrations in production.

## 1.1 Product Vision

Make the right care pathway discoverable, understandable and actionable for every citizen, including people with limited digital literacy, language barriers, poor connectivity or feature phones.

## 1.2 Core Outcome

A citizen should be able to move from 'I need care' to an appropriate next action—self-care guidance, nearby facility, teleconsultation, referral or emergency response—with a traceable workflow and appropriate consent, privacy and safety controls.

# 2\. Problem Statement

- Citizens may not know which facility is appropriate for a symptom or condition.
- The nearest facility may not have the required doctor, medicine, diagnostic capability or bed.
- Referral workflows can be fragmented across facilities and channels.
- ASHA/ANM workers need offline-capable tools for household registration, screening, referral and follow-up.
- Citizens may prefer local languages and voice rather than text-heavy interfaces.
- Government and health-system data exists across multiple platforms and cannot be treated as one monolithic database.
- District administrators need operational visibility into readiness, utilization, referral bottlenecks, ambulance response and citizen feedback.
- Emergency pathways need explicit escalation, status tracking and SLA monitoring.

# 3\. Goals and Non-Goals

## 3.1 Goals

- Provide a unified care-navigation workflow across citizen, field-worker and facility channels.
- Support Tamil/English initially, with architecture for additional Indian languages.
- Provide deterministic, clinically governed triage and escalation rules.
- Rank facilities using configurable readiness, distance/travel-time, service match and capacity factors.
- Manage referrals using an explicit state machine.
- Support offline-first ASHA/ANM workflows.
- Integrate with ABDM/FHIR, Bhashini, telemedicine and authorized ambulance systems through adapters.
- Provide role-based operational dashboards and audit trails.
- Build an MVP that can later scale to district/state deployment.

## 3.2 Non-Goals

- ArogyaMitra is not a replacement for a hospital information system.
- ArogyaMitra is not an autonomous diagnostic system.
- ArogyaMitra does not independently create or operate unauthorized government API integrations.
- ArogyaMitra is not a national health-record repository.
- AI/LLM output will not be allowed to independently make high-risk medical decisions.
- The platform will not bypass consent, identity, security or data-access controls.

# 4\. Target Users and Roles

| **Role**        | **Primary needs**                                                         | **Main interface**   |
| --------------- | ------------------------------------------------------------------------- | -------------------- |
| Citizen         | Care request, triage, facility discovery, referral, teleconsult, feedback | Flutter Android/PWA  |
| ASHA            | Household registration, screening, referral, follow-up, education         | Flutter Android      |
| ANM             | Screening, clinical workflow support, follow-up, reports                  | Flutter Android      |
| Medical Officer | Facility readiness, referral acceptance, patient/referral queue           | Flutter Web          |
| Facility Admin  | Resources, staff/service status, operational reports                      | Flutter Web          |
| DHO             | District monitoring, SLA, readiness, outcomes                             | Flutter Web          |
| State Admin     | State-wide analytics, governance, configuration                           | Flutter Web          |
| System Admin    | Identity, configuration, integrations, audit                              | Secure admin console |

# 5\. Product Scope

## 5.1 Citizen App / USSD

- Language selection and accessibility preferences.
- Mobile-number/approved identity onboarding.
- Symptom-based care request.
- Emergency shortcut and emergency escalation.
- Voice input and audio responses.
- Nearby facility discovery.
- Facility readiness and service availability display.
- Directions and contact information.
- Referral status tracking.
- Teleconsultation initiation where eligible.
- Ambulance request/status where authorized.
- Follow-up reminders.
- Feedback and issue reporting.
- USSD session flow for feature-phone users.

## 5.2 ASHA/ANM App

- Secure worker login.
- Assigned-area/household list.
- Household and member registration.
- Screening forms.
- Risk identification and referral.
- Facility readiness lookup.
- Referral creation and tracking.
- Follow-up task queue.
- Health education and reminders.
- Offline data capture.
- Background synchronization with conflict handling.
- Sync/error dashboard.

## 5.3 Facility MO Console

- Facility profile and service configuration.
- Doctor availability.
- Essential medicine availability.
- Diagnostic availability.
- Bed/capacity status.
- Readiness score and history.
- Incoming referral queue.
- Referral accept/reject/escalate actions.
- Patient/encounter workflow integration.
- Teleconsultation status where supported.
- Operational reports and alerts.

## 5.4 DHO/State Dashboard

- Facility readiness heatmap.
- Service utilization trends.
- Referral volume and completion.
- Referral turnaround time.
- SLA and escalation alerts.
- Ambulance response analytics.
- Teleconsultation utilization.
- Follow-up compliance.
- Feedback/NPS and issue categories.
- District/state filtering and drill-down.

# 6\. Functional Requirements

| **ID** | **Feature**            | **Requirement**                                                                                                      |
| ------ | ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| FR-001 | User authentication    | The system shall authenticate users through an approved identity mechanism and issue short-lived access tokens.      |
| FR-002 | Role authorization     | The system shall enforce role and scope-based access for citizen, ASHA/ANM, MO, facility admin, DHO and state admin. |
| FR-003 | Language               | The UI shall support Tamil and English initially and be localization-ready.                                          |
| FR-004 | Symptom intake         | Citizen and field-worker channels shall capture structured symptoms, duration, severity and red-flag indicators.     |
| FR-005 | Triage                 | The system shall run a clinically reviewed rule set and return a risk category plus next action.                     |
| FR-006 | Emergency escalation   | Emergency/red-flag outcomes shall trigger the configured emergency pathway.                                          |
| FR-007 | Facility discovery     | The system shall search facilities by geography, service and current readiness.                                      |
| FR-008 | Facility scoring       | The referral engine shall calculate a configurable facility score using approved factors.                            |
| FR-009 | Referral               | Users with appropriate permissions shall create, accept, reject, update and close referrals.                         |
| FR-010 | Referral state machine | Referral transitions shall be validated and audited.                                                                 |
| FR-011 | Follow-up              | The system shall schedule, assign and track follow-up tasks.                                                         |
| FR-012 | Feedback               | Citizens shall be able to submit ratings and categorized issues.                                                     |
| FR-013 | Readiness              | Facilities shall maintain resource readiness indicators and history.                                                 |
| FR-014 | Notifications          | The system shall send approved notifications through configurable channels.                                          |
| FR-015 | Offline mode           | ASHA/ANM workflows shall function without continuous network connectivity.                                           |
| FR-016 | Sync                   | Offline records shall synchronize when connectivity returns and surface conflicts.                                   |
| FR-017 | ABDM integration       | The platform shall integrate with authorized ABDM capabilities through a dedicated adapter.                          |
| FR-018 | FHIR                   | Health-information exchange shall use supported FHIR resources and validation.                                       |
| FR-019 | Bhashini               | The platform shall support speech/language services through a Bhashini adapter.                                      |
| FR-020 | Telemedicine           | The platform shall support authorized teleconsultation workflow integration.                                         |
| FR-021 | Ambulance              | The platform shall support authorized ambulance request/status integration.                                          |
| FR-022 | Analytics              | Operational events shall feed dashboard metrics.                                                                     |
| FR-023 | Audit                  | Sensitive actions shall generate immutable audit records.                                                            |

# 7\. End-to-End Care Journey

Reference journey:

1. Citizen selects language and chooses 'I need care'.
2. Citizen enters symptoms by text, guided options or voice.
3. Bhashini speech-to-text/translation may normalize the input.
4. Triage engine checks emergency red flags and classifies risk.
5. If emergency, the emergency workflow is triggered and ambulance dispatch is requested through the authorized adapter.
6. If non-emergency, the facility service retrieves candidate facilities.
7. Readiness, service match, capacity and travel-time factors are calculated.
8. The referral engine recommends the best eligible facility.
9. Citizen accepts the recommendation or requests an alternative.
10. Referral is created and sent to the destination facility.
11. Facility MO accepts, rejects or escalates the referral.
12. Citizen receives directions/status and, where applicable, ambulance ETA or teleconsult session details.
13. Arrival/consultation events update the referral state.
14. Follow-up is scheduled and assigned.
15. Citizen/ASHA receives follow-up reminders.
16. Outcome and feedback are captured.
17. Aggregated operational events become available to DHO/State dashboards.

# 8\. System Architecture

The architecture uses Flutter for all primary user applications, a Dart backend for ArogyaMitra domain services, PostgreSQL for operational data, Redis for ephemeral state and caching, and an integration layer for external systems.

Recommended logical layers: Presentation → API Gateway → Application/Domain Services → Data/Event Layer → Integration Adapters → External Government/Ecosystem Platforms.

## 8.1 Architecture Principles

- API-first design.
- Domain-driven modular boundaries.
- Adapter pattern for every external government/service integration.
- Offline-first for ASHA/ANM workflows.
- FHIR for interoperable clinical exchange where applicable.
- Event-driven architecture for notifications and analytics.
- Least privilege and purpose-based access.
- Consent-aware access to health information.
- Configuration-driven scoring, rules and service availability.
- Observability from day one.

# 9\. Technology Stack

| **Layer**            | **Technology**                         | **Purpose**                             |
| -------------------- | -------------------------------------- | --------------------------------------- |
| Citizen application  | Flutter + Dart                         | Android/PWA care-navigation experience  |
| ASHA/ANM application | Flutter + Dart                         | Offline-first field workflow            |
| MO/DHO web           | Flutter Web + Dart                     | Operational and governance dashboards   |
| State management     | Riverpod                               | Reactive application state              |
| Networking           | Dio/http                               | REST/HTTP communication                 |
| Local storage        | Drift/SQLite                           | Offline cache and sync queue            |
| Backend              | Dart server                            | ArogyaMitra API and domain services     |
| Authentication       | OIDC/OAuth2 + Keycloak or approved IAM | Identity and token management           |
| Database             | PostgreSQL                             | Operational relational data             |
| Cache/session        | Redis                                  | OTP/session/cache/rate-limit state      |
| Events               | Kafka (scale phase)                    | Domain events and analytics integration |
| FHIR                 | HAPI FHIR or validated FHIR service    | FHIR resource validation/exchange       |
| Object storage       | S3-compatible storage                  | Documents/reports/exports               |
| Maps                 | Approved mapping/routing provider      | Distance, route and ETA                 |
| Voice/language       | Bhashini adapter                       | STT/TTS/translation/language services   |
| Telemedicine         | eSanjeevani adapter                    | Authorized teleconsult workflow         |
| Ambulance            | State/authorized adapter               | Dispatch and status                     |
| Monitoring           | Prometheus + Grafana                   | Metrics and dashboards                  |
| Tracing              | OpenTelemetry                          | Distributed tracing                     |
| Logging              | Centralized structured logs            | Operational/security investigation      |
| Containers           | Docker                                 | Packaging                               |
| Orchestration        | Kubernetes later                       | High-availability deployment            |
| CI/CD                | GitHub Actions                         | Build/test/security/deploy automation   |

# 10\. Application Architecture

## 10.1 Flutter Monorepo

Recommended repository structure:

arogyamitra/  
├── apps/  
│ ├── citizen/  
│ ├── asha/  
│ ├── facility/  
│ └── dho/  
├── packages/  
│ ├── core/  
│ ├── models/  
│ ├── networking/  
│ ├── authentication/  
│ ├── localization/  
│ ├── maps/  
│ └── ui_components/  
├── backend/  
│ └── arogyamitra_server/  
│ ├── auth/  
│ ├── households/  
│ ├── patients/  
│ ├── facilities/  
│ ├── readiness/  
│ ├── triage/  
│ ├── referrals/  
│ ├── followups/  
│ ├── feedback/  
│ ├── notifications/  
│ └── integrations/  
│ ├── abdm/  
│ ├── bhashini/  
│ ├── esanjeevani/  
│ └── ambulance/  
└── infrastructure/  
├── docker/  
├── kubernetes/  
└── monitoring/

## 10.2 Backend Modular Design

- Controller/API layer: validates requests, authentication and authorization.
- Application layer: orchestrates use cases.
- Domain layer: triage, readiness, referral and follow-up rules.
- Repository layer: persistence abstraction.
- Integration layer: external API adapters.
- Event layer: publishes domain events.
- Audit layer: records sensitive actions.

# 11\. Data Model

| **Entity**             | **Key fields**                                                                |
| ---------------------- | ----------------------------------------------------------------------------- |
| User                   | id, role, phone, status, scope, created_at                                    |
| Household              | id, code, address/village, geo_point, assigned_worker                         |
| Patient                | id, household_id, approved identifiers, demographics                          |
| Facility               | id, HFR/reference ID where applicable, type, location, district               |
| FacilityResource       | facility_id, resource_type, quantity/status, updated_at                       |
| ReadinessCheck         | facility_id, doctor, medicines, diagnostics, beds, score, checked_at          |
| TriageAssessment       | patient_id, symptoms, red_flags, risk_level, rule_version                     |
| Referral               | id, patient_id, source, destination, priority, status, created_at             |
| ReferralEvent          | referral_id, event_type, actor, timestamp, metadata                           |
| FollowUp               | patient_id, referral_id, due_date, assignee, status, outcome                  |
| Feedback               | patient_id/facility_id, rating, category, comment, status                     |
| Notification           | recipient, channel, template, delivery status, timestamps                     |
| ConsentRecord          | subject, requester, purpose, scope, status, timestamps, transaction reference |
| AuditLog               | actor, action, resource, purpose, timestamp, trace_id                         |
| IntegrationTransaction | system, operation, correlation_id, request/response metadata, status          |

# 12\. Referral and Readiness Logic

## 12.1 Facility Score

The default scoring model should be configurable rather than hard-coded. A baseline can use travel time, estimated wait/capacity, department/service match and readiness confidence.

**Example:** score = w1 × normalized inverse travel time + w2 × normalized inverse wait + w3 × service match + w4 × capacity confidence

All weights must be stored in configuration with versioning and audit history.

## 12.2 Referral State Machine

CREATED  
↓  
TRIAGED  
↓  
RECOMMENDED  
↓  
REFERRAL_SENT  
↓  
ACCEPTED  
↓  
PATIENT_TRAVELLING  
↓  
ARRIVED  
↓  
CONSULTATION  
↓  
COMPLETED  
<br/>Alternate terminal/exception states:  
REJECTED, CANCELLED, EXPIRED, NO_SHOW, EMERGENCY_ESCALATED

## 12.3 Readiness

- Doctor availability.
- Essential medicines.
- Diagnostics.
- Beds/capacity.
- Service/department availability.
- Last-update timestamp and confidence.
- Manual override only with authorized role and reason.
- Stale data must be visually flagged.

# 13\. API Specification

| **Endpoint**                      | **Method** | **Purpose**                  |
| --------------------------------- | ---------- | ---------------------------- |
| /api/v1/auth/login                | POST       | Authenticate user            |
| /api/v1/households                | POST/GET   | Create/search households     |
| /api/v1/patients                  | POST/GET   | Create/search patients       |
| /api/v1/triage                    | POST       | Run symptom triage           |
| /api/v1/facilities                | GET        | Search facilities            |
| /api/v1/facilities/{id}/readiness | GET/PUT    | Read/update readiness        |
| /api/v1/referrals                 | POST/GET   | Create/search referrals      |
| /api/v1/referrals/{id}/accept     | POST       | Accept referral              |
| /api/v1/referrals/{id}/reject     | POST       | Reject referral              |
| /api/v1/referrals/{id}/events     | GET        | Referral timeline            |
| /api/v1/followups                 | POST/GET   | Schedule and track follow-up |
| /api/v1/feedback                  | POST       | Submit feedback              |
| /api/v1/notifications             | GET        | Notification inbox           |
| /api/v1/ambulance/requests        | POST       | Request authorized ambulance |
| /api/v1/teleconsult/sessions      | POST       | Create teleconsult workflow  |
| /api/v1/integrations/abdm/\*      | Internal   | ABDM adapter operations      |
| /api/v1/integrations/bhashini/\*  | Internal   | Language/voice operations    |

All APIs shall use versioning, correlation IDs, idempotency keys for retriable commands, structured errors and audit logging.

# 14\. Integration Requirements

## 14.1 ABDM

- Integrate only through official/authorized interfaces.
- Use sandbox for development and integration testing.
- Keep ABDM credentials and secrets outside source code.
- Implement ABHA/consent/health-information workflows only where the product use case and authorization permit.
- Use FHIR resources for supported clinical data exchange.
- Persist only the minimum operational metadata required by ArogyaMitra.
- Record transaction/correlation identifiers for troubleshooting.

## 14.2 Bhashini

- Speech-to-text for citizen/worker voice input.
- Text-to-speech for accessible responses.
- Translation between supported languages.
- Language detection where useful.
- Audio should be handled with explicit retention rules; avoid unnecessary storage.

## 14.3 eSanjeevani / Teleconsultation

- Use only approved integration mechanisms.
- Create a teleconsultation session from ArogyaMitra only when the user is eligible and the workflow permits.
- Track session lifecycle without duplicating external platform data unnecessarily.
- Maintain consent and audit information.

## 14.4 Ambulance

- Create an adapter interface independent of the state/provider.
- Support request, dispatch, location/status, ETA and completion events where exposed.
- Use a mock adapter for development.
- Do not assume a universal 108 API; deployment-specific authorization and interface contracts are required.

# 15\. Offline-First Requirements

- ASHA/ANM must be able to access assigned households without network.
- Forms shall save locally before submission.
- Every write shall receive a local UUID.
- Sync queue shall use retry with exponential backoff.
- Duplicate submission shall be prevented with idempotency keys.
- Conflicts shall be detected and resolved using field-level rules.
- Sensitive local data shall be encrypted where supported.
- Logout/remote disable shall invalidate access and protect local data.
- The user shall see last-sync time and pending item count.

# 16\. Security, Privacy and Safety

- TLS for all network communication.
- Short-lived access tokens and refresh-token rotation where supported.
- Role and scope-based authorization.
- Least-privilege service accounts.
- Secrets stored in a secret manager.
- Encryption at rest for databases/storage according to deployment requirements.
- Immutable or append-only audit logging for sensitive actions.
- Purpose-aware access to health information.
- Consent workflow for applicable health-information exchange.
- Rate limiting and abuse protection on public APIs.
- Input validation and output encoding.
- Dependency and container vulnerability scanning.
- Security testing before production.
- No autonomous diagnosis or unsafe medical advice from an LLM.
- Clinical triage rules must have a documented owner, version and approval process.
- Emergency messaging must clearly distinguish urgent action from general information.

# 17\. Non-Functional Requirements

| **Category**     | **Requirement / target**                                                                                                      |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Availability     | Target 99.9% for production core APIs, excluding planned maintenance and external dependency outages.                         |
| Performance      | Typical read APIs should target p95 < 500 ms under normal load; triage should target p95 < 1 s excluding external voice APIs. |
| Scalability      | Horizontal scaling of stateless API instances.                                                                                |
| Offline          | ASHA workflows must remain usable during temporary connectivity loss.                                                         |
| Recovery         | Automated backups and tested restore procedures.                                                                              |
| Observability    | Metrics, structured logs, traces and integration health checks.                                                               |
| Accessibility    | Large touch targets, readable typography, voice/audio support and low-literacy flows.                                         |
| Localization     | No hard-coded user-facing strings.                                                                                            |
| Auditability     | Sensitive actions traceable to actor, time, purpose and resource.                                                             |
| Interoperability | FHIR-based exchange where applicable; adapters isolate external APIs.                                                         |
| Maintainability  | Modular domain packages and automated tests.                                                                                  |
| Security         | OWASP-aligned secure development and regular dependency/security scanning.                                                    |

# 18\. Notifications

| **Event**            | **Citizen** | **ASHA/ANM** | **MO** | **DHO**  |
| -------------------- | ----------- | ------------ | ------ | -------- |
| Referral created     | Yes         | Yes          | Yes    | Optional |
| Referral accepted    | Yes         | Yes          | Yes    | Optional |
| Referral rejected    | Yes         | Yes          | Yes    | Optional |
| Ambulance dispatched | Yes         | Yes          | Yes    | Optional |
| Follow-up due        | Yes         | Yes          | No     | Optional |
| SLA breach           | Optional    | Optional     | Yes    | Yes      |
| Readiness critical   | No          | Optional     | Yes    | Yes      |
| Feedback issue       | Optional    | Optional     | Yes    | Yes      |

# 19\. Analytics and KPIs

| **KPI**                    | **Definition**                                                  |
| -------------------------- | --------------------------------------------------------------- |
| Triage completion rate     | Completed triage / started triage                               |
| Referral acceptance rate   | Accepted referrals / referrals sent                             |
| Referral completion rate   | Completed referrals / referrals created                         |
| Median referral turnaround | Time from referral creation to accepted/arrived/completed state |
| Facility readiness         | Current readiness score and component availability              |
| Ambulance response time    | Dispatch request to arrival where data is available             |
| Follow-up completion       | Completed follow-ups / due follow-ups                           |
| Teleconsult utilization    | Completed teleconsults / initiated sessions                     |
| Citizen satisfaction       | Average rating and NPS-like measures where implemented          |
| SLA breach rate            | Breached workflows / monitored workflows                        |

# 20\. AI and Decision Support Policy

AI can assist with language normalization, summarization, search, routing support and analytics, but the initial safety-critical triage engine shall be deterministic and clinically governed.

- AI suggestions must be labeled as suggestions.
- No AI-generated diagnosis may be presented as a confirmed diagnosis.
- Emergency red flags must be handled by deterministic rules.
- Clinical rules must be versioned.
- Every triage result must store rule/version metadata.
- AI/LLM prompts and outputs must not expose unnecessary personal health information.
- Human override and escalation must be available.
- Model monitoring and safety evaluation are required before any clinical decision-support expansion.

# 21\. DevOps and Deployment

MVP deployment:

- Docker Compose.
- Managed or hardened PostgreSQL.
- Redis.
- Dart API container.
- Flutter Web served through CDN/reverse proxy.
- Android APK/AAB distribution through controlled testing.

Scale deployment:

- Kubernetes.
- Load balancer/WAF.
- Multiple stateless API replicas.
- Managed PostgreSQL HA.
- Redis HA.
- Kafka cluster.
- Object storage.
- Centralized logs and metrics.
- Automated backup/restore and disaster recovery.

## 21.1 CI/CD Pipeline

1. Pull request.
2. Dart format/analyze.
3. Unit tests.
4. Widget tests.
5. Integration/API tests.
6. Dependency vulnerability scan.
7. SAST.
8. Container build and scan.
9. Deploy to staging.
10. Smoke tests.
11. Security/DAST tests.
12. Manual approval for production.
13. Production deployment.
14. Post-deployment health verification.

# 22\. Testing Strategy

- Unit tests for domain rules, scoring and state transitions.
- Widget tests for critical Flutter screens.
- Integration tests for offline sync.
- API contract tests.
- FHIR validation tests.
- External integration tests using sandbox/mock adapters.
- Security tests.
- Load tests.
- Accessibility tests.
- Failure-mode tests for external dependency outages.
- Disaster recovery/restore tests.

# 23\. MVP Definition

The first demonstrable MVP should complete one end-to-end care journey:

1. Citizen opens Flutter app.
2. Citizen selects Tamil/English.
3. Citizen enters symptoms.
4. Triage engine classifies low/medium/high risk.
5. System searches nearby facilities.
6. Readiness service returns current facility status.
7. Referral engine ranks facilities.
8. Citizen chooses a recommended facility.
9. Referral is created.
10. MO console receives the referral.
11. MO accepts referral.
12. Citizen sees referral status.
13. ASHA can view/perform follow-up.
14. Citizen submits feedback.
15. DHO dashboard displays the referral and readiness metrics.

MVP external integrations can use mock adapters, while the same interfaces are preserved for later ABDM/Bhashini/eSanjeevani/ambulance production integrations.

# 24\. Implementation Roadmap

| **Phase**                  | **Scope**                                                          | **Exit criteria**                                         |
| -------------------------- | ------------------------------------------------------------------ | --------------------------------------------------------- |
| 0\. Architecture           | Repository, UX flows, threat model, API contracts, database design | Approved architecture and backlog                         |
| 1\. Foundation             | Flutter apps, Dart API, auth, PostgreSQL, roles                    | Users can securely log in and access role-specific shells |
| 2\. Facility readiness     | Facility registry, resources, readiness dashboard                  | MO can update and DHO can monitor readiness               |
| 3\. Triage/referral        | Triage rules, facility scoring, referral state machine             | End-to-end referral works                                 |
| 4\. Offline ASHA           | SQLite/Drift, sync queue, conflict handling                        | ASHA can work offline and synchronize                     |
| 5\. Voice/language         | Bhashini adapter, Tamil/English UX                                 | Voice-assisted multilingual journey works                 |
| 6\. Interoperability       | ABDM/FHIR adapters and authorized sandbox flows                    | Sandbox integration passes functional tests               |
| 7\. Telemedicine/ambulance | Authorized adapters                                                | Mock-to-approved integration transition                   |
| 8\. Analytics              | Events, KPIs, DHO/state dashboards                                 | Operational metrics available                             |
| 9\. Hardening              | Security, load, DR, audit, observability                           | Production readiness review passed                        |

# 25\. Suggested Team

| **Role**                          | **Responsibilities**                                             |
| --------------------------------- | ---------------------------------------------------------------- |
| Product Owner                     | Requirements, stakeholder coordination, roadmap                  |
| Clinical/Health-system advisor    | Triage, workflows, safety and governance                         |
| Flutter Lead                      | Application architecture and shared packages                     |
| Flutter Developers                | Citizen, ASHA, MO/DHO applications                               |
| Dart Backend Developer            | APIs, domain services, integrations                              |
| Backend/Interoperability Engineer | FHIR, ABDM and external adapters                                 |
| UI/UX Designer                    | Low-literacy, accessibility and multilingual flows               |
| DevOps/Security Engineer          | CI/CD, infrastructure, IAM, monitoring and security              |
| QA Engineer                       | Functional, integration, offline, performance and security tests |
| Data/Analytics Engineer           | Events, KPIs and DHO/state analytics                             |

# 26\. Risks and Mitigations

| **Risk**                     | **Impact** | **Mitigation**                                                                     |
| ---------------------------- | ---------- | ---------------------------------------------------------------------------------- |
| External API availability    | High       | Adapter layer, retries, circuit breakers, mocks and clear degraded mode            |
| Incorrect triage             | Critical   | Clinical governance, deterministic red flags, versioned rules and human escalation |
| Poor connectivity            | High       | Offline-first ASHA workflow and queued synchronization                             |
| Stale facility data          | High       | Timestamp/confidence, stale-data warnings and readiness refresh                    |
| Privacy breach               | Critical   | Least privilege, encryption, audit, consent and security testing                   |
| Integration contract changes | High       | Versioned adapters and contract tests                                              |
| Over-engineering too early   | Medium     | Start modular; extract microservices only when scale requires                      |
| Low adoption                 | High       | Simple UX, local language, field-worker feedback and usability testing             |
| Vendor lock-in               | Medium     | Provider interfaces and adapter abstraction                                        |
| Infrastructure outage        | High       | HA deployment, backups, monitoring and DR                                          |

# 27\. Acceptance Criteria

- Citizen can complete a care request in Tamil and English.
- Emergency red flags trigger the configured emergency workflow.
- Facility results are ranked using the configured scoring model.
- Facility readiness shows component-level availability and timestamp.
- Referral lifecycle prevents invalid state transitions.
- MO can accept/reject/escalate a referral.
- ASHA can create records while offline and synchronize later.
- Duplicate synchronization does not create duplicate referrals/patients.
- Sensitive actions create audit records.
- Role-based users cannot access data outside their scope.
- External integration failures do not crash the core referral workflow.
- Mock adapters can be replaced with authorized production adapters without changing core domain logic.
- Dashboard KPIs reconcile with operational events.
- Backup restore is tested.
- Critical security findings are resolved before production.

# 28\. Definition of Done

- Requirements implemented and mapped to backlog items.
- Unit, integration and critical UI tests pass.
- API contracts documented.
- Database migrations versioned.
- Audit logging implemented.
- Security review completed.
- External integrations tested in the appropriate sandbox/mock environment.
- Offline sync tested under network interruption.
- Monitoring and alerting configured.
- Runbook and rollback procedure documented.
- User acceptance testing completed.
- Production readiness sign-off completed by product, technical and clinical stakeholders.

# 29\. Open Decisions Before Production

- State/district-specific ambulance interface and authorization.
- Exact ABDM role(s) and integration pathway applicable to the deployment.
- Exact FHIR profiles/resources required by participating health facilities.
- eSanjeevani integration mechanism and operational ownership.
- Identity/OTP provider and citizen authentication policy.
- Hosting environment and data-residency requirements.
- Clinical triage rule owner and approval committee.
- Data retention and deletion schedule.
- Notification providers and sender registration requirements.
- District/state operational escalation matrix.
- Final SLA targets and support model.

# 30\. Final Reference Architecture

USERS  
│  
├── Citizen Flutter  
├── ASHA/ANM Flutter  
├── MO Flutter Web  
└── DHO/State Flutter Web  
│  
▼  
API Gateway / WAF  
│  
▼  
DART BACKEND  
├── Auth & Authorization  
├── Household / Patient  
├── Facility Registry  
├── Readiness  
├── Triage  
├── Referral  
├── Follow-up  
├── Feedback  
├── Notification  
├── Analytics  
└── Audit  
│  
├────────────── PostgreSQL  
├────────────── Redis  
├────────────── Event Bus  
└────────────── Object Storage  
│  
▼  
INTEGRATION ADAPTERS  
├── ABDM / Consent / FHIR  
├── Bhashini  
├── eSanjeevani / Teleconsultation  
├── Authorized Ambulance / 108  
├── SMS / Notification  
└── Maps / Routing  
│  
▼  
EXTERNAL HEALTH ECOSYSTEM

# 31\. Product Success Definition

ArogyaMitra is successful when a citizen can access the appropriate next care action through a simple local-language experience; a field worker can continue essential work despite intermittent connectivity; a facility can accurately publish readiness and manage referrals; and district/state administrators can see measurable operational outcomes. The architecture must remain interoperable, secure, auditable and replaceable at every external integration boundary.

**End of PRD — ArogyaMitra v1.0**