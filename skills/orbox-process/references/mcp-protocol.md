# Working with the Orbox MCP tools

Read this before the first Orbox call. The tool descriptions define each payload; this file covers how to use the tools together safely.

## Connection

The server is `https://orbox.dev/api/mcp` (production). The user connects it with OAuth (sign in through the browser and pick read-only or read/write) or with a personal API token for scripts. Either way you act as that user, inside their organization, with their permissions.

A **read-only** connection lists only the read tools. Never claim to have created, edited, submitted or archived anything over it; tell the user that mapping needs a read/write connection.

## Tool map

| Need | Tool |
|---|---|
| Entity types and their fields (do this once, early) | `get_catalog` (full schema) / `list_entity_types` |
| Find catalog entities | `search_entities` (`search` matches names, `typeSlug` filters a type, paginate with `nextCursor`) |
| Read one entity / its relationships | `get_entity` / `get_entity_relations` |
| Propose one new entity / many at once | `propose_entity` / `propose_entities` (always created as `proposed`; a person activates them in Orbox) |
| Change / retire an entity | `update_entity` / `retire_entity` |
| Link / unlink two entities | `add_entity_relation` / `remove_entity_relation` |
| Find processes | `search_processes` |
| Read a committed process / its open draft / its processing status | `get_process` / `get_process_draft` / `get_process_status` |
| Start a new process | `create_process_draft` |
| Reopen an active process for editing | `reopen_process_for_edit` |
| **Several draft changes in one atomic write** | `batch_edit_process_draft` |
| Process header fields and body sections | `update_process_draft` |
| Add / change / remove a step | `add_process_step` / `update_process_step` / `remove_process_step` |
| Sequence connection | `connect_process_steps` / `disconnect_process_steps` |
| Split (decision, parallel work) | `set_process_branch` / `clear_process_branch` |
| Join (parallel convergence) | `set_process_join` / `clear_process_join` |
| Check the draft against the submit requirements | `validate_process_draft` |
| Submit the draft | `submit_process_draft`, then poll `get_process_status` |
| Archive an obsolete process | `archive_process` (soft delete; only on explicit request) |

The server has no semantic entity search and no structured-question tool. Search entities by several name variants (`entities.md`) and ask questions with your host's own tools.

## Batch edits

`batch_edit_process_draft` applies an ordered list of `ops` to an open draft in ONE atomic write: one `requestId`, one write unit, one new revision. Prefer it for any change of more than about two operations; use the granular tools for a single targeted fix.

- Each op is `{"op": <type>, …}` with the fields of the matching granular tool, minus `requestId`, `id` and `expectedRevision`. Types: `update_draft` (`meta`, `bodySections`), `add_step`, `update_step`, `remove_step`, `connect_steps`, `disconnect_steps`, `set_branch`, `clear_branch`, `set_join`, `clear_join`.
- `add_step` may declare a `ref` (lowercase, e.g. `"check_invoice"`). Later ops in the SAME batch may use that ref anywhere a step id goes. Refs are the one exception to "never invent step ids"; they are never stored, so after the batch use the returned `refs` map (ref → step id).
- Flow structure is checked only on the final state, so the order of connect/disconnect inside a batch does not matter.
- All or nothing: on failure nothing changed, and the error names the failing op by `opIndex` and `opType`. Fix that op and resend the whole batch with a NEW `requestId`.
- The response carries the full draft, its validation findings and the new revision. Use them instead of a follow-up `get_process_draft` or `validate_process_draft`.
- Limits: 100 ops and 512 KB per batch. Draft creation, reopen, submit, archive and entity writes are not batch ops.

Adding the next step in discovery, in one call:

```json
{
  "requestId": "<new uuid>",
  "id": "<processId>",
  "expectedRevision": "<draft revision>",
  "ops": [
    { "op": "add_step", "ref": "approve", "kind": "task", "title": "Approve the invoice",
      "assigneeIds": ["<role id>"], "toolId": "<tool id>",
      "bodySections": [
        { "section": "Vstupy", "markdown": "…" },
        { "section": "Jak", "markdown": "…" },
        { "section": "Výstupy", "markdown": "…" }
      ] },
    { "op": "disconnect_steps", "fromStepId": "<last step id>", "toStepId": "<end step id>" },
    { "op": "connect_steps", "fromStepId": "<last step id>", "toStepId": "approve" },
    { "op": "connect_steps", "fromStepId": "approve", "toStepId": "<end step id>" }
  ]
}
```

## Write protocol

- **`requestId` on every write.** Generate a fresh unique id per intended change (a UUID is fine). If a write's outcome is uncertain (timeout, dropped connection), retry with the SAME `requestId`: the server replays the recorded outcome instead of applying the change twice. Never reuse a `requestId` for a different change (`REQUEST_ID_REUSE`). A recorded failure (`PROCESS_NOT_READY`, a failed batch) is replayed too, so after fixing the cause, retry with a NEW `requestId`.
- **`expectedRevision` on every edit.** Draft edits take the draft revision from `get_process_draft`; every successful draft write returns the new `revision`, so use that for the next write. `reopen_process_for_edit` and `archive_process` take the committed revision from `get_process`. Entity edits take the entity's revision from `get_entity` / `search_entities`.
- **After `STALE_REVISION`**, someone else (the user in the Orbox editor, another agent) changed the record. Re-read it, check whether your change still makes sense, and only then write again with a new `requestId`. Never blindly retry with the new revision.
- **Targeted changes only.** Omitted fields are preserved. Send only what you are changing. A `bodySections` entry with an empty string clears that section.
- **Steps are addressed by the ids the server returns** (or by batch refs inside one batch), never by title. Keep the ids of the steps you create, especially the `start` and `end` steps.
- **Connection ids change whenever the flow is rebuilt.** After a structural edit, use the returned draft or re-read `get_process_draft` instead of relying on connections you saw earlier. Removing a step prunes its connections and may drop a split or join left with fewer than two branches.
- **`PROCESS_BUSY`**: the built-in Orbox agent is working on the same draft. Wait and retry later.
- **`NO_OPEN_DRAFT`**: the process has no open draft (e.g. it is active). Reopen it first (`edit-round.md`).
- **`VALIDATION`**: the input broke a rule (unknown field, wrong entity type for a field, `[[…]]` token in text, etc.). Read the message, fix the input; do not retry unchanged.
- **`FORBIDDEN` / `EXTERNAL_WRITES_DISABLED`**: the connection is read-only, or writes are switched off for this deployment. Tell the user; you cannot work around it.
- **`TOO_MANY_REQUESTS`**: honour `retryAfterSeconds` before trying again. Reads and writes share per-user and per-organization budgets, so keep list paging and status polling bounded, and prefer one batch over many small writes.

## Text fields and mentions

- Prose fields (`ucel`, `vstup`, `vystup`, `trigger`, process `bodySections`, step `bodySections`) accept `@ExactName` mentions; the server resolves them to catalog links at write time. The entity must exist in the catalog first (`entities.md`).
- Plain-text fields take no mentions: process `name`, `domain`, `sla`, `frequency`, `reviewFrequency`; step `title`, `sla`; branch `label` / `condition`; join `label`.
- **Never write `[[ref:…]]`, `[[entity:…]]` or any other bracket token anywhere.** Reads render mentions as `@Name` and list the resolved targets in `references`; refer to records by those ids.

## Field identifiers (fixed, whatever the content language)

The API's identifiers are Czech. Use them exactly as listed; write the *content* in the agreed language.

**Process header** (`update_process_draft` → `meta`, or a batch `update_draft` op):

| Identifier | Meaning |
|---|---|
| `name` | process name |
| `ucel` | purpose: why the process exists, what it should leave behind, who uses the result |
| `vstup` | input: the trigger in human terms, required inputs, the main object the process works on (case, request, incident) |
| `vystup` | output: what the process produces and who or what receives it next |
| `trigger` | the concrete event that starts the process |
| `ownerId` | accountable **role** (entity id) |
| `escalationId` | escalation **role** (entity id) |
| `teamId` | owning **team** (entity id) |
| `sla` / `noTimeLimit` | maximum process duration (`8h`, `5 days`, `best effort`) / explicitly no time limit |
| `frequency`, `reviewFrequency`, `impact` (`High`/`Medium`/`Low`), `domain` | operational metadata |

**Process body sections** (`bodySections`, a map of section name → markdown). Exactly these names:

| Section name | Content |
|---|---|
| `Scope procesu` | what the process covers and excludes, where it starts and ends |
| `Flow logika` | the main path, decisions, rework and handoffs, as prose, not a step list |
| `Mapa autority` | where the process state is kept, documents and approvals |
| `Kontrolní logika a eskalace` | what is checked, what blocks progress, when it is escalated |

Write concrete facts only and omit a section with no real basis. Do not copy the step breakdown or the header values into the body.

**Steps** (`add_process_step` / `update_process_step`, or batch `add_step` / `update_step`):

| Identifier | Meaning |
|---|---|
| `title` | short step name, plain text |
| `kind` | `start`, `task` or `end` |
| `assigneeIds` | executor pool: ids of `role` or `automatizace` entities (any one of them may do the step) |
| `toolId` | the single tool/system: id of a `nastroj` entity |
| `sla` / `noTimeLimit` | step duration, only when the user stated it |
| `assigneesUnknown` / `toolUnknown` / `slaUnknown` | the user said they do not know |
| `bodySections` | list of `{ section, markdown }`; `section` is exactly `Vstupy` (inputs), `Jak` (how), or `Výstupy` (outputs) |

**Entity type slugs** you will meet: `role`, `tym` (team), `nastroj` (tool/system), `pravidlo` (rule), `znalost` (knowledge source), `automatizace` (automation). The authoritative list, with each type's fields, comes from `get_catalog`.

## Draft lifecycle

1. `create_process_draft` (optionally with `name`) returns `processId` and a `revision`. The draft is visible in Orbox at `/process/<processId>`. It never becomes active by itself.
2. Edit it with the draft tools. Incomplete drafts are fine: steps may sit unconnected while you build.
3. `validate_process_draft` is a read-only dry run of the submit gate: it returns blocking findings and warnings without changing anything. Resolve the blockers.
4. `submit_process_draft` (only on the user's explicit request) checks the same requirements. If they are not met, it returns `PROCESS_NOT_READY` and changes nothing. Otherwise it returns `waiting_for_processing` with a `workflowRunId`. **The process is NOT active yet.**
5. Poll `get_process_status` at a modest pace (e.g. every 10–20 s, bounded) until `terminal` is `true`. Report the process as active **only** when `isActive` is `true`. A failed processing run is reported as such, never as active.

## Submission requirements

The submit gate (and `validate_process_draft`) checks:

- header: name, purpose (`ucel`), input (`vstup`), output (`vystup`), owner, team, escalation, trigger, and a max duration or `noTimeLimit`;
- the process max duration is not shorter than the longest path through the step SLAs;
- at least one non-empty body section and at least one step;
- an `end` reachable from a `start`, and every step reachable from a start and able to reach an end;
- every `task` step has a title, an executor or `assigneesUnknown`, and non-empty `Vstupy`, `Jak`, `Výstupy`;
- every non-end step has a continuation and every non-start step has an incoming connection;
- every split has at least two branches, every `exclusive`/`inclusive` branch has a label, every join has at least two inputs, and a `complex` join has a threshold within `1..inputs`.

These are the structural minimum, not a quality bar. A draft can pass all of them and still be unusable; that is what `pre-submit-review.md` is for.
