<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Security incident response scenario

Multi-agent security workflow for breach triage. The orchestrator scans mock logs and code changes, delegates forensics to specialist **child workflows**, and publishes a security incident report.

| Workflow | Role | Queue |
|----------|------|-------|
| `security-incident-orchestrator` | Tool-call planner + delegation | `oloQueue2` |
| `threat-detection-agent` | Classifies attack indicators (child workflow) | `oloQueue2` |
| `forensics-agent` | Traces breach vector (child workflow) | `oloQueue2` |
| `containment-agent` | Recommends isolation steps (child workflow) | `oloQueue2` |
| `security-report-agent` | Publishes executive security report (child workflow) | `oloQueue2` |

## Mock tools

| Tool ID | Purpose | Key arguments |
|---------|---------|---------------|
| `olo-core:log-reader` | Suspicious log activity | `startTime`, `endTime` |
| `olo-core:recently-changed-code` | Recent PR/diff stubs | `limit`, `pullRequestNumber` |
| `olo-core:web-search` | Threat-intel stub search | `query` |

## Sample prompt (recommended)

```text
Respond to a suspected security incident in payment-service on 2026-06-14 around 14:30 UTC.
Scan logs for suspicious activity, investigate recent code changes, recommend containment,
and publish a security incident report with timeline and remediation steps.
```

### Shorter prompts

| Prompt | What it exercises |
|--------|-------------------|
| `Classify threats in payment-service logs from 14:30–14:31 UTC on 2026-06-14` | log-reader + threat-detection-agent |
| `Did PR 842 introduce a security regression before the outage?` | recently-changed-code + forensics-agent |
| `What immediate containment steps should we take?` | containment-agent |
| `Draft executive security report for the payment-service incident` | security-report-agent |

### Tool hints

| Tool | Arguments |
|------|-----------|
| Log Reader | `startTime: 2026-06-14T14:30:00Z`, `endTime: 2026-06-14T14:31:00Z` |
| Recently Changed Code | `pullRequestNumber: "842"` |
| Web Search | `query: "payment gateway timeout CVE"` |

## Regenerate JSON

```bash
./gradlew :olo-definition:generateSecurityIncidentResponse
```

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `security-incident-response`. See [current-active/README.md](../current-active/README.md).

## Load in worker

Default local config scans `current-active/`. To scan this folder directly:

```yaml
workflowDefinitions:
  scanFolder: "../../olo-definition/olo-configuration/security-incident-response"
```

## Tests

- `SecurityIncidentResponseConfigurationTest`
- `SecurityIncidentResponseRegenerationTest`
