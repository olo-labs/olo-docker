<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Log RCA analysis scenario

End-to-end scenario for incident triage and root-cause analysis. A tool-call orchestrator scans mock observability data, delegates RCA to specialist **child workflows**, then publishes a final incident summary.

| Workflow | Role | Queue |
|----------|------|-------|
| `log-rca-orchestrator` | Tool-call planner + delegation | `oloQueue2` |
| `log-failure-agent` | Identifies failure signatures and affected services (child workflow) | `oloQueue2` |
| `metrics-rca-agent` | Correlates CPU spikes with the failure window (child workflow) | `oloQueue2` |
| `code-change-rca-agent` | Analyzes recent deployments and code changes (child workflow) | `oloQueue2` |
| `incident-summary-agent` | Publishes executive incident summary (child workflow) | `oloQueue2` |

## Investigation flow

The orchestrator runs in multiple planner passes:

1. **Failure identification** — calls `olo-core:log-reader` (and optionally delegates to `log-failure-agent`) to find errors, stack traces, and the incident time window.
2. **Root-cause analysis** — delegates to `metrics-rca-agent` and `code-change-rca-agent` as separate child workflows (each runs its own workflow graph).
3. **Final summary** — delegates to `incident-summary-agent` to publish timeline, root cause, impact, and recommended actions.

## Mock tools (orchestrator)

These tools read filesystem fixtures under `olo-core/tools/demo-data/`. No live APIs are called.

| Tool ID | Purpose | Key arguments |
|---------|---------|---------------|
| `olo-core:log-reader` | Fetch ERROR/WARN log lines in a time window | `startTime`, `endTime` (ISO-8601) |
| `olo-core:cpu-usage` | CPU utilization samples in a time window | `startTime`, `endTime` (ISO-8601) |
| `olo-core:recently-changed-code` | Recent PR/diff stubs for the service | `limit` (optional), `pullRequestNumber` (optional) |

Fixture details: [`olo-core/tools/demo-data/README.md`](../../../olo-core/tools/demo-data/README.md).

## Sample prompt (recommended)

Use this prompt in **olo-ui** (Run workflow → `log-rca-orchestrator`) or **chat-ui** to exercise the full end-to-end path against the bundled mock incident:

```text
Investigate the payment-service outage on 2026-06-14 around 14:30 UTC.
Find errors in the logs, determine root cause using metrics and recent code changes,
and publish an incident summary with timeline, impact, and recommended actions.
```

### Why this prompt works

All mock data describes the same synthetic outage on **2026-06-14 ~14:30 UTC**:

- Payment gateway becomes unreachable
- CPU spikes to ~97% (`demo-data/cpu/metrics.csv`)
- Logs show `ConnectionTimeout`, circuit breaker OPEN, retry exhaustion (`demo-data/logs/application.log`)
- Recent PR stubs include #842 (gateway timeout reduction — likely trigger) and #839 (retry pool resize)

The planner should:

1. Call **log-reader** with a window around 14:30 UTC
2. Delegate **log-failure-agent** for structured failure analysis
3. Delegate **metrics-rca-agent** and **code-change-rca-agent** for RCA hypotheses
4. Delegate **incident-summary-agent** for the final report

### Shorter prompts (still valid)

| Prompt | What it exercises |
|--------|-------------------|
| `What failed in payment-service logs between 14:30 and 14:35 UTC on 2026-06-14?` | Log reader + log-failure-agent |
| `Was there a CPU spike during the payment gateway outage on 2026-06-14 at 14:30 UTC?` | CPU usage tool + metrics-rca-agent |
| `Show recent code changes for payment-service before the 2026-06-14 incident` | Recently-changed-code + code-change-rca-agent |
| `Summarize the payment-service incident on 2026-06-14` | Full flow through incident-summary-agent |

### Tool argument hints (mock incident window)

If the planner asks for times, these windows match the demo fixtures:

| Tool | startTime | endTime |
|------|-----------|---------|
| Log Reader | `2026-06-14T14:30:00Z` | `2026-06-14T14:31:00Z` |
| CPU Usage | `2026-06-14T14:29:00Z` | `2026-06-14T14:32:00Z` |
| Recently Changed Code | — | `pullRequestNumber: "842"` (optional filter) |

### Expected mock findings (sanity check)

After a successful run you should see evidence of:

- **Logs:** `ConnectionTimeout`, `GATEWAY_TIMEOUT`, `CircuitBreaker OPEN`, `Retry exhausted`
- **CPU:** peak ~97% near `2026-06-14T14:30:30Z`
- **Code changes:** PR #842 (`842-gateway-timeout.patch`) — reduced gateway timeouts
- **Summary:** consolidated timeline and root-cause narrative from `incident-summary-agent`

## Regenerate JSON

From `olo-definition/olo-definition`:

```bash
./gradlew :olo-definition:generateLogRcaAnalysis
```

Writes **`olo-configuration/log-rca-analysis/`** only.

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `log-rca-analysis`. See [current-active/README.md](../current-active/README.md).

## Load in worker

Default local config scans `current-active/` (activate the scenario first). To scan this folder directly:

```yaml
workflowDefinitions:
  scanFolder: "../../olo-definition/olo-configuration/log-rca-analysis"
```

Ensure the worker process can resolve demo data. Tools auto-discover `olo-core/tools/demo-data` from the working directory, or set:

```bash
OLO_DEMO_DATA_ROOT=olo-core/tools
```

## Run end-to-end (local)

1. Start **Temporal**, **Ollama** (or configured LLM), **olo** backend, and **olo-worker** with `scanFolder` pointing at this folder.
2. Open **olo-ui** → select workflow **`log-rca-orchestrator`** on queue **`oloQueue2`**.
3. Paste the [sample prompt](#sample-prompt-recommended) and click **Run**.
4. Watch the progress log: tool calls first, then child-agent delegations, then final summary.
5. Use **Cancel** if needed; you can rerun immediately after cancel completes.

## Tests

- `LogRcaAnalysisConfigurationTest` — on-disk JSON matches programmatic definitions
- `LogRcaAnalysisRegenerationTest` — regenerates presets
- Programmatic source: `LogRcaAnalysisDefinitions.java`
