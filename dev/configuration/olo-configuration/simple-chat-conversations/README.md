<!--
Copyright (c) 2026 Olo Labs
SPDX-License-Identifier: Apache-2.0
-->
# Simple chat conversations

Small focused chat pipelines that load prior conversation, answer as a role-specific assistant, and store the current turn for later runs. These pipelines do not include human approval or orchestration steps.

| Workflow | Role |
|----------|------|
| `end-user-reply-chat` | Friendly end-user support replies |
| `architect-chat` | Architecture and design conversation |
| `traveler-chat` | Travel preference and itinerary conversation |
| `literature-chat` | Literature, reading, and interpretation conversation |
| `teacher-chat` | Step-by-step teaching conversation |
| `reviewer-chat` | Review and critique conversation |

## Flow

Each workflow uses the same pipeline shape:

1. `START` maps caller input into `message`.
2. `conversation-load` restores `conversationSummary` and `conversationHistory`.
3. `agent` replies with a role-specific system prompt.
4. `conversation-store` saves the turn.
5. `END` returns the assistant response.

There is no `HUMAN` node in this collection.

## Sample prompts

```text
For end-user-reply-chat:
I cannot find the document I uploaded earlier. Can you help me phrase the next message?

For architect-chat:
Help me think through a worker-to-vector-db integration design and its failure modes.

For traveler-chat:
Plan a relaxed 3-day trip for someone who likes museums and walkable neighborhoods.

For literature-chat:
Compare unreliable narration in two novels and help me shape an essay thesis.

For teacher-chat:
Teach me vector search from first principles, assuming I know basic Java.

For reviewer-chat:
Review this proposed API behavior and point out ambiguity or missing edge cases.
```

## Regenerate

From `olo-definition/olo-definition`:

```bash
./gradlew :olo-definition:generateSimpleChatConversations
```

## Contributors and owners

Contributions are welcome. Start with [CONTRIBUTING.md](../../CONTRIBUTING.md), use the [contributor guide](../../docs/CONTRIBUTOR_GUIDE.md) to find the right module or scenario, route review through [OWNERS.md](../../OWNERS.md), and record meaningful module or scenario credit in [CREDITS.md](../../CREDITS.md).
