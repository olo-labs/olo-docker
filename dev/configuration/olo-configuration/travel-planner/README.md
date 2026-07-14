<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Travel planner scenario

End-to-end scenario for trip planning. A tool-call orchestrator queries mock destination and offer catalogs, delegates itinerary work to specialist **child workflows**.

| Workflow | Role | Queue |
|----------|------|-------|
| `travel-orchestrator` | Tool-call planner + delegation | `oloQueue2` |
| `destination-agent` | City and highlight recommendations (child workflow) | `oloQueue2` |
| `itinerary-agent` | Day-by-day itinerary builder (child workflow) | `oloQueue2` |

## Mock tools

| Tool ID | Purpose | Key arguments |
|---------|---------|---------------|
| `olo-core:travel-destinations` | Destination guides | `region` |
| `olo-core:travel-offers` | Flight/hotel offers | `origin`, `destination` |

## Sample prompt (recommended)

```text
Plan a weekend trip from London to Paris in Europe.
Find destination highlights and compare travel offers, then build a day-by-day itinerary.
```

### Shorter prompts

| Prompt | What it exercises |
|--------|-------------------|
| `Suggest destinations in Europe for summer` | travel-destinations tool |
| `Find weekend offers from London to Paris` | travel-offers tool |
| `Build a 2-day Paris itinerary with museums and food` | itinerary-agent |

## Regenerate JSON

```bash
./gradlew :olo-definition:generateTravelPlanner
```

## Activate scenario

**Recommended:** olo-ui → **Administration → Scenarios** → **Activate** `travel-planner`. See [current-active/README.md](../current-active/README.md).

## Load in worker

Default local config scans `current-active/`. To scan this folder directly:

```yaml
workflowDefinitions:
  scanFolder: "../../olo-definition/olo-configuration/travel-planner"
```

## Tests

- `TravelPlannerConfigurationTest`
- `TravelPlannerEndToEndTest` (olo-kernel)
