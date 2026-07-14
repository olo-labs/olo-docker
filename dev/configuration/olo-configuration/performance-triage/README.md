<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Performance triage scenario

Multi-agent SRE workflow for investigating latency spikes. The orchestrator queries mock CPU, memory, and latency metrics, delegates analysis to specialist **child workflows**, then publishes a performance report.

| Workflow | Role | Queue |
|----------|------|-------|
| `performance-triage-orchestrator` | Tool-call planner + delegation | `oloQueue2` |
| `latency-analysis-agent` | Interprets latency spikes (child workflow) | `oloQueue2` |
| `resource-pressure-agent` | Correlates CPU/memory pressure (child workflow) | `oloQueue2` |
| `optimization-agent` | Recommends tuning actions (child workflow) | `oloQueue2` |
| `performance-report-agent` | Publishes SRE report (child workflow) | `oloQueue2` |

## Mock tools

| Tool ID | Purpose | Key arguments |
|---------|---------|---------------|
| `olo-core:cpu-usage` | CPU utilization samples | `startTime`, `endTime` |
| `olo-core:memory-usage` | Heap/memory usage (MB) | `startTime`, `endTime` |
| `olo-core:numeric-metric` | Upstream latency (ms) | `startTime`, `endTime` |

Fixtures: [`olo-core/tools/demo-data/README.md`](../../../olo-core/tools/demo-data/README.md) — same **2026-06-14 14:30 UTC** payment-service incident.

## Sample prompt (recommended)

```text
Investigate the payment-service latency spike on 2026-06-14 around 14:30 UTC.
Check CPU, memory, and request latency metrics, analyze root cause with specialist agents,
and publish a performance incident report with recommended tuning actions.
```

### Shorter prompts

| Prompt | What it exercises |
|--------|-------------------|
| `What was p95 latency during the 2026-06-14 14:30 UTC outage?` | Latency metric + latency-analysis-agent |
| `Did memory pressure contribute to the payment gateway incident?` | memory-usage + resource-pressure-agent |
| `Recommend timeout and pool tuning after the 2026-06-14 incident` | optimization-agent |

### Tool time windows (demo fixtures)

| Tool | startTime | endTime |
|------|-----------|---------|
| CPU Usage | `2026-06-14T14:29:00Z` | `2026-06-14T14:32:00Z` |
| Memory Usage | `2026-06-14T14:29:00Z` | `2026-06-14T14:32:00Z` |
| Latency Metric | `2026-06-14T14:29:00Z` | `2026-06-14T14:32:00Z` |

### Expected mock findings

- **Latency:** peak ~3120 ms at `2026-06-14T14:30:30Z`
- **Memory:** spike to ~1536 MB during incident window
- **CPU:** peak ~97% (shared incident narrative)

## Regenerate JSON

```bash
./gradlew :olo-definition:generatePerformanceTriage
```

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `performance-triage`. See [current-active/README.md](../current-active/README.md).

## Load in worker

Default local config scans `current-active/`. To scan this folder directly:

```yaml
workflowDefinitions:
  scanFolder: "../../olo-definition/olo-configuration/performance-triage"
```

## Tests

- `PerformanceTriageConfigurationTest`
- `PerformanceTriageRegenerationTest`
