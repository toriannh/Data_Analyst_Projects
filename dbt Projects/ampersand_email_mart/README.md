# ampersand_email_mart  
**Email Analytics Mart (dbt + Snowflake) with Tableau Reporting**

This repository is a production-style analytics engineering project that builds an email analytics mart in **Snowflake** using **dbt (Core + dbt Cloud)** and exposes curated datasets for **Tableau** reporting. It includes a daily refresh workflow, standardized modeling layers (RAW → STAGING → MARTS), and a practical data quality/auditing framework (tests + audit views). While this is an interview project using **mock Marketing Cloud-style events**, the implementation mirrors real-world patterns you’d expect in a client environment: repeatable builds, documented models, and quality checks designed for stakeholder trust.

---

## Why this exists

Email analytics often suffers from inconsistent event semantics, unclear grains, and unreliable joins between campaigns and people (contacts/leads). This project demonstrates how I would structure an **email mart** so that:
- reporting is consistent across tools and teams,
- definitions are centralized (dbt models + docs),
- data quality issues are visible (tests + DQ/audit views),
- and daily refreshes are automated via dbt Cloud.

---

## Tech stack

- **Warehouse:** Snowflake  
- **Transformation:** dbt Core (local dev) + dbt Cloud (scheduled job)  
- **Languages:** SQL (+ dbt Jinja/macros)  
- **BI Layer:** Tableau  
- **Documentation:** `dbt docs generate` (served from dbt Cloud or locally)

---

## Architecture overview

The project follows a standard dbt layering approach:

```

RAW (sources / seeded mock inputs)
↓
STAGING (clean + standardized columns, typed fields, conformed IDs)
↓
MARTS (facts/dims for analytics + DQ coverage models)
↓
AUDIT (exception views for monitoring issues)
↓
TABLEAU (dashboards connected to MARTS models)

````

### Where dbt fits
- **Seeds / RAW inputs** provide campaign, person, and event-like data (mocked for this project).
- **Staging models** normalize and standardize those inputs.
- **Mart models** build analytics-ready facts/dimensions.
- **Audit models** surface issues (duplicates, grain violations, orphan campaign IDs, etc.).
- **Docs** describe the lineage and definitions for handoff to stakeholders.

### What Tableau connects to
Tableau should connect to the **MARTS** schema/models (and optionally **AUDIT** views for QA dashboards). The primary reporting tables are:
- `fct_email_events_daily` (daily rollups)
- `dim_campaign`
- `dim_person`
- `fct_campaign_membership`
- (optionally) `fct_email_events` for event-level drilldowns

---

## Data model summary

### Core dimensions
- **`DIM_CAMPAIGN`**  
  Canonical campaign attributes used across reporting (one row per `campaign_id`).

- **`DIM_PERSON`**  
  A conformed “person” dimension that unifies **Contacts** and **Leads** into a single entity.  
  Includes `person_type` (accepted values: `CONTACT`, `LEAD`).

### Core facts
- **`FCT_EMAIL_EVENTS` (event-level fact)**  
  **Grain:** one row per email event (`event_id`).  
  Contains event activity (send/delivered/open/click/bounce/unsubscribe) tied to campaign and person keys.

- **`FCT_EMAIL_EVENTS_DAILY` (daily aggregated fact)**  
  **Grain:** daily aggregation of email activity (designed for fast dashboarding).  
  Commonly used for trend charts and KPI tiles.

- **`FCT_CAMPAIGN_MEMBERSHIP`**  
  **Grain:** one row per campaign-member relationship.  
  Bridges campaign membership to unified people (contacts/leads).

### Keys & joins (typical usage)
- Join facts → campaign: `campaign_id`
- Join facts → person: `person_id`
- Campaign membership joins to both dimensions: `campaign_id`, `person_id`

---

## Key models (tables/views)

### Facts & dimensions (MARTS)
- **`marts.fct_email_events`**  
  Event-level table for detailed analysis, QA, and drill-through.

- **`marts.fct_email_events_daily`**  
  Daily rollups for KPI cards, time series, and dashboard performance.

- **`marts.dim_campaign`**  
  Campaign dimension used to filter/group metrics consistently.

- **`marts.dim_person`**  
  Unified person dimension with `person_type` = `CONTACT` or `LEAD`.

- **`marts.fct_campaign_membership`**  
  Campaign-member bridge enabling audience analytics and membership coverage checks.

### Data quality coverage (MARTS)
- **`marts.dq_campaign_id_coverage`**  
  Coverage logic for campaign IDs across facts/membership (helps quantify missing/unknown campaign mappings).

- **`marts.dq_orphan_campaign_ids`**  
  Identifies campaign IDs appearing in event activity that do not exist in the campaign dimension (or vice versa, depending on rule).

### Audit views (AUDIT)
- **`audit.audit__event_id_duplicates`**  
  Detects duplicate `event_id` values (violates event grain).

- **`audit.audit__daily_grain_violations`**  
  Validates that daily aggregation grain is preserved (no duplicate keys at the daily level).

- **`audit.audit__orphan_campaigns_14d`**  
  Focuses orphan campaign behavior in a recent time window to support operational monitoring.

---

## Scheduling & orchestration (dbt Cloud)

This project is designed to run as a scheduled daily dbt Cloud job with three main stages:

1. **Generate mock Marketing Cloud events**

```bash
dbt run-operation insert_mock_marketing_cloud_events
````

2. **Build daily-tagged models + run tests**

```bash
dbt build --select tag:daily
```

3. **Generate documentation**

```bash
dbt docs generate
```

**Notes**

* The mock event macro exists to simulate a realistic event stream for demo/interview purposes.
* The `tag:daily` selector keeps the scheduled job focused and predictable (build only what needs daily refresh + tests).

---

## Data quality & testing strategy

The repo uses a mix of **schema tests** and **auditing models** to detect issues early and make them observable.

### Built-in dbt tests (examples)

* **`unique` / `not_null`** on primary keys (e.g., campaign_id, person_id, event_id)
* **`accepted_values`** to enforce controlled vocabularies:

  * `event_type`: `SEND`, `DELIVERED`, `OPEN`, `CLICK`, `BOUNCE`, `UNSUBSCRIBE`
  * `person_type`: `CONTACT`, `LEAD`
  * `campaign.status`: `Planned`, `In_Progress`, `Completed`, `Cancelled`
  * `member_type`: `LEAD`, `CONTACT`
* **`relationships`** tests to protect referential integrity (e.g., fact campaign_id must exist in `dim_campaign`)

### Coverage + auditing (beyond basic tests)

* **Orphan / missing campaign coverage** is modeled explicitly via `dq_*` models (so stakeholders can quantify gaps, not just see failures).
* **Audit views** provide exception reporting without blocking the pipeline unless you choose to enforce it (practical for real teams).

---

## How to run locally (dbt Core)

### Prereqs

* Python 3.11+
* dbt Core + Snowflake adapter installed
* A working `profiles.yml` (recommended: use environment variables; do not hardcode credentials)

### Install dependencies

```bash
dbt deps
```

### Generate mock events (optional demo step)

```bash
dbt run-operation insert_mock_marketing_cloud_events
```

### Build daily models + run tests

```bash
dbt build --select tag:daily
```

### Generate and view docs

```bash
dbt docs generate
dbt docs serve
```

---

## How to run in dbt Cloud (conceptual)

A typical dbt Cloud job for this repo includes:

* **Commands**

  1. `dbt run-operation insert_mock_marketing_cloud_events`
  2. `dbt build --select tag:daily`
  3. `dbt docs generate`

* **Environment variables**

  * Store Snowflake connection settings in dbt Cloud’s environment (account/role/warehouse/db/schema) and credentials via supported secure methods.
  * Keep secrets out of version control.

---

## Models in this project (dbt inventory)

**Models (15 total):**

* **Staging**

  * `staging.stg_marketing_cloud_events`
  * `staging.stg_campaigns`
  * `staging.stg_campaign_members`
  * `staging.stg_contacts`
  * `staging.stg_leads`

* **Marts**

  * `marts.dim_campaign`
  * `marts.dim_person`
  * `marts.fct_email_events`
  * `marts.fct_email_events_daily`
  * `marts.fct_campaign_membership`
  * `marts.dq_campaign_id_coverage`
  * `marts.dq_orphan_campaign_ids`

* **Audit**

  * `audit.audit__event_id_duplicates`
  * `audit.audit__daily_grain_violations`
  * `audit.audit__orphan_campaigns_14d`

**Seeds (8 total):**

* `accounts`, `calendar`, `campaign_daily_metrics`, `campaign_members`, `campaigns`, `contacts`, `leads`, `marketing_cloud_events`

**Tests (25 total):**

* Unique / not_null / accepted_values / relationships across staging + marts

---

## Tableau reporting layer

This repo assumes Tableau is pointed at the curated **MARTS** layer (and optionally **AUDIT**).

### Dashboards (3)

> Names may vary depending on your Tableau workbook conventions; these are the intended functional dashboards.

1. **Executive Email Performance (Daily KPIs & Trends)**
   **Primary sources:** `marts.fct_email_events_daily`, `marts.dim_campaign`

2. **Campaign Performance & Engagement Breakdown**
   **Primary sources:** `marts.fct_email_events_daily`, `marts.dim_campaign`
   *(optionally drill to)* `marts.fct_email_events`

3. **Audience & Membership Quality / Coverage**
   **Primary sources:** `marts.fct_campaign_membership`, `marts.dim_person`, `marts.dq_*`, `audit.audit__*`

---

## What I’d do next (practical improvements)

If I were extending this beyond an interview/demo project:

* **Incremental models** for event facts (`fct_email_events`, `fct_email_events_daily`) with partitioning/clustering strategies in Snowflake
* **Exposures** for Tableau dashboards to formalize BI dependencies in dbt docs
* **Semantic/metrics layer** (dbt Metrics / semantic models) for governed KPI definitions
* **Performance hardening**

  * pre-aggregations where needed
  * selective materializations (view/table/incremental)
  * warehouse sizing guidance for daily jobs
* **CI/CD**

  * slim CI builds on PRs
  * automated `dbt build` on modified models
  * linting + SQL formatting
* **Observability**

  * richer audit logging tables for job runs
  * alerts on audit thresholds (e.g., orphan rate exceeds X%)

---

## Notes / disclaimers

* This is an **interview-style project** designed to demonstrate production patterns using **mock event generation** in place of a real Marketing Cloud connector.
* No secrets or credentials are included in this repo—configure Snowflake access via dbt Cloud environment settings or a local `profiles.yml` using environment variables.

---

## Quick start (tl;dr)

```bash
dbt deps
dbt run-operation insert_mock_marketing_cloud_events
dbt build --select tag:daily
dbt docs generate
```

```
```
