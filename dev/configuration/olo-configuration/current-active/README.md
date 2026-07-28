<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# RAG knowledge scenario

End-to-end RAG **ingest** and **query** workflows without human-input steps.

| Workflow | Role | Queue |
|----------|------|-------|
| `documents-index` | Index uploaded files into vector store (`olo-core:rag-ingest`) | `oloQueue2` |
| `rag-chat` | Retrieve chunks then answer (`olo-core:rag-query` → agent) | `oloQueue2` |

## Ingest (Knowledge → Create new)

1. Upload files under **Documents**
2. **Knowledge → Create new** → select files → **Create RAG index run**
3. Runs `documents-index` pipeline: `START → RAG Ingest TOOL → END` (no human step)

## Query (Chat)

1. Select a knowledge source in the **RAG dropdown** before Send in olo-chat
2. Backend routes to `rag-chat` pipeline and passes `capabilitySource`
3. `rag-query` plugin retrieves chunks and injects `ragContext` into the agent prompt

## Activate

**Administration → Scenarios → Activate `rag-knowledge`**, then restart the worker.

Ensure `default/` presets (e.g. `ask`) remain available if needed — activation replaces `current-active/`.

## Contributors and owners

Contributions are welcome. Start with [CONTRIBUTING.md](../../../CONTRIBUTING.md), use the [contributor guide](../../../docs/CONTRIBUTOR_GUIDE.md) to find the right module or scenario, route review through [OWNERS.md](../../../OWNERS.md), and record meaningful module or scenario credit in [CREDITS.md](../../../CREDITS.md).
