<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Research planner scenario

End-to-end scenario collection for a tool-call orchestrator with specialist child agents and mock literature lookup tools.

| Workflow | Role | Queue |
|----------|------|-------|
| `research-orchestrator` | Tool-call planner + delegation | `oloQueue2` |
| `literature-agent` | Paper discovery child agent | `oloQueue2` |
| `synthesis-agent` | Brief synthesis child agent | `oloQueue2` |

## Mock tools

| Tool ID | Purpose | Example query |
|---------|---------|---------------|
| `olo-core:research-literature` | Mock academic paper summaries | `renewable energy storage`, `AI safety alignment` |

## Regenerate JSON

From `olo-definition/olo-definition`:

```bash
./gradlew :olo-definition:generateResearchPlanner
```

Writes **`olo-configuration/research-planner/`** only.

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `research-planner`. See [current-active/README.md](../current-active/README.md).

## Load in worker

Default local config scans `current-active/`. To scan this folder directly:

```yaml
workflowDefinitions:
  scanFolder: "../../olo-definition/olo-configuration/research-planner"
```

## Mock literature topics

| Sample query | Fixture |
|--------------|---------|
| renewable energy storage | `renewable-energy-storage.json` |
| AI safety alignment | `ai-safety-alignment.json` |
| what is olo / Open LLM Orchestrator | `olo-open-llm-orchestrator.json` |

## Tests

- `ResearchPlannerConfigurationTest` — on-disk JSON matches programmatic definitions
- `ResearchPlannerEndToEndTest` (olo-kernel) — registry load, tool execution, tool-call merge
