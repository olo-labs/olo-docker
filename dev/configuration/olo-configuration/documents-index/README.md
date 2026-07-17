<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Documents index scenario

Dedicated **RAG ingest** workflow for indexing uploaded documents into a vector store. Triggered from **olo-chat → Knowledge → Create new** via `POST /api/rag/ingest`, or manually from **olo-ui** Run workflow.

| Workflow | Role | Default queue |
|----------|------|---------------|
| `documents-index` | Single TOOL node (`olo-core:rag-ingest`) | `oloQueue2` |

## Flow

1. **Upload** files under **olo-chat → Documents** (`POST /api/resource/upload`) keyed by `capabilitySource`.
2. **Select files** in **Knowledge → Create new** and start ingest (`POST /api/rag/ingest`).
3. **Temporal** runs the `documents-index` pipeline; the **RAG Ingest** plugin chunks files and writes entries into the configured vector store.
4. **Progress** is visible via run SSE (`runId` returned from ingest API).

## Configuration (olo-ui builder)

Edit the **RAG Ingest** TOOL node on the canvas:

| Property | Purpose |
|----------|---------|
| Vector store (`extensionRef`) | Links to `extensions[]` entry (`pgvector-store`) |
| Collection table (`vectorTable`) | Logical collection / table name |
| Chunk size | Characters per indexed chunk |
| Embedding provider | `modelProviders[]` ref for embeddings |

Vector store driver settings live under workflow **extensions** (`VECTOR_STORE` type): `driver`, `connectionRef`, `table`.
The checked-in pipeline uses `${env:...}` placeholders so Docker/container configuration owns the deploy-time values.

Environment:

```bash
OLO_RESOURCE_UPLOAD_DIR=/path/to/uploads
OLO_VECTOR_STORE_DRIVER=qdrant
OLO_VECTOR_STORE_URL=http://qdrant:6333
OLO_VECTOR_STORE_TABLE=documents
OLO_VECTOR_STORE_COLLECTION=documents
OLO_VECTOR_STORE_VECTOR_SIZE=384
OLO_VECTOR_STORE_DISTANCE=Cosine
```

## Activate

1. **Administration → Scenarios** → activate `documents-index`, or copy this folder into `current-active/`.
2. Ensure olo-worker scans `olo-configuration/current-active`.
3. Set `olo.rag.ingest.pipeline=documents-index` on olo-be (default).

## olo-chat env (optional)

```env
VITE_RESOURCE_UPLOAD_PIPELINE=documents-index
VITE_RESOURCE_UPLOAD_QUEUE=oloQueue2
```

## Contributors and owners

Contributions are welcome. Start with [CONTRIBUTING.md](../../../CONTRIBUTING.md), use the [contributor guide](../../../docs/CONTRIBUTOR_GUIDE.md) to find the right module or scenario, route review through [OWNERS.md](../../../OWNERS.md), and record meaningful module or scenario credit in [CREDITS.md](../../../CREDITS.md).
