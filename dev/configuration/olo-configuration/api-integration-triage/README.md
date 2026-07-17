<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# API integration triage scenario

Multi-agent workflow for investigating upstream API and integration failures. The orchestrator probes HTTP endpoints, reads correlated logs, searches vendor stubs, and delegates analysis to specialist **child workflows**.

| Workflow | Role | Queue |
|----------|------|-------|
| `api-integration-orchestrator` | Tool-call planner + delegation | `oloQueue2` |
| `endpoint-probe-agent` | Interprets HTTP probe results (child workflow) | `oloQueue2` |
| `dependency-analysis-agent` | Assesses vendor/dependency impact (child workflow) | `oloQueue2` |
| `error-correlation-agent` | Maps HTTP errors to log signatures (child workflow) | `oloQueue2` |
| `integration-report-agent` | Publishes integration incident report (child workflow) | `oloQueue2` |

## Mock tools

| Tool ID | Purpose | Key arguments |
|---------|---------|---------------|
| `olo-core:http-tool` | Probe upstream HTTP endpoints | `url` |
| `olo-core:log-reader` | Application logs during failure window | `startTime`, `endTime` |
| `olo-core:web-search` | Vendor status / advisory stubs | `query` |

Combines with shared incident logs from [`olo-core/tools/demo-data/logs/`](../../../olo-core/tools/demo-data/logs/) when investigating the **2026-06-14 payment-gateway outage**.

## Sample prompt (recommended)

```text
Investigate payment-service integration failures on 2026-06-14 around 14:30 UTC.
Probe the payment gateway health endpoint, correlate errors in application logs,
check vendor status, and publish an integration incident report with remediation steps.
```

### Shorter prompts

| Prompt | What it exercises |
|--------|-------------------|
| `Did the payment gateway HTTP health check fail during the outage?` | http-tool + endpoint-probe-agent |
| `Correlate ConnectionTimeout logs with HTTP probe failures` | log-reader + error-correlation-agent |
| `Search for payment gateway provider outage advisories` | web-search + dependency-analysis-agent |

### Tool hints

| Tool | Example |
|------|---------|
| HTTP | `url: https://api.example.com/health` |
| Log Reader | `startTime: 2026-06-14T14:30:00Z`, `endTime: 2026-06-14T14:31:00Z` |
| Web Search | `query: payment gateway timeout outage status` |

## Regenerate JSON

```bash
./gradlew :olo-definition:generateApiIntegrationTriage
```

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `api-integration-triage`. See [current-active/README.md](../current-active/README.md).

## Tests

- `ApiIntegrationTriageConfigurationTest`
- `ApiIntegrationTriageRegenerationTest`

## Contributors and owners

Contributions are welcome. Start with [CONTRIBUTING.md](../../../CONTRIBUTING.md), use the [contributor guide](../../../docs/CONTRIBUTOR_GUIDE.md) to find the right module or scenario, route review through [OWNERS.md](../../../OWNERS.md), and record meaningful module or scenario credit in [CREDITS.md](../../../CREDITS.md).
