<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# OLO configuration scenarios

Multi-agent orchestration presets for end-to-end demos. Each folder is a self-contained scenario with an orchestrator workflow, specialist **child workflows**, mock tools where applicable, and a **README** with sample prompts.

All scenarios use queue **`oloQueue2`** unless noted otherwise.

## Scenario catalog

| Folder | Orchestrator | Child agents | Mock tools | README |
|--------|--------------|--------------|------------|--------|
| [research-planner](research-planner/) | `research-orchestrator` | literature, synthesis | research-literature | [README](research-planner/README.md) |
| [travel-planner](travel-planner/) | `travel-orchestrator` | destination, itinerary | travel-destinations, travel-offers | [README](travel-planner/README.md) |
| [log-rca-analysis](log-rca-analysis/) | `log-rca-orchestrator` | log-failure, metrics-rca, code-change-rca, incident-summary | log-reader, cpu-usage, recently-changed-code | [README](log-rca-analysis/README.md) |
| [performance-triage](performance-triage/) | `performance-triage-orchestrator` | latency, resource-pressure, optimization, performance-report | cpu-usage, memory-usage, numeric-metric | [README](performance-triage/README.md) |
| [security-incident-response](security-incident-response/) | `security-incident-orchestrator` | threat-detection, forensics, containment, security-report | log-reader, recently-changed-code, web-search | [README](security-incident-response/README.md) |
| [release-readiness-review](release-readiness-review/) | `release-readiness-orchestrator` | changelog, regression-risk, qa-signoff, release-notes | recently-changed-code, log-reader, calculator | [README](release-readiness-review/README.md) |
| [api-integration-triage](api-integration-triage/) | `api-integration-orchestrator` | endpoint-probe, dependency-analysis, error-correlation, integration-report | http-tool, log-reader, web-search | [README](api-integration-triage/README.md) |
| [capacity-planning](capacity-planning/) | `capacity-planning-orchestrator` | resource-utilization, cost-estimation, scaling-recommendation, capacity-report | cpu-usage, memory-usage, calculator | [README](capacity-planning/README.md) |
| [literature-review](literature-review/) | `literature-review-orchestrator` | paper-discovery, evidence-synthesis, gap-analysis, research-brief | research-literature, web-search | [README](literature-review/README.md) |
| [dynamic-graph-creation](dynamic-graph-creation/) | `dynamic-graph-creation` | (inline LLM graph) | — | [README](dynamic-graph-creation/README.md) |
| [documents-index](documents-index/) | `documents-index` | RAG ingest (TOOL) | `olo-core:rag-ingest` | [README](documents-index/README.md) |
| [default](default/) | `agent`, `planner`, … | various presets | calculator, cpu-usage, … | — |

## Quick start (any scenario)

1. **Regenerate** JSON for a scenario (from `olo-definition/olo-definition`):

   ```bash
   ./gradlew :olo-definition:generateLogRcaAnalysis
   ./gradlew :olo-definition:generatePerformanceTriage
   ./gradlew :olo-definition:generateSecurityIncidentResponse
   ./gradlew :olo-definition:generateReleaseReadinessReview
   ./gradlew :olo-definition:generateApiIntegrationTriage
   ./gradlew :olo-definition:generateCapacityPlanning
   ./gradlew :olo-definition:generateLiteratureReview
   ./gradlew :olo-definition:generateAllScenarios
   ```

2. **Activate the scenario** (recommended — **olo-ui**):

   - Open **Administration → Scenarios**
   - Click **Activate** next to the scenario folder (e.g. `log-rca-analysis`)
   - This copies the folder into [`current-active/`](current-active/), clears the previous active files, and refreshes olo-worker + studio

   **Manual alternative:** copy the scenario into `current-active/` and call `POST /api/v1/system/refresh` on olo-be, or use **Refresh stack** in the workflow builder. See [current-active/README.md](current-active/README.md).

3. **Point the worker** at `current-active` (default in local-debug config):

   ```yaml
   workflowDefinitions:
     scanFolder: "../../olo-definition/olo-configuration/current-active"
     recursive: true
   ```

   You do **not** need to change `scanFolder` when using UI activation — only the files inside `current-active` change.

4. **Set demo data root** (observability tools):

   ```bash
   OLO_DEMO_DATA_ROOT=olo-core/tools
   ```

5. **Run in olo-ui** — select the orchestrator workflow on `oloQueue2`, paste the sample prompt from the scenario README. Use **Cancel** during a run if needed; **Run** is available again after cancel completes.

## Shared mock incident (observability scenarios)

`log-rca-analysis`, `performance-triage`, `security-incident-response`, and `release-readiness-review` share synthetic demo data for a **payment-service outage on 2026-06-14 ~14:30 UTC**:

- Logs: `olo-core/tools/demo-data/logs/application.log`
- CPU: `olo-core/tools/demo-data/cpu/metrics.csv`
- Memory: `olo-core/tools/demo-data/memory/metrics.csv`
- Latency: `olo-core/tools/demo-data/latency/metrics.csv`
- Code changes: `olo-core/tools/demo-data/recent-changes/*.patch`

Details: [`olo-core/tools/demo-data/README.md`](../../olo-core/tools/demo-data/README.md).

## Architecture

Each orchestrator:

1. Runs a **tool-call planner** (`agent` node with `toolCallPlanner: true`)
2. Calls **mock tools** from the allow-list
3. Delegates to **child workflows** via `agentCalls` (each specialist agent is a separate workflow JSON)
4. Continues until `directResponse` or the final summary agent completes

Child workflows run as **Temporal child workflows** when dispatched from the parent workflow thread. Worker logs include `childWorkflowId`, `parentWorkflowId`, and shared `transactionId` for correlation (see [olo-worker/README.md](../../olo-worker/README.md#logging)).

Programmatic builders live under `olo-definition/src/test/java/org/olo/definition/configuration/<scenario>/`.
