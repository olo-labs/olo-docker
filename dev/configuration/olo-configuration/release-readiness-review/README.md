<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Release readiness review scenario

Multi-agent release workflow. The orchestrator inventories recent changes, assesses regression risk, coordinates QA sign-off via **child workflows**, and publishes release notes.

| Workflow | Role | Queue |
|----------|------|-------|
| `release-readiness-orchestrator` | Tool-call planner + delegation | `oloQueue2` |
| `changelog-agent` | Summarizes merged changes (child workflow) | `oloQueue2` |
| `regression-risk-agent` | Assesses regression risk (child workflow) | `oloQueue2` |
| `qa-signoff-agent` | Go/no-go and test gaps (child workflow) | `oloQueue2` |
| `release-notes-agent` | Customer-facing release notes (child workflow) | `oloQueue2` |

## Mock tools

| Tool ID | Purpose | Key arguments |
|---------|---------|---------------|
| `olo-core:recently-changed-code` | PR/diff stubs in release | `limit`, `pullRequestNumber` |
| `olo-core:log-reader` | Staging regression logs | `startTime`, `endTime` |
| `olo-core:calculator` | Risk score math | `expression` |

Demo PR stubs: #839, #842, #847 — see [`demo-data/recent-changes/`](../../../olo-core/tools/demo-data/recent-changes/).

## Sample prompt (recommended)

```text
Review release readiness for payment-service v2.4.0 after the 2026-06-14 incident fixes.
Summarize recent code changes, assess regression risk from staging logs,
get QA sign-off criteria, and publish customer-facing release notes.
```

### Shorter prompts

| Prompt | What it exercises |
|--------|-------------------|
| `List changes in PR 842 and 847 for the release candidate` | recently-changed-code + changelog-agent |
| `Any ERROR regressions in staging logs before we ship?` | log-reader + regression-risk-agent |
| `What QA gaps block production deployment?` | qa-signoff-agent |
| `Write release notes for payment-service v2.4.0` | release-notes-agent |

### Tool hints

| Tool | Example |
|------|---------|
| Recently Changed Code | `limit: 5` or `pullRequestNumber: "847"` |
| Log Reader | `startTime: 2026-06-14T14:30:00Z`, `endTime: 2026-06-14T14:35:00Z` |
| Calculator | `expression: "3 * 2.5 + 1"` (risk weighting) |

## Regenerate JSON

```bash
./gradlew :olo-definition:generateReleaseReadinessReview
```

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `release-readiness-review`. See [current-active/README.md](../current-active/README.md).

## Load in worker

Default local config scans `current-active/`. To scan this folder directly:

```yaml
workflowDefinitions:
  scanFolder: "../../olo-definition/olo-configuration/release-readiness-review"
```

## Tests

- `ReleaseReadinessReviewConfigurationTest`
- `ReleaseReadinessReviewRegenerationTest`

## Contributors and owners

Contributions are welcome. Start with [CONTRIBUTING.md](../../../CONTRIBUTING.md), use the [contributor guide](../../../docs/CONTRIBUTOR_GUIDE.md) to find the right module or scenario, route review through [OWNERS.md](../../../OWNERS.md), and record meaningful module or scenario credit in [CREDITS.md](../../../CREDITS.md).
