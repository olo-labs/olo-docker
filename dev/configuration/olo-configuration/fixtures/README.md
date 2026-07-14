<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Test fixtures

Committed samples used by unit tests (injection envelopes, etc.). Not loaded by the worker unless copied to `current-active/`.

| File | Used by |
|------|---------|
| `tool-call-agent-agent.json` | `DynamicSubgraphInjectionSupportTest`, `DynamicSubgraphInjectionLoaderTest` |

Refresh from a runtime `log/tool-call-*.json` when the agent preset graph changes materially.
