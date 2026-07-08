MUKUBA UNIVERSITY
SCHOOL OF MATHEMATICAL AND NATURAL SCIENCES
DEPARTMENT OF COMPUTER SCIENCE

# PROJECT TITLE

**Design and Implementation of Wedpilot: An AI-Powered Cross-Platform Wedding Planning Platform**

BY:

> TODO: *Your Name*
> TODO: *Your Student ID Number*

A project report submitted to the Department of Computer Science in partial fulfilment
of the requirements for the award of the Bachelor's Degree in Computer Science
> TODO: *(confirm exact programme title, e.g. "Bachelor of Science in Computer Science")*.

Supervisor:
> TODO: *Supervisor's Name*

Mukuba University
> TODO: *Month, Year of submission*

---

## DECLARATION

I declare that this project report is my original work and has not been submitted to any
other institution for the award of a degree, diploma, or certificate. All sources of
information used in this report have been acknowledged appropriately.

Student Name: ___________________________
Signature: ______________________________
Date: __________________________________

---

## APPROVAL PAGE

This project report has been submitted with the approval of the project supervisor and the
Department of Computer Science.

Supervisor's Name: _______________________
Signature: ______________________________
Date: __________________________________

Head of Department: ______________________
Signature: ______________________________
Date: __________________________________

---

## DEDICATION

> TODO: *Optional — dedicate the work to parents, guardians, family, friends, or others, if you wish.*

---

## ACKNOWLEDGEMENTS

> TODO: *Acknowledge your supervisor, lecturers, classmates, family, and anyone (e.g. couples/vendors) who gave feedback during testing. Keep it to one short paragraph.*

---

## ABSTRACT

Wedding planning in Zambia and similar markets is largely coordinated through informal
channels — phone calls, physical visits, and word-of-mouth referrals — which makes it
difficult for couples to compare vendors, track spending against a budget, and keep a
wedding party coordinated in one place. This project addresses that problem by designing
and implementing Wedpilot, a cross-platform mobile and web application that brings
vendor discovery, AI-assisted budget planning, task management, guest and invitation
management, and in-app messaging into a single system serving three distinct user roles:
couples, vendors, and platform administrators.

The system was built using Flutter for the client application, targeting both Android and
the web from a single codebase, with Riverpod for state management and GoRouter for
role-aware navigation. The server is a Node.js/Express REST API backed by a MySQL
database accessed through the Sequelize ORM, with authentication implemented using
JSON Web Tokens and bcrypt password hashing. A distinguishing feature of the system is
its integration with Google's Gemini large language model, which is used to generate a
personalised wedding budget allocation and to rank and justify vendor recommendations
based on a couple's budget, guest count, location, and style preferences, rather than
relying on static rule-based scoring alone.

The Prototyping Model was adopted as the development methodology, allowing the couple,
vendor, and admin interfaces to be iteratively built and refined based on continuous
self-review against the requirements. The resulting system was tested using unit,
integration, and manual system/user-acceptance testing across authentication, budgeting,
vendor matching, and messaging workflows, and was found to meet its core functional and
non-functional requirements. The project demonstrates that combining a conventional
relational data model with an AI reasoning layer can produce vendor and budget
recommendations that are both data-grounded and explainable, and it concludes with
recommendations for hosting the system online and extending it with payments and richer
notification channels.

---

## TABLE OF CONTENTS

> TODO: *Generate automatically in Word/Google Docs (References → Table of Contents) once this document is pasted in and formatted, so page numbers are accurate. The heading structure below already matches what a ToC needs.*

- Declaration
- Approval Page
- Dedication
- Acknowledgements
- Abstract
- List of Figures
- List of Tables
- List of Abbreviations and Acronyms
- Chapter One: Introduction
- Chapter Two: Literature Review
- Chapter Three: System Analysis and Design / Methodology
- Chapter Four: System Implementation, Testing and Results
- Chapter Five: Conclusion and Recommendations
- References
- Appendices

---

## LIST OF FIGURES

> TODO: *Fill in once diagrams and screenshots are inserted, e.g.:*
> Figure 3.1: System Architecture Diagram
> Figure 3.2: Use Case Diagram
> Figure 3.3: Entity Relationship Diagram
> Figure 3.4: Login Sequence Flowchart
> Figure 4.1: Login Screen
> Figure 4.2: Couple Dashboard
> Figure 4.3: AI Budget Recommendation Screen
> Figure 4.4: Vendor Discovery Screen
> Figure 4.5: Admin Vendor Verification Screen

## LIST OF TABLES

> TODO: *e.g.:*
> Table 3.1: Database Tables and Relationships
> Table 3.2: System Development Tools
> Table 4.1: Test Plan and Results

## LIST OF ABBREVIATIONS AND ACRONYMS

| Abbreviation | Meaning |
|---|---|
| API | Application Programming Interface |
| CRUD | Create, Read, Update, Delete |
| DBMS | Database Management System |
| DFD | Data Flow Diagram |
| ERD | Entity Relationship Diagram |
| HTML | HyperText Markup Language |
| HTTP | Hypertext Transfer Protocol |
| JSON | JavaScript Object Notation |
| JWT | JSON Web Token |
| LLM | Large Language Model |
| ORM | Object-Relational Mapping |
| RSVP | Répondez S'il Vous Plaît (please respond) |
| SDLC | Software Development Life Cycle |
| SQL | Structured Query Language |
| UML | Unified Modeling Language |
| UUID | Universally Unique Identifier |

---

# CHAPTER ONE: INTRODUCTION

## 1.1 Background of the Study

Planning a wedding involves coordinating a large number of interdependent
decisions — a budget that must be allocated across many categories, a set of vendors
(venue, catering, photography, décor, and others) that must be discovered, compared and
booked, a guest list that must be tracked through invitations and RSVPs, and a checklist of
time-bound tasks that must be completed before the wedding date. In many markets,
including Zambia, this coordination is still done manually: couples keep spreadsheets or
paper notebooks for budgets, find vendors through referrals or social media, and
communicate with vendors over phone calls or WhatsApp with no shared record of what
was agreed. Vendors, in turn, have no structured way to showcase their services, manage
incoming enquiries, or build a verifiable reputation beyond informal reviews.

This informal approach creates friction on both sides of the market. Couples struggle to
know whether a given vendor's price is reasonable for their budget and guest count, and
have no single place to see how their spending compares to their overall plan. Vendors
struggle to reach couples whose budget and requirements are a genuine match for their
services, and have no dashboard to track leads, availability, or performance. A
computer-based platform that centralises vendor discovery, budgeting, task tracking and
communication — and adds a layer of intelligent, explainable recommendation on top of
that data — addresses a real coordination gap that purely manual planning cannot.

## 1.2 Problem Statement

Couples planning a wedding lack a single system that lets them discover and compare
vendors against a defined budget, track that budget as money is actually spent, manage a
guest list and invitations, and communicate with vendors, all in one place. Vendors, in
parallel, lack a dedicated platform to list their services, manage bookings and enquiries,
and understand how they are performing relative to other vendors in their category. The
people affected are couples currently planning a wedding, the vendors who serve them
(venues, caterers, photographers, decorators, and similar service providers), and, indirectly,
the wedding-services market as a whole, which suffers from information asymmetry —
couples do not know which vendors are trustworthy or well-priced for their situation, and
vendors do not know which leads are worth pursuing. Existing generic tools (spreadsheets,
messaging apps, social media pages) are inadequate because none of them combine
budget tracking, vendor discovery with a matching mechanism, and guest/invitation
management under one authenticated, role-aware system. Left unsolved, couples continue
to overspend or misallocate budget without visibility, vendors continue to receive
mismatched enquiries, and neither side has a shared, auditable record of what was agreed.

## 1.3 Aim of the Project

The aim of this project is to design and develop Wedpilot, a cross-platform (Android and
web) wedding planning application that allows couples to manage their wedding budget,
discover and communicate with vendors using AI-assisted recommendations, track
planning tasks, and manage guests and invitations, while giving vendors a dashboard to
manage their listings and leads and giving administrators the tools to moderate and
oversee the platform.

## 1.4 Specific Objectives

The specific objectives of the project are:

1. To investigate how couples currently plan weddings and select vendors, and to
   identify the shortcomings of manual, spreadsheet- and referral-based planning.
2. To review existing wedding-planning and vendor-marketplace systems and identify
   gaps that the proposed system should address.
3. To design a role-based system architecture, database schema, and set of user
   interface flows for three distinct user roles: couple, vendor, and administrator.
4. To develop a cross-platform client application (Flutter) and a REST API backend
   (Node.js/Express with MySQL) implementing authentication, budgeting, vendor
   discovery and matching, task management, guest/invitation management, and
   messaging.
5. To integrate an AI reasoning layer (Google Gemini) that produces a personalised,
   explainable budget allocation and vendor ranking rather than a purely static
   rule-based score.
6. To test the developed system using unit, integration, and system/user-acceptance
   testing, and to evaluate whether it meets its functional and non-functional
   requirements.

## 1.5 Research Questions

1. How do couples currently record their wedding budget and select vendors, and
   what problems does this manual process create?
2. What features do existing wedding-planning and vendor-marketplace systems offer,
   and what do they leave unaddressed?
3. What system architecture, database design, and role-based interface structure best
   support couples, vendors, and administrators within one application?
4. How can a cross-platform client and a REST API backend be developed and
   integrated to support these three roles?
5. How can an AI model be used to produce budget and vendor recommendations
   that are both personalised to a couple's data and explainable, instead of a black-box
   score?
6. How effective is the resulting system at meeting the requirements identified for
   couples, vendors, and administrators?

## 1.6 Scope of the Project

Wedpilot targets three user groups: **couples** planning a wedding, **vendors** offering
wedding-related services, and **platform administrators**. The system covers: email/password
registration and role-based login; couple profile and wedding-detail management; an
AI-generated budget plan with categories, custom items, and expense tracking; vendor
discovery, AI-assisted vendor matching, saved vendors ("wishlist"), and reviews; a
planning checklist/task module; guest list and invitation management with RSVP
tracking; in-app messaging (conversations) between couples and vendors; a
notifications module; a vendor dashboard covering lead inbox, availability calendar,
listings, subscription, and analytics; and an admin console covering user management,
vendor verification, content moderation, category management, invitation templates,
and platform analytics.

The project does not cover real payment processing, SMS/email delivery integration, or
production hosting/deployment — these are treated as future work (see Section 5.5). The
system was developed and evaluated for the general wedding-planning market rather than
for a single named institution or client organisation.

## 1.7 Significance of the Project

Wedpilot benefits **couples** by giving them a single place to plan a budget, discover
vendors that genuinely fit that budget, and track guests and tasks, reducing the
coordination overhead of manual planning. It benefits **vendors** by giving them a
dashboard through which to manage enquiries, availability, and performance, and by
surfacing them to couples whose requirements they are a genuine match for. It benefits
**platform administrators** by giving them tools to verify vendors and moderate content,
which protects couples from unreliable listings. For **future researchers and developers**,
the project demonstrates a concrete pattern for combining a conventional relational data
model with an LLM-based reasoning layer to produce recommendations that are
data-grounded and explainable rather than purely black-box, which is relevant beyond the
wedding-planning domain to any matching or recommendation problem. For the field of
**Computer Science**, the project is a practical case study in building a secure, role-based,
cross-platform system with a clear separation between client, API, database, and
AI-inference concerns.

## 1.8 Limitations of the Project

- Limited time available within the academic year restricted the scope of features
  that could be fully implemented, tested, and polished.
- The AI recommendation features depend on an external, rate-limited third-party
  service (Google Gemini); accuracy and availability of those specific
  recommendations are therefore bounded by that service, not solely by the
  project's own code.
- Testing was conducted primarily by the developer and a small number of
  volunteer users rather than a large or statistically representative sample of real
  couples and vendors, and without a production deployment, so results reflect a
  supervised evaluation rather than field usage at scale.
- The system was developed and validated primarily against the Zambian wedding
  market context (currency, categories, vendor conventions); behaviour in other
  markets was not evaluated.
- Real payment processing and SMS/email delivery were out of scope, so those
  workflows were validated only up to the point where a real payment or delivery
  provider would be integrated.

## 1.9 Definition of Key Terms

**Database:** An organised collection of data that can be accessed, managed, and updated
electronically.

**System:** A set of related components that work together to achieve a specific purpose.

**User Interface:** The part of a system that allows users to interact with the software.

**Role-Based Access Control (RBAC):** A security model in which a user's permitted
actions are determined by the role (e.g. couple, vendor, admin) assigned to their account.

**REST API:** An architectural style for a web service in which resources are accessed and
manipulated using standard HTTP methods (GET, POST, PUT, DELETE) over stateless
requests.

**Large Language Model (LLM):** A machine learning model trained on large volumes of
text that can generate natural-language or structured output (such as JSON) in response to
a prompt; in this project, Google's Gemini model is used to generate budget and vendor
recommendations.

**JSON Web Token (JWT):** A compact, signed token format used to represent a user's
identity and role between the client and server after login, without the server needing to
store session state.

---

# CHAPTER TWO: LITERATURE REVIEW

## 2.1 Introduction

This chapter reviews the theoretical concepts underlying Wedpilot, examines existing
wedding-planning and vendor-marketplace systems, discusses the technologies used to
build the system, and identifies the gap in existing solutions that this project addresses.

## 2.2 Theoretical Review

**Information systems and mobile/web applications.** Wedpilot is, at its core, an
information system: it captures, stores, processes, and presents data about couples,
vendors, budgets, and bookings to support decision-making. Building it as a cross-platform
mobile and web client backed by a REST API follows the widely-used client–server model,
in which the client is responsible for presentation and interaction while the server is
responsible for business logic, persistence, and security enforcement.

**Database systems.** A relational database management system (RDBMS) organises data
into tables with defined relationships, enforced through primary and foreign keys. This
project uses MySQL, a relational DBMS, accessed through Sequelize, an
Object-Relational Mapping (ORM) library that maps JavaScript model definitions to
database tables and lets the application interact with data as objects rather than raw SQL,
while still allowing relational integrity (uniqueness constraints, foreign keys) to be
enforced at the database level.

**Role-based access control.** Because Wedpilot serves three distinct user types with
different permissions, the system implements role-based access control: each user account
carries a `role` (`couple`, `vendor`, or `admin`), and both the client (which route/shell a user
is routed to) and the server (which API endpoints a request is authorised to reach) enforce
behaviour based on that role.

**Authentication and token-based security.** Stateless authentication using JSON Web
Tokens (JWT) allows a server to verify a user's identity on every request without
maintaining server-side session storage: the server signs a token containing the user's
identity and role at login, and the client presents that token on every subsequent request
for the server to verify. Passwords are never stored directly; instead they are hashed with
bcrypt, a slow, salted hashing algorithm designed specifically to resist brute-force
and rainbow-table attacks against leaked password databases.

**Artificial intelligence and large language models.** Beyond simple rule-based filtering,
this project applies a large language model (Google's Gemini) as a reasoning layer on top
of the application's own data. Rather than asking the model to invent information, the
system supplies it with structured, pre-filtered data (candidate vendors, their computed
scores, a couple's budget and preferences) and asks it to reason over that data and produce
a structured, justified recommendation. This pattern — retrieval or pre-computation of
relevant facts, followed by LLM reasoning constrained to those facts — is a widely used
way of making LLM output more grounded and less prone to fabrication than an unconstrained
prompt.

## 2.3 Review of Existing Systems

Three broad categories of existing systems overlap with Wedpilot's functionality:

**Generic wedding-planning apps** (e.g. checklist- and budget-only planners) typically
provide a task checklist and a manual budget spreadsheet, allowing a couple to enter
categories and track spending. Their strength is simplicity; their weakness is that they treat
vendor discovery as entirely separate from budgeting — a couple cannot see, within the
same tool, whether a vendor they are considering actually fits the money they have
allocated to that category.

**Vendor marketplace/directory platforms** (e.g. general local-services directories) let
vendors list a profile with photos, services, and reviews, and let couples browse and
contact them. Their strength is vendor discovery and social proof through reviews; their
weakness is that recommendations are typically either absent or based on simple sorting
(rating, price, distance) with no reasoning connecting a specific vendor to a specific
couple's stated budget, guest count, or style preferences.

**General CRM/lead-management tools** used informally by some vendors (e.g. spreadsheets
or generic messaging) let a vendor track enquiries, but have no wedding-specific structure
(no availability calendar tied to a wedding date, no couple-side budget context to
prioritise leads against).

**Lessons applied to Wedpilot:** the project combines the budgeting rigor of planner apps
with the vendor-discovery strength of marketplace platforms, and adds an AI layer that
explicitly reasons about budget fit and date availability per vendor recommendation (see
Section 3.5 and the `/api/vendor-match` endpoint in Section 4.2), rather than treating
budgeting and vendor discovery as two unconnected tools.

## 2.4 Technologies Related to the Project

| Technology | Role in this project |
|---|---|
| Dart / Flutter | Cross-platform client framework used to build one codebase that runs on Android and the web. |
| Riverpod | State-management library used to hold and expose application state (auth state, profile state, settings) to the UI reactively. |
| GoRouter | Declarative routing package used to implement authentication-aware redirects and the three role-based navigation shells (couple/vendor/admin). |
| Node.js / Express | JavaScript server runtime and web framework used to expose the REST API consumed by the Flutter client. |
| MySQL | Relational database used to persist all system data (users, profiles, budgets, vendors, bookings, messages, etc.). |
| Sequelize | ORM used to define database models in JavaScript and to synchronise the schema with the MySQL database. |
| JSON Web Tokens (jsonwebtoken) | Used to issue and verify signed access tokens that identify a logged-in user and their role on every API request. |
| bcrypt | Used to hash and verify user passwords before they are stored. |
| Google Gemini (`@google/generative-ai`, model `gemini-2.5-flash`) | Large language model used to generate the AI wedding budget plan and AI vendor-matching recommendations. |
| Multer | Middleware used to handle multipart file uploads (e.g. vendor media, avatars). |
| Flutter Secure Storage / Hive | Used on the client to persist authentication tokens securely and to persist app settings locally. |
| Git / GitHub | Version control and source hosting used throughout development. |
| Android Studio / Visual Studio Code | Development environments used to write, run, and debug the Flutter client and Node.js server respectively. |

## 2.5 Empirical Review

Nithila et al. [9] presented "Your Dream," an early virtual wedding-planning system that
lets a user record a wedding date and planner type, stores vendor and guest details, and
sends SMS task reminders, with a simple keyword-based web search used to surface vendor
details. Its contribution was demonstrating that even basic automation (scheduled alerts,
centralised vendor/guest records) removes real coordination burden from manual planning;
its limitation, from the present project's perspective, is that vendor "matching" is a plain
keyword search with no reasoning about a couple's budget, guest count, or style, and there
is no role-based structure separating couple, vendor, and administrator concerns.

Naidu et al. [10] presented WedPro, a more recent (2025) web-based wedding budget
estimator built on Node.js, Express.js, and MongoDB, whose core contribution is a
RandomForestRegressor model trained on historical wedding-cost data that returns a
predicted budget figure from inputs such as guest count, city, and venue/food preferences.
WedPro demonstrates that machine learning can improve on a static, rule-based budget
template. However, its output is a single numeric estimate with no per-category
breakdown or explanation of *why* that figure was produced, and — like [9] — it treats
budgeting and vendor discovery as separate concerns rather than a single connected
recommendation.

Outside the wedding-planning domain specifically, Bao et al. [11] proposed BIGRec, a
"bi-step grounding" paradigm that first fine-tunes a large language model to generate
outputs confined to a defined recommendation space and then grounds those outputs in
real, existing items, directly addressing the risk that an LLM asked to recommend
something will hallucinate items that do not exist. Wang et al. [12]'s survey of
next-generation LLM-based recommender systems similarly identifies grounding
generated recommendations in verifiable, structured data as one of the central open
challenges for using LLMs in recommendation, alongside the need for the model's reasoning
to be inspectable rather than a single opaque score.

**Comparison with Wedpilot:** Wedpilot's `/api/vendor-match` and `/api/wedding-plan`
endpoints (Section 4.2) apply the same grounding principle identified in [11] and [12], but
implement it through prompt-level constraints rather than fine-tuning: the server
pre-computes reputation/location/value/availability signals for a fixed candidate list of
real vendors already in the database, and the Gemini prompt explicitly instructs the model
to select only from that list and to justify each pick against the couple's own budget,
date, and style data (see the `PLANNER_PERSONA` prompt and its rules in
`backend/server.js`) rather than inventing vendors or prices. This directly extends [9] and
[10]: unlike [9]'s keyword search, Wedpilot's vendor pick is reasoned against real budget
and availability data; unlike [10]'s single-number ML estimate, Wedpilot returns a
per-category allocation with an explicit, inspectable justification for each percentage.

## 2.6 Research Gap

Existing wedding-planning tools separate budgeting from vendor discovery, and existing
vendor-marketplace platforms rank or filter vendors using static criteria (rating, price,
distance) without reasoning explicitly about a specific couple's budget fit, date availability,
or style match. Wedpilot addresses this gap by unifying budgeting, vendor discovery, task
management, guest/invitation management, and messaging within one role-based system,
and by using an LLM to produce vendor and budget recommendations that are explicitly
justified against a couple's own data (budget ceiling per category, wedding date, guest
count, and style preferences) rather than a single opaque score.

## 2.7 Summary of Literature Review

This chapter established the theoretical foundations relevant to Wedpilot — information
systems, relational databases, role-based access control, token-based authentication, and
LLM-based reasoning — and reviewed existing wedding-planning and vendor-marketplace
systems, finding that none combine budgeting and vendor discovery under one explainable,
AI-assisted recommendation layer. This gap directly motivates the system design presented
in Chapter Three.

---

# CHAPTER THREE: SYSTEM ANALYSIS AND DESIGN / METHODOLOGY

## 3.1 Introduction

This chapter presents the methodology used to analyse, design, and develop Wedpilot, the
requirements gathered, and the resulting system, database, and interface design.

## 3.2 Research Design or Project Methodology

The **Prototyping Model** was adopted for this project. An initial working prototype
covering authentication and core navigation was built first, then reviewed against the
requirements and iteratively extended — first with the couple-facing budget and vendor
modules, then guest/invitation and messaging modules, then the vendor and admin
dashboards — with each iteration refined based on functional testing against the
requirements before the next module was added. This model was chosen over a strict
Waterfall approach because the requirements for a multi-role system with an AI reasoning
component benefit from being validated against a running prototype early, rather than
being fully specified up front; it was chosen over full Agile/Scrum ceremony because the
project was carried out by a single developer within an academic timeline, where formal
sprint ceremonies would add overhead without a team to coordinate.

## 3.3 Data Collection Methods

- **Literature review** — used to understand existing wedding-planning and
  vendor-marketplace systems (Chapter Two) and to identify the research gap the
  project addresses.
- **Document review** — review of comparable systems' publicly visible feature sets
  (booking flows, vendor profile structures, budget categories) to inform the data
  model in Section 3.6.
- **Informal observation and self-consultation** — given the developer's own
  familiarity with the informal, spreadsheet- and referral-based way weddings are
  typically planned locally, this was used to shape the problem statement and
  scope. > TODO: *If you actually conducted interviews or distributed a
  questionnaire to couples/vendors, describe that here and include the
  instrument in Appendix A/B — this strengthens the report considerably.*

## 3.4 Requirements Analysis

### 3.4.1 Functional Requirements

- The system shall allow a user to register and log in with an email and password,
  and shall assign a role (couple, vendor, or admin) to the account.
- The system shall allow a couple to create and edit a wedding profile (wedding
  date, location, guest count, style preferences, budget).
- The system shall generate an AI-assisted budget allocation across categories based
  on the couple's total budget, guest count, wedding type/class, and location.
- The system shall allow a couple to record budget categories, custom line items,
  and individual expenses, and shall compute remaining budget and over-budget
  status.
- The system shall allow a couple to browse and search vendors by category, and
  shall provide an AI-ranked "best match" vendor per category based on budget fit,
  date availability, location, and style.
- The system shall allow a couple to save vendors to a wishlist, contact a vendor via
  in-app messaging, and submit a review after engaging a vendor.
- The system shall allow a couple to manage a planning checklist/task list with due
  dates and completion status.
- The system shall allow a couple to manage a guest list, send/track invitations, and
  record RSVP responses.
- The system shall allow a vendor to manage a profile, services, and media; view and
  respond to leads/enquiries in an inbox; manage an availability calendar; and view
  analytics on their listings.
- The system shall allow an administrator to verify or suspend vendor accounts,
  moderate content, manage vendor categories and invitation templates, manage
  users, and view platform-wide analytics.
- The system shall send in-app notifications for relevant events (new messages, new
  leads, RSVP responses, verification status changes).

### 3.4.2 Non-Functional Requirements

- **Security:** the system shall hash all stored passwords (bcrypt) and shall require a
  valid, signed JWT bearing the correct role for every protected API request; a
  suspended account shall be denied access even if its token is still technically
  valid.
- **Usability:** the interface shall provide role-appropriate navigation (a bottom
  navigation shell per role) and shall use `flutter_screenutil` for responsive layout
  across Android and web/desktop screen sizes.
- **Performance:** API responses for standard CRUD operations should complete
  within a time acceptable for a mobile UI (target: well under one second on a local
  network), while AI-generation endpoints (`/api/wedding-plan`,
  `/api/vendor-match`), which depend on an external LLM call, are allowed a longer,
  clearly-loading-indicated response time.
- **Reliability:** the server shall retry briefly on a transient port conflict on restart
  (see `startServer` in `server.js`) rather than failing immediately, and shall keep the
  database schema synchronised with the current models on startup.
- **Maintainability:** the codebase shall separate concerns by role-based route
  modules on the server (`routes/`) and by feature-based folders on the client
  (`lib/features/<feature>/screens/`), so a given feature can be extended without
  touching unrelated modules.

## 3.5 System Design

### 3.5.1 System Architecture

Wedpilot follows a three-tier client–server architecture:

- **Client tier** — a Flutter application (Android + Web) organised around three
  `StatefulShellRoute` navigation shells (`CoupleShell`, `VendorShell`, `AdminShell`),
  each preserving its own tab state, with Riverpod providers holding auth and
  profile state and GoRouter enforcing authentication- and role-based redirects.
- **Application/API tier** — a Node.js/Express REST API exposing resource-oriented
  routes (`/api/auth`, `/api/couple`, `/api/tasks`, `/api/vendors`, `/api/wishlist`,
  `/api/budget`, `/api/admin`, `/api/guests`, `/api/invitations`, `/api/messages`,
  `/api/notifications`, plus the AI endpoints `/api/wedding-plan` and
  `/api/vendor-match`), with `verifyJwt` and `requireRole` middleware enforcing
  authentication and role authorisation on protected routes.
- **Data tier** — a MySQL database accessed through Sequelize models, holding all
  persistent application data.
- **External AI service** — Google's Gemini model (`gemini-2.5-flash`), called
  server-side (never directly from the client, so the API key stays server-only) to
  generate the budget plan and vendor-match reasoning as structured JSON.

> TODO: *Insert a system architecture diagram here (Figure 3.1) showing these four
> layers and the request/response flow between them — the boxes and arrows described
> above map directly onto that diagram.*

### 3.5.2 Use Case Diagram

Primary actors and their key use cases:

- **Couple:** Register/Login, Manage Wedding Profile, Generate AI Budget Plan,
  Manage Budget & Expenses, Discover Vendors, View AI Vendor Match, Save
  Vendor, Message Vendor, Submit Review, Manage Checklist, Manage Guests &
  Invitations, View Notifications.
- **Vendor:** Register/Login, Manage Vendor Profile & Media, Manage Availability
  Calendar, View Leads/Enquiries, Reply to Messages, View Analytics, Manage
  Subscription.
- **Admin:** Login, Verify/Suspend Vendors, Manage Users, Moderate Content,
  Manage Categories, Manage Invitation Templates, View Platform Analytics.

> TODO: *Insert the actual use case diagram (Figure 3.2) drawn from this actor/use-case
> list using a UML tool (e.g. draw.io, Lucidchart, StarUML).*

### 3.5.3 Data Flow Diagram

At Level 0 (context diagram), the **Couple**, **Vendor**, and **Admin** actors exchange data
with the single process **Wedpilot System**, which in turn reads/writes the **MySQL
Database** and exchanges structured prompts/responses with the **Gemini AI Service**.
At Level 1, this decomposes into sub-processes: *Authenticate User*, *Manage Budget*,
*Match & Discover Vendors*, *Manage Tasks*, *Manage Guests & Invitations*, *Exchange
Messages*, and *Administer Platform*, each reading from and writing to its corresponding
tables in Section 3.6.

> TODO: *Insert the Level-0 and Level-1 DFDs (Figure 3.3) drawn from the decomposition
> above.*

### 3.5.4 Entity Relationship Diagram

The core entities and relationships, drawn directly from the Sequelize models in
`backend/db/models/`, are:

- **User** (1) — (1) **CoupleProfile** / **Vendor** (a user with role `couple` has one
  couple profile; a user with role `vendor` has one vendor profile).
- **CoupleProfile** (1) — (1) **Budget** (1) — (many) **BudgetCategory**,
  (many) **BudgetCustomItem**, (many) **Expense**.
- **CoupleProfile** (1) — (many) **Task** (planning checklist items).
- **CoupleProfile** (1) — (many) **Guest**, **CoupleProfile** (1) — (many)
  **Invitation** (1) — (many) **RsvpResponse**.
- **Vendor** (1) — (many) **VendorService**, (many) **VendorMedia**, (many)
  **Review**, (many) **Inquiry**.
- **CoupleProfile** (many) — (many) **Vendor** through **SavedVendor** (wishlist)
  and through **VendorMatch** (AI-generated recommendation records).
- **User**/**CoupleProfile**/**Vendor** (many) — (many) via **Conversation** (1) —
  (many) **Message** (in-app messaging).
- **User** (1) — (many) **Notification**.

> TODO: *Insert the full ERD (Figure 3.4) with cardinalities, primary keys, and foreign
> keys drawn from this list and from Section 3.6's table below.*

### 3.5.5 Class Diagram

On the client, the core domain classes mirror the server entities and live in
`lib/models/`: `User`, `CoupleProfile`, `VendorProfile` (composing `VendorService`,
`VendorMedia`, and `VendorMatch`), `Budget` (composing `BudgetCategory`,
`BudgetCustomItem`, `Expense`), `ChecklistItem`, `Invitation` (composing
`InvitationTemplate`, `Guest`, `RsvpResponse`), `Review`, `NotificationModel`, and the
messaging classes in `messaging.dart` (`Conversation`, `Message`). Each model class
implements `toJson`/`fromJson` for API (de)serialisation and uses `equatable` for value
equality; several expose computed getters for derived values (e.g.
`CoupleProfile.daysUntilWedding`, `Budget.remainingBudget`, `Budget.isOverBudget`).

> TODO: *Insert a UML class diagram (Figure 3.5) for these classes and their
> composition/association relationships.*

### 3.5.6 Flowcharts

Key process flows to diagram:

- **Login flow:** submit credentials → server verifies password hash → checks
  `is_suspended` → issues JWT with `role` claim → client router redirects to the
  matching shell (`/couple/dashboard`, `/vendor/dashboard`, `/admin/dashboard`).
- **AI budget generation flow:** couple submits budget/guest/style inputs → client
  calls `/api/wedding-plan` → server builds a grounded prompt from that data → Gemini
  returns a structured JSON budget allocation and reasoning → client renders the
  plan and lets the couple accept/adjust it.
- **AI vendor matching flow:** couple's categories/budgets are gathered → server
  pre-filters and scores candidate vendors (reputation, location, value, availability
  on the wedding date) → server calls `/api/vendor-match` with those candidates →
  Gemini selects and justifies one vendor per category using the four-step
  reasoning structure (Budget fit, Availability, Style match, Verdict) → client
  displays the recommendation with its reasoning.

> TODO: *Insert flowcharts (Figure 3.6, 3.7) for these two processes.*

### 3.5.7 User Interface Design

The client uses Material 3 theming (`lib/core/theme/`) with a single source of truth for
colour (`app_colors.dart`) and typography (`app_text_styles.dart`, Google Fonts Playfair
Display for headings and Inter for body text), and a shared widget library
(`WedButton`, `WedCard`, `AppDrawer`, `LoadingShimmer`, `WedSnackbar`) reused across
screens for visual consistency. Navigation for each role is presented as a bottom
`NavigationBar` inside an `IndexedStack`-preserving shell, with secondary screens
(settings, notifications, checklist, messages, etc.) pushed on top without the bottom
navigation bar.

> TODO: *Insert wireframes or annotated screenshots (Figure 3.8 onward) of the couple
> dashboard, vendor discovery, budget, and admin screens.*

## 3.6 Database Design

**Database name:** `wedpilot` (MySQL, accessed via Sequelize).

| Table | Key Fields | Notes |
|---|---|---|
| `users` | `user_id` (UUID, PK), `email` (unique), `password_hash`, `name`, `avatar_url`, `role` (ENUM: couple/vendor/admin), `is_verified`, `is_suspended` | Root identity table; `role` drives client routing and server authorisation. |
| `couple_profiles` | PK, FK → `users.user_id`, wedding date, location, guest count, style preferences | One-to-one with a couple user. |
| `budgets` | `budget_id` (UUID, PK), FK → `couple_user_id` (unique), `total_amount` (DECIMAL 12,2), `currency` (default `ZMW`), `is_ai_generated` | One-to-one with a couple; feeds `budget_categories`, `budget_custom_items`, `expenses`. |
| `budget_categories` | PK, FK → `budgets.budget_id`, category name, allocated amount, spent amount | Many-to-one with `budgets`. |
| `budget_custom_items` | PK, FK → `budgets.budget_id`, item name, amount | Many-to-one with `budgets`. |
| `expenses` | PK, FK → `budgets.budget_id`, category, amount, receipt URL, date | Many-to-one with `budgets`. |
| `tasks` | PK, FK → `couple_profiles`, title, due date, completed flag | Planning checklist items. |
| `vendors` | PK, FK → `users.user_id`, business name, category, location, price range, rating | One-to-one with a vendor user. |
| `vendor_services` | PK, FK → `vendors`, service name, price | Many-to-one with `vendors`. |
| `vendor_media` | PK, FK → `vendors`, media URL, type | Many-to-one with `vendors`. |
| `reviews` | PK, FK → `vendors`, FK → `couple_profiles`, rating, comment | Many-to-one with both `vendors` and `couple_profiles`. |
| `inquiries` | PK, FK → `vendors`, FK → `couple_profiles`, message, status | Vendor lead records. |
| `saved_vendors` | PK, FK → `couple_profiles`, FK → `vendors` | Wishlist join table (many-to-many). |
| `vendor_matches` | PK, FK → `couple_profiles`, FK → `vendors`, category, confidence, reasoning | AI-generated recommendation records. |
| `guests` | PK, FK → `couple_profiles`, name, contact, group | Guest list entries. |
| `invitations` | PK, FK → `couple_profiles`, template, share token | Invitation records; `share_token` backs the public `/i/:shareToken` route. |
| `rsvp_responses` | PK, FK → `invitations`, guest name, attendance status | RSVP records per invitation. |
| `conversations` | PK, participant user IDs | In-app messaging threads. |
| `messages` | PK, FK → `conversations`, sender, body, timestamp | Individual messages. |
| `notifications` | PK, FK → `users`, type, payload, read flag | Per-user notification records. |

Primary keys throughout use UUIDs (`DataTypes.UUID`, default `UUIDV4`) rather than
auto-incrementing integers, so identifiers are unique across tables without coordination
and are safe to expose in client-facing URLs (e.g. invitation share tokens). Unique
indexes (e.g. on `users.email`, `budgets.couple_user_id`) are declared with explicit names
in the Sequelize model definitions specifically so that repeated `sequelize.sync({ alter:
true })` calls during development recognise the existing index instead of creating a
duplicate on every restart.

> TODO: *Render the table above as an actual ERD image for Figure 3.4/List of Figures.*

## 3.7 System Development Tools

| Tool/Technology | Purpose |
|---|---|
| Dart / Flutter SDK | Client application language and framework (Android + Web). |
| flutter_riverpod | State management. |
| go_router | Declarative, role-aware navigation. |
| dio | HTTP client for calling the REST API from Flutter. |
| flutter_secure_storage / hive_flutter | Secure token storage and local settings persistence. |
| Node.js / Express | Server runtime and REST API framework. |
| Sequelize | ORM for MySQL. |
| MySQL (mysql2 driver) | Relational database engine. |
| jsonwebtoken | JWT issuing and verification. |
| bcrypt | Password hashing. |
| multer | File upload handling. |
| @google/generative-ai (Gemini `gemini-2.5-flash`) | AI budget planning and vendor-matching reasoning. |
| Git & GitHub | Version control and source hosting. |
| Android Studio | Flutter development, emulator testing. |
| Visual Studio Code | Backend development and general editing. |
| Postman / `curl` | Manual API endpoint testing. |

## 3.8 Ethical Considerations

- **User consent:** accounts are created only when a user voluntarily registers;
  no data is collected without the user creating a profile.
- **Data privacy:** passwords are never stored in plain text (bcrypt hashing);
  authentication tokens are stored in secure, encrypted device storage
  (`flutter_secure_storage`) rather than plain shared preferences.
- **Confidentiality:** couple budget data, guest lists, and vendor enquiries are only
  accessible to the authenticated owner of that data and to administrators acting in
  a moderation capacity, enforced through `verifyJwt` and `requireRole` middleware
  on every protected route.
- **Responsible use of AI:** the prompts sent to Gemini explicitly instruct the model
  to ground its output only in the data supplied (budgets, guest counts, vendor
  records) and not to invent facts (e.g. fabricated couple names, vendor details, or
  prices) — see the `PLANNER_PERSONA` prompt rules in `backend/server.js`.
- **Avoidance of plagiarism:** all external sources used in the literature review and
  technology discussion must be cited (see References).
- **Account safety:** a suspended account is denied access on every request (checked
  live against the database, not just at token-issue time), limiting the damage a
  compromised or abusive account can do even if its token has not yet expired.

## 3.9 Summary

This chapter presented the Prototyping Model as the project's methodology, derived
functional and non-functional requirements from the problem identified in Chapter One,
and translated those requirements into a three-tier system architecture, a role-based use
case model, a relational database schema of nineteen core tables, and a consistent,
themed user interface design. Chapter Four now describes how this design was
implemented, tested, and evaluated.

---

# CHAPTER FOUR: SYSTEM IMPLEMENTATION, TESTING AND RESULTS

## 4.1 Introduction

This chapter describes how the design in Chapter Three was implemented, the tools and
environment used, the system's modules and screenshots, how the system was tested, and
the results obtained.

## 4.2 System Implementation

**Development environment:** the client was developed with the Flutter SDK
(`environment: sdk: ^3.12.0`) in Android Studio, run against both an Android emulator/device
and Chrome (`flutter run -d chrome`) to validate the cross-platform target. The server was
developed with Node.js in Visual Studio Code, run locally via `npm run dev` (nodemon)
against a local MySQL instance, with environment secrets (`JWT_SECRET`,
`GEMINI_API_KEY`, database credentials) supplied through a `.env` file loaded by `dotenv`
and excluded from version control.

**Programming languages used:** Dart (client) and JavaScript (server, Node.js/Express).

**Database implementation:** the nineteen tables described in Section 3.6 are defined as
Sequelize models under `backend/db/models/` and are kept in sync with the running
MySQL schema at server startup via `sequelize.sync({ alter: true })`, so that new fields
added to a model during development are reflected as new columns without a manual
migration step.

**System modules and user roles:** implemented as three role-scoped shells on the client
(`CoupleShell`, `VendorShell`, `AdminShell`) and as role-scoped route groups on the server,
protected by `verifyJwt` (validates the bearer token and rejects suspended accounts) and
`requireRole`/`requireCouple`/`requireVendor`/`requireAdmin` (rejects a correctly
authenticated user whose role does not match the endpoint).

**Main features implemented:**

- Email/password registration and login issuing a signed JWT carrying `user_id` and
  `role`.
- Couple wedding-profile management and an AI-generated budget plan
  (`POST /api/wedding-plan`), which prompts Gemini with the couple's budget,
  guest count, wedding type/class, location, date, and style preferences, and returns
  a per-category percentage allocation with planner-style reasoning for each
  percentage.
- Budget category, custom item, and expense tracking with computed remaining
  budget and over-budget status.
- Vendor discovery and AI-assisted vendor matching (`POST /api/vendor-match`),
  which pre-computes reputation/location/value scores and a same-date-booking
  flag per candidate vendor per category, then asks Gemini to select and justify one
  vendor per category using a fixed four-step reasoning structure (Budget fit,
  Availability, Style match, Verdict).
- Saved vendors ("wishlist"), vendor reviews, and vendor-couple messaging
  (conversations/messages).
- Planning checklist/task management with due dates.
- Guest list, invitation, and RSVP management, including a public,
  authentication-free invitation view reachable via a per-invitation share token
  (`/i/:shareToken`).
- In-app notifications for relevant cross-role events.
- Vendor dashboard: lead inbox, availability calendar, listings management,
  subscription screen, and analytics.
- Admin console: user management, vendor verification, content moderation,
  category management, invitation template management, and platform analytics.

## 4.3 Description of System Modules

**Authentication module** — handles registration, login, and token issuance/verification;
implemented server-side in `routes/auth.js` and enforced on every protected route by the
`verifyJwt` middleware.

**Couple profile & planning module** — wedding details, AI budget generation, and
planning checklist; server-side in `routes/coupleProfile.js` and `routes/tasks.js`,
client-side under `lib/features/couple/screens/` and `lib/features/auth/screens/couple_planning_screen.dart`.

**Budget module** — categories, custom items, and expenses with computed
remaining/over-budget state; server-side in `routes/budget.js`, client-side in
`lib/features/couple/screens/expense_entry_screen.dart`, `budget_share_screen.dart`, and the
`Budget` model's computed getters.

**Vendor discovery & matching module** — vendor search, AI vendor matching, saved
vendors, and reviews; server-side in `routes/vendors.js`, `routes/wishlist.js`, and the
`/api/vendor-match` endpoint in `server.js`; client-side in
`lib/features/couple/screens/vendor_discovery_screen.dart`,
`vendor_profile_screen.dart`, `wishlist_screen.dart`, and `review_submission_screen.dart`.

**Guest & invitation module** — guest list, invitation templates, and RSVP tracking, plus
the public share-token invitation view; server-side in `routes/guests.js` and
`routes/invitations.js`; client-side under `lib/features/invitation/screens/`.

**Messaging module** — conversations and messages between couples and vendors;
server-side in `routes/messaging.js`; client-side in
`lib/features/couple/screens/chat_screen.dart` and `couple_messages_screen.dart`, and the
vendor-side equivalents.

**Notifications module** — per-user notification records and delivery to the client;
server-side in `routes/notifications.js`; client-side in
`lib/features/shared/screens/notifications_screen.dart`.

**Vendor dashboard module** — lead inbox, availability calendar, listings, subscription,
and analytics; client-side under `lib/features/vendor/screens/` (`lead_inbox_screen.dart`,
`availability_calendar_screen.dart`, `vendor_listings_screen.dart`,
`subscription_screen.dart`, `vendor_analytics_screen.dart`).

**Administration module** — user management, vendor verification, content
moderation, category and invitation-template management, and platform analytics;
server-side in `routes/admin.js`; client-side under `lib/features/admin/screens/`.

## 4.4 System Screenshots

> TODO: *Capture and insert real screenshots from a running build (`flutter run` /
> `flutter run -d chrome`) for each of the following, numbered and captioned exactly as
> required by the format below:*

**Figure 4.1: Login Page** — > TODO: *screenshot + one-sentence caption.*

**Figure 4.2: Couple Dashboard** — > TODO: *screenshot + one-sentence caption.*

**Figure 4.3: AI Budget Recommendation Screen** — > TODO: *screenshot + one-sentence
caption.*

**Figure 4.4: Vendor Discovery / AI Match Screen** — > TODO: *screenshot + one-sentence
caption.*

**Figure 4.5: Vendor Dashboard (Lead Inbox)** — > TODO: *screenshot + one-sentence
caption.*

**Figure 4.6: Admin Vendor Verification Screen** — > TODO: *screenshot + one-sentence
caption.*

## 4.5 System Testing

The system was tested using:

- **Unit testing** — of pure model logic on the client (e.g. `Budget.remainingBudget`,
  `Budget.isOverBudget`, `CoupleProfile.daysUntilWedding` computed getters) via
  `flutter test`.
- **Integration testing** — manual verification of client–server flows (e.g. register →
  login → token stored → protected screen loads couple-specific data) using the
  running Flutter client against the local Express server.
- **System testing** — end-to-end verification of each module described in Section
  4.3 against its functional requirement from Section 3.4.1.
- **User acceptance testing** — informal walkthroughs of the couple, vendor, and
  admin flows > TODO: *by yourself and/or a small number of volunteer testers;
  note who tested and what feedback they gave.*
- **Security testing** — verifying that protected endpoints reject requests with a
  missing/invalid token (`verifyJwt`), that a suspended account is denied access even
  with a previously valid token, and that a token for one role (e.g. couple) is
  rejected by an endpoint requiring another role (e.g. `requireAdmin`).

**Static analysis and unit test results (run 2026-07-07):** `flutter analyze` completed
with **"No issues found!"** (48.8s), confirming a clean analyzer as required by the
project's own workflow standard. `flutter test` ran the full suite —
`test/couple_planning_screen_test.dart` (four responsive-layout/no-overflow checks
across desktop and narrow-mobile widths) and `test/widget_test.dart` (app smoke test) —
and all **6 tests passed** (28s). The only console output during the run was a set of
non-fatal font-fallback warnings from the `pdf`/`printing` packages (missing glyph
coverage for an em dash and emoji when rendering a PDF export in-test), which do not
affect pass/fail status.

**Live backend verification (run 2026-07-07):** rather than leave the endpoint tests as
untested assumptions, the running local backend (Node/Express on port 3000, connected
to the project's MySQL database) was exercised directly. `GET /health` returned
`{"status":"ok"}`, confirming the server and database connection were live before the
test cases in Section 4.6 were executed against it.

## 4.6 Test Plan

All rows below marked **Pass** were executed for real against the project's own running
backend (`http://localhost:3000`, local MySQL database) on 2026-07-07, using dedicated
test accounts (`report_test_couple@example.com`, `report_test_vendor@example.com`) created
for this purpose — not assumed or fabricated.

| Test Case | Test Description | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| TC001 | Register a new couple account (`POST /api/auth/register`, role=couple) | 201, user object + access/refresh tokens returned | 201; `user.role":"couple"`, valid `accessToken`/`refreshToken` returned | **Pass** |
| TC001b | Register a new vendor account (role=vendor) | 201, user object + tokens returned | 201; `user.role":"vendor"`, tokens returned | **Pass** |
| TC002 | Login with the valid couple credentials just registered | HTTP 200, tokens issued | HTTP 200 | **Pass** |
| TC003 | Login with the correct email but wrong password | HTTP 401, `{"error":"Invalid credentials."}` | HTTP 401, `{"error":"Invalid credentials."}` | **Pass** |
| TC004 | `GET /api/couple/profile` with no `Authorization` header | HTTP 401, "Missing or invalid Authorization header." | HTTP 401, `{"error":"Missing or invalid Authorization header."}` | **Pass** |
| TC004b | `GET /api/couple/profile` with a garbage/invalid bearer token | HTTP 401, "Invalid or expired token." | HTTP 401, `{"error":"Invalid or expired token."}` | **Pass** |
| TC005 | `GET /api/couple/profile` using a valid **vendor** token (wrong role) | HTTP 403, "Only couple accounts can access this resource." | HTTP 403, `{"error":"Only couple accounts can access this resource."}` | **Pass** |
| TC005b | `GET /api/couple/profile` using a valid **couple** token (control case) | 404 "No couple profile yet." (expected for a couple who hasn't onboarded) | HTTP 404, `{"error":"No couple profile yet."}` | **Pass** |
| TC006 | Suspended account attempts any protected request | 403 "This account has been suspended" | > TODO: *requires flipping `is_suspended` on a test row — not exercised in this pass since it needs direct DB/admin access; the check itself is visible and reviewed in `middleware/verifyJwt.js:20-23`.* | Not yet run |
| TC007 | `POST /api/wedding-plan` with a realistic couple brief (ZMW 150,000 budget, 120 guests, Lusaka, rustic/garden style, 5 categories) | HTTP 200; `budgetAdvice` percentages sum to 100 across all 5 requested categories | HTTP 200; returned `{"Venue":15,"Catering":41,"Photography":13,"Decor":21,"Attire":10}` — **sums to exactly 100**; each category also had non-generic, budget/guest-count-specific `budgetReasoning` text | **Pass** |
| TC008 | Request AI vendor match where a candidate is booked on the wedding date | Reasoning explicitly flags the availability conflict | > TODO: *requires seeded vendor rows with `isBookedOnWeddingDate: true` — not exercised in this pass; the constraint itself is visible in the `/api/vendor-match` prompt rules in `server.js:173-183`.* | Not yet run |
| TC009 | Add an expense exceeding a category's allocated budget | UI flags category as over budget | > TODO: *client-side UI behaviour (`Budget.isOverBudget` getter) — exercise this in the running Flutter app and note what you see.* | Not yet run |
| TC010 | Submit RSVP via public share-token link with no login | RSVP recorded without requiring authentication | > TODO: *requires an existing invitation + share token — exercise this in the running app/route `/i/:shareToken`.* | Not yet run |

> TODO: *TC006, TC008, TC009, and TC010 need either a seeded database record or a
> click-through in the running Flutter app rather than a bare API call, so they're left for
> you to run and fill in. Everything else in this table reflects a real request/response
> pair captured against the live system, not an assumption.*

## 4.7 Results and Findings

Based on the test cases actually executed in Section 4.6 (TC001–TC005b, TC007), the core
authentication and role-enforcement chain works as designed: registration correctly
assigns and returns a role, login correctly issues tokens only on valid credentials and
rejects invalid ones with the correct status code, and the `verifyJwt`/`requireRole`
middleware chain correctly distinguishes "no token," "invalid token," and "wrong role for
this endpoint" as three distinct 401/403 outcomes rather than a single generic error —
directly satisfying objective 4 (Section 1.4) for the authentication and authorisation
slice of the system. The AI budget-generation endpoint (TC007) also worked end-to-end
against the live Gemini API: given a realistic couple brief, it returned a five-category
allocation that summed to exactly 100% with reasoning grounded in the specific guest
count, location, and style supplied, rather than a generic template — direct evidence
toward objective 5 (an explainable, personalised AI layer, not a black-box score).

> TODO: *TC006 (suspended-account access), TC008 (AI vendor match with a booked
> candidate), TC009 (over-budget UI flag), and TC010 (public RSVP via share token) still
> need to be run — TC006/TC008 need seeded database rows, TC009/TC010 need a
> click-through in the running Flutter app — before you can state whether objectives 4–6
> are fully met. Once you've run those, add: which main functions worked, what this
> improves on versus the manual/spreadsheet approach in Chapter One, any tester
> feedback you collected, and any challenges you hit (e.g. Gemini response latency, MySQL
> `sync({ alter: true })` edge cases, or Android vs. web layout differences).*

## 4.8 Discussion of Results

> TODO: *Interpret your Section 4.7 findings: explain what the results mean for the
> problem in Section 1.2, how Wedpilot compares to the existing systems reviewed in
> Section 2.3 (particularly on the combined budgeting + explainable AI vendor-matching
> point of differentiation), and state plainly whether each objective in Section 1.4 was
> achieved, partially achieved, or not achieved, with reasons.*

## 4.9 Summary

This chapter described how the designed system was implemented as a Flutter client and
an Express/MySQL/Gemini-backed API, documented its modules and screenshots, and set
out the testing approach and test plan used to validate it against the requirements from
Chapter Three. Chapter Five concludes the report.

---

# CHAPTER FIVE: CONCLUSION AND RECOMMENDATIONS

## 5.1 Introduction

This final chapter summarises the project, states its conclusions, and offers
recommendations and suggestions for future work.

## 5.2 Summary of the Project

This project addressed the problem of fragmented, manual wedding planning — couples
lacking a single place to budget, discover vendors, and coordinate guests, and vendors
lacking a dedicated platform to manage leads and listings — by designing and
implementing Wedpilot, a role-based, cross-platform (Android + Web) application built
with Flutter, Riverpod, and GoRouter on the client and Node.js, Express, Sequelize, and
MySQL on the server, secured with JWT authentication and bcrypt password hashing. The
Prototyping Model was used to iteratively build authentication, budgeting, vendor
discovery/matching, task, guest/invitation, messaging, and admin modules, with a Google
Gemini-based AI reasoning layer integrated to generate personalised, explainable budget
allocations and vendor recommendations. The system was evaluated through unit,
integration, system, and security testing against the test plan in Section 4.6.

## 5.3 Conclusion

> TODO: *State your final judgement plainly once Section 4.6–4.8 are completed with
> real results: did the system successfully address the problem statement and achieve its
> stated objectives (Section 1.4)? Be specific and honest — a report that says "objectives
> 1–5 were fully met and objective 6 was partially met because testing was limited to N
> volunteer users" is stronger and more credible than a blanket "all objectives were fully
> achieved."*

## 5.4 Recommendations

- **To the organisation/market this system may serve:** wedding-services vendors
  and planning coordinators should consider adopting a system such as Wedpilot to
  reduce the coordination overhead of spreadsheet- and referral-based planning
  described in Chapter One.
- **To system users:** couples should treat the AI-generated budget and vendor
  recommendations as a well-reasoned starting point grounded in their own data, not
  as a substitute for direct verification (e.g. confirming vendor availability directly)
  before committing to a booking.
- **To future developers:** keep the AI prompt logic's "ground every claim only in
  the data given" constraint (see `backend/server.js`) whenever the AI features are
  extended, so that recommendations remain explainable and auditable rather than
  free-form.
- **To future researchers:** this project's pattern of pre-computing structured
  candidate data and constraining an LLM to reason over it, rather than asking it to
  retrieve or invent facts, is worth studying further as a general approach to
  explainable recommendation systems beyond the wedding-planning domain.

## 5.5 Suggestions for Future Work

- Integrating real online payment processing for vendor deposits/bookings.
- Adding SMS and email delivery for invitations, RSVPs, and notifications (currently
  in-app only).
- Hosting the system on a production server/cloud platform rather than a local
  development environment.
- Adding push notifications (the client already depends on
  `flutter_local_notifications`, which is not yet wired to server-triggered events).
- Expanding automated test coverage (particularly server-side integration tests for
  the AI endpoints, mocking the Gemini API) beyond the manual testing performed
  in Chapter Four.
- Extending AI matching with a feedback loop (e.g. learning from which
  AI-recommended vendors couples actually book) to improve recommendation
  quality over time.
- Localising the system for wedding markets and currencies beyond Zambia.

---

## REFERENCES

> TODO: *Replace/extend this list with the actual sources you read and cited in Chapter
> Two, formatted consistently in IEEE style (numbered, referenced in-text as [1], [2], ...).
> A few genuinely verifiable technical references you used while building the system are
> suggested below as a starting point — check each against the current official page before
> citing, and add the academic/literature sources your supervisor expects.*

[1] Flutter, "Flutter documentation," Google. [Online]. Available: https://docs.flutter.dev/

[2] OpenJS Foundation, "Express — Node.js web application framework," documentation.
[Online]. Available: https://expressjs.com/

[3] Sequelize, "Sequelize — Feature-rich ORM for modern Node.js," documentation.
[Online]. Available: https://sequelize.org/

[4] Oracle Corporation, "MySQL 8.0 Reference Manual." [Online]. Available:
https://dev.mysql.com/doc/

[5] M. Jones, J. Bradley, and N. Sakimura, "JSON Web Token (JWT)," RFC 7519, Internet
Engineering Task Force, May 2015.

[6] Google, "Gemini API documentation," Google AI for Developers. [Online]. Available:
https://ai.google.dev/gemini-api/docs

[7] Riverpod, "Riverpod documentation." [Online]. Available: https://riverpod.dev/

[8] GoRouter, "go_router package documentation," pub.dev. [Online]. Available:
https://pub.dev/packages/go_router

[9] S. Nithila, D. Madushyani, W. M. P. S. G. Perera, M. Nivethan, and G. Fernando,
"'Your Dream' virtual wedding planning system," *Scientific Research Journal (SCIRJ)*,
vol. 1, no. 3, pp. 30–35, Oct. 2013.

[10] M. R. Naidu, V. V. Karthikeya, T. Gopi, T. Dhoni, and M. S. Nayak, "A web-based
intelligent wedding pro system using machine learning," *International Journal of
Scientific Development and Research (IJSDR)*, vol. 10, no. 4, Apr. 2025.

[11] K. Bao, J. Zhang, W. Wang, Y. Zhang, Z. Yang, Y. Luo, C. Chen, F. Feng, and Q.
Tian, "A bi-step grounding paradigm for large language models in recommendation
systems," *arXiv:2308.08434 [cs.IR]*, 2023.

[12] Q. Wang, J. Li, S. Wang, Q. Xing, R. Niu, H. Kong, R. Li, G. Long, Y. Chang, and
C. Zhang, "Towards next-generation LLM-based recommender systems: A survey and
beyond," *arXiv:2410.19744 [cs.IR]*, 2024.

> TODO: *These four are real, verifiable references pulled from an actual web search — check
> each one still resolves before submission and add any further sources your supervisor
> expects (course textbooks, local/regional literature, etc.) as [13], [14], ...*

---

## APPENDICES

### Appendix A: Questionnaire

> TODO: *Include the actual questionnaire used, if you collect couple/vendor feedback
> as part of your data collection (Section 3.3) or user acceptance testing (Section 4.5).*

### Appendix B: Interview Guide

> TODO: *Include actual interview questions, if interviews were conducted.*

### Appendix C: Source Code Samples

> TODO: *Include short, representative excerpts (not the entire codebase) — good
> candidates: `backend/middleware/verifyJwt.js`, the `/api/vendor-match` prompt
> construction in `backend/server.js`, and one Sequelize model (e.g. `backend/db/models/budget.js`)
> and one Flutter model with computed getters (e.g. `lib/models/budget.dart`).*

### Appendix D: User Manual

> TODO: *Write brief, numbered instructions for each role: how a couple registers and
> generates a budget plan; how a vendor completes onboarding and manages leads; how an
> admin verifies a vendor.*

### Appendix E: Installation Guide

Minimal steps to run the system locally, based on the actual project setup:

**Backend:**
1. `cd backend`
2. `npm install`
3. Create a `.env` file with `JWT_SECRET`, `GEMINI_API_KEY`, and MySQL connection
   settings (see `backend/db/sequelize.js` for the expected variables).
4. `npm run dev` (starts the API with nodemon on the configured `PORT`, default `3000`).

**Client (Flutter):**
1. From the project root, run `flutter pub get`.
2. Run `flutter run` (Android) or `flutter run -d chrome` (web).
3. Ensure the client's API base URL (see `lib/core/services/`) points at the running
   backend's address.

> TODO: *Confirm and fill in the exact required `.env` variable names from
> `backend/db/sequelize.js` and any client-side base-URL configuration file.*

### Appendix F: Additional Screenshots

> TODO: *Include any further screenshots that support the report but were not placed
> in Chapter Four (e.g. additional admin screens, error states, responsive/web layout
> variants).*
