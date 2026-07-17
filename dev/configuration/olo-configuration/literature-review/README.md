<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Literature review scenario

Multi-agent workflow for structured literature reviews. The orchestrator queries mock academic paper summaries, supplements with web-search stubs, and delegates synthesis to specialist **child workflows**.

| Workflow | Role | Queue |
|----------|------|-------|
| `literature-review-orchestrator` | Tool-call planner + delegation | `oloQueue2` |
| `paper-discovery-agent` | Ranks papers and key findings (child workflow) | `oloQueue2` |
| `evidence-synthesis-agent` | Combines literature and web sources (child workflow) | `oloQueue2` |
| `gap-analysis-agent` | Identifies research gaps (child workflow) | `oloQueue2` |
| `research-brief-agent` | Publishes executive research brief (child workflow) | `oloQueue2` |

## Mock tools

| Tool ID | Purpose | Key arguments |
|---------|---------|---------------|
| `olo-core:research-literature` | Mock academic paper summaries | topic in user message |
| `olo-core:web-search` | Surveys, preprints, news stubs | `query` |

### Mock literature topics (research-literature tool)

| Sample query | Fixture topic |
|--------------|---------------|
| renewable energy storage | `renewable-energy-storage` |
| AI safety alignment | `ai-safety-alignment` |
| Open LLM Orchestrator | `olo-open-llm-orchestrator` |

## Sample prompt (recommended)

```text
Produce a structured literature review on AI safety alignment for multi-agent orchestration.
Find key papers, synthesize evidence, identify research gaps, and publish an executive research brief.
```

### Shorter prompts

| Prompt | What it exercises |
|--------|-------------------|
| `Find academic papers on renewable energy storage` | research-literature + paper-discovery-agent |
| `Search recent surveys on LLM agent frameworks` | web-search + evidence-synthesis-agent |
| `What gaps remain in AI safety alignment research?` | gap-analysis-agent |
| `Write an executive brief on OLO-style orchestration` | research-brief-agent |

## Regenerate JSON

```bash
./gradlew :olo-definition:generateLiteratureReview
```

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `literature-review`. See [current-active/README.md](../current-active/README.md).

## Tests

- `LiteratureReviewConfigurationTest`
- `LiteratureReviewRegenerationTest`

## Contributors and owners

Contributions are welcome. Start with [CONTRIBUTING.md](../../../CONTRIBUTING.md), use the [contributor guide](../../../docs/CONTRIBUTOR_GUIDE.md) to find the right module or scenario, route review through [OWNERS.md](../../../OWNERS.md), and record meaningful module or scenario credit in [CREDITS.md](../../../CREDITS.md).
