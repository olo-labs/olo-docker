<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Dynamic graph creation

Single-workflow preset that turns a natural-language request into a **valid `WorkflowDefinition` JSON graph**, validates it, and expands it inline at runtime. Use it to demo meta-workflow generation — the planner returns JSON only; the kernel injects and runs the generated subgraph.

| Workflow | Role | Queue |
|----------|------|-------|
| `dynamic-graph-creation` | JSON graph planner + inline expansion | `oloQueue2` |

Unlike multi-agent scenarios (travel, research, RCA, …), this collection has **no child workflows**. The `graph-planner` agent node produces structured graph JSON; olo-kernel validates and merges it into the live execution.

## Canvas pipeline

```
START → conversation-load → human-input → graph-planner → conversation-store → END
```

| Step | Purpose |
|------|---------|
| `conversation-load` | Restores prior chat context (`conversationSummary`, `conversationHistory`) |
| `human-input` | Operator reviews requirements and optional publish fields before planning |
| `graph-planner` | LLM returns **JSON only** — a complete `WorkflowDefinition` graph |
| `conversation-store` | Persists the turn for the next run |

## Planner output rules

The graph planner must return a single JSON object (no markdown, no code fences) with at least:

- One `START` node, one `END` node, and edges connecting `START → … → END`
- Unique kebab-case node ids
- Allowed node types: `START`, `END`, `AGENT`, `TOOL`, `MODEL`, `PARALLEL`, `HUMAN`, `CONDITION`, `ROUTER`, `PLANNER`, `REFLECTION`, `EVALUATOR`, `VECTOR_SEARCH`, `MEMORY`, `WORKFLOW_REF`
- `TOOL` nodes with `configuration.toolId` set to an `olo-core:` tool id

Invalid JSON is retried up to three times; validation errors are injected into the planner prompt via `generatedGraphJsonValidationError`.

## Tools the generated graph may reference

The planner prompt documents commonly used `olo-core` tools. Generated graphs can wire any of these (plus human-approved mock actions):

| Tool ID | Purpose |
|---------|---------|
| `olo-core:web-search` | News / web lookup |
| `olo-core:log-reader` | Log lines in a time window |
| `olo-core:cpu-usage` | CPU metrics |
| `olo-core:memory-usage` | Memory metrics |
| `olo-core:numeric-metric` | Generic numeric series |
| `olo-core:recently-changed-code` | Recent diffs / PR stubs |
| `olo-core:calculator` | Arithmetic |
| `olo-core:http-tool` | HTTP probe |
| `olo-core:restart-container` | Mock container restart (writes execution log) |
| `olo-core:git-revert` | Mock git revert (writes execution log) |
| `olo-core:create-pull-request` | Mock PR creation (writes execution log) |
| `olo-core:book-ticket` | Mock ticket booking (writes execution log) |

For observability tools, include ISO-8601 `startTime` and `endTime` in `configuration.arguments` when the user mentions a time window.

Observability fixtures live under [`olo-core/tools/demo-data/`](../../../olo-core/tools/demo-data/README.md).

## Human input

The `human-input` step asks the operator to confirm graph requirements before planning. For publish flows, supply **title** and **headBranch** so a generated graph can call `olo-core:create-pull-request` after validation.

## Sample prompts

### Minimal echo workflow

```text
Create the smallest valid workflow that echoes the user message through a single AGENT node.
```

### Tool chain (observability)

```text
Build a workflow that reads payment-service logs from 2026-06-14T14:30:00Z to 2026-06-14T14:31:00Z,
checks CPU usage in the same window, and summarizes findings in a final AGENT node.
```

### Human-approved action

```text
Create a workflow with a HUMAN intake step and a tool node that calls olo-core:create-pull-request
using title and headBranch from the operator input.
```

### Shorter prompts

| Prompt | What it exercises |
|--------|-------------------|
| `Hello-world workflow: START → AGENT → END` | Minimal graph shape |
| `Workflow that uses olo-core:calculator to add 2 and 2` | Single TOOL node |
| `Two-step AGENT workflow that answers then summarizes` | Multi-node AGENT chain |

## Regenerate JSON

From `olo-definition/`:

```bash
./gradlew :olo-definition:generateDynamicGraphCreation
```

Writes **`olo-configuration/dynamic-graph-creation/dynamic-graph-creation.json`** only.

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `dynamic-graph-creation`. See [current-active/README.md](../current-active/README.md).

## Load in worker

Default local config scans `current-active/`. To scan this folder directly:

```yaml
workflowDefinitions:
  scanFolder: "../../olo-definition/olo-configuration/dynamic-graph-creation"
```

## Key variables

| Variable | Role |
|----------|------|
| `message` | User request (workflow input) |
| `conversationSummary` | Prior conversation summary from `conversation-load` |
| `generatedGraphJson` | Model-produced workflow graph JSON |
| `generatedGraphJsonValidationError` | Last validation error (planner retries) |
| `ReturnValue` | Workflow return message |

## Tests

- `DynamicGraphCreationConfigurationTest` — on-disk JSON matches programmatic definitions; planner prompt requires JSON-only output
- `DynamicGraphCreationRegenerationTest` — regenerates canonical JSON
- `DynamicSubgraphInjectionSupportTest` — subgraph merge helpers (olo-definition)

## Source

Programmatic builder: `DynamicGraphCreationDefinitions` in `olo-definition` test sources (`org.olo.definition.configuration.dynamicgraphcreation`).
