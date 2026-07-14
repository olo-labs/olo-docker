<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Capacity planning scenario

Multi-agent workflow for post-incident capacity and cost planning. The orchestrator reads mock CPU/memory metrics, uses the calculator for cost estimates, and delegates scaling recommendations to specialist **child workflows**.

| Workflow | Role | Queue |
|----------|------|-------|
| `capacity-planning-orchestrator` | Tool-call planner + delegation | `oloQueue2` |
| `resource-utilization-agent` | Summarizes peak utilization (child workflow) | `oloQueue2` |
| `cost-estimation-agent` | Estimates incremental cost (child workflow) | `oloQueue2` |
| `scaling-recommendation-agent` | Recommends autoscaling and pool tuning (child workflow) | `oloQueue2` |
| `capacity-report-agent` | Publishes capacity planning report (child workflow) | `oloQueue2` |

## Mock tools

| Tool ID | Purpose | Key arguments |
|---------|---------|---------------|
| `olo-core:cpu-usage` | CPU utilization samples | `startTime`, `endTime` |
| `olo-core:memory-usage` | Memory/heap usage samples | `startTime`, `endTime` |
| `olo-core:calculator` | Cost and capacity arithmetic | `expression` or `a`, `b`, `op` |

Uses demo metrics from [`olo-core/tools/demo-data/`](../../../olo-core/tools/demo-data/README.md) (2026-06-14 ~14:30 UTC incident).

## Sample prompt (recommended)

```text
After the payment-service outage on 2026-06-14 around 14:30 UTC, plan capacity changes.
Review peak CPU and memory, estimate extra instance cost, recommend scaling thresholds,
and publish a capacity planning report for leadership.
```

### Shorter prompts

| Prompt | What it exercises |
|--------|-------------------|
| `What were peak CPU and memory during the 2026-06-14 incident?` | cpu-usage + memory-usage + utilization-agent |
| `Estimate cost of 4 extra instances for 2.5 hours` | calculator + cost-estimation-agent |
| `Recommend autoscaling changes after the gateway timeout incident` | scaling-recommendation-agent |

### Tool time windows

| Tool | startTime | endTime |
|------|-----------|---------|
| CPU / Memory | `2026-06-14T14:29:00Z` | `2026-06-14T14:32:00Z` |

## Regenerate JSON

```bash
./gradlew :olo-definition:generateCapacityPlanning
```

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `capacity-planning`. See [current-active/README.md](../current-active/README.md).

## Tests

- `CapacityPlanningConfigurationTest`
- `CapacityPlanningRegenerationTest`
