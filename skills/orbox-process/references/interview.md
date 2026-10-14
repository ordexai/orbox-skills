# Discovery interview

How a discovery session runs. Step structure is in `steps.md`, entities in `entities.md`, branching in `gateways.md`.

Every question costs the user time. Aim for the shortest description from which someone new to this organization could run the process, and ask only what moves the process forward.

Keep working notes outside the process: the ids of the steps you created, term → entity id decisions, and where inside each tool the user said the work happens.

## Phase 1: Understand

1. **Create the draft once the topic is clear.** `create_process_draft` with a `name` derived from the user's description. Do not ask whether they want a new process; they described one.
2. **Store header fields as you learn them** (`update_process_draft`): `name`, `trigger`, owner (`ownerId`, a role), escalation (`escalationId`, a role), team (`teamId`). **Never infer the owner.** A role that acts somewhere in the story executes a step; it is not necessarily accountable for the process. Set the owner only from the user's answer to a question about ownership.
3. **Anchor both ends.** Ask what starts the process and what exists once it is over. The moment either answer arrives, add it as a boundary step (`kind: "start"` / `kind: "end"`, a short plain-text title, nothing else) and keep its id. Leave the two unconnected; the first work step bridges them. If the user later rephrases an endpoint, update the SAME step.
4. **Resolve the entities** the user named (roles, teams, tools, automations) per `entities.md`, and use them as `@ExactName` from your next reply on.

Move on once the trigger, the end and the main header fields are known. Do it in the same turn as the first question of Phase 2 ("Got it. When the signed contract arrives, what happens first?").

## Phase 2: Build

Walk from the trigger to the end, one step and one short question at a time: "And what happens next?", "Who does that?", "Which system is it done in?", "How do you know it's done?".

1. **Take the next step from what the user described.** Never lay out a skeleton of steps first, and never offer a list of steps you assembled yourself for confirmation. If the user's answer bundles several roles, tools or outputs, split it per `steps.md`.
2. **Ground that one step.** What it produces, who does it (a role, or an automation when no person is involved), what it starts from, how the work is done, and, when it is done in a tool, where inside the tool. Ask what is missing; questions that do not depend on each other go in one batch.
3. **Write it and wire it in, in one `batch_edit_process_draft`** (example in `mcp-protocol.md`):
   - the **first** work step: `add_step`, then connect `start → step` and `step → end`;
   - every **later** step: `add_step`, disconnect `last → end`, connect `last → new` and `new → end`. Without the disconnect the old connection stays as a shortcut past the new step.
   - decisions, parallel work and rework: `gateways.md`.
4. New facts about an existing step go in with `update_step` on its id. Sending a body section replaces it, so start from the current text.

One step per turn: never build the whole flow in one go, not even as bare titles.

**Map how it runs when it goes right.** Do not ask on your own initiative what happens if someone does not respond, a deadline passes or a system is down. When the user mentions a real deviation, note it and model it once the main path is complete (`gateways.md`). For a step that moves money, does something irreversible or goes outside the organization, ask what has to be true before it may proceed.

When the user names a company document, record or form, ask what it contains and where it comes from; the system it lives in does not answer that.

As facts accumulate, write `ucel`, `vstup`, `vystup` and the body sections (`mcp-protocol.md`). Concrete facts only; leave out a section with no basis.

## Phase 3: Finalize

1. If the user never stated the process maximum duration, ask once ("How long may the whole process take at most, or has it no time limit?") and store `sla` or `noTimeLimit`. Never estimate it.
2. Run the review in `pre-submit-review.md`. Fix structural findings yourself; take content gaps to the user.
3. **Close** with a short message:
   - the process in a few lines (trigger → main path → result, owner);
   - what stayed open: gaps the user chose to leave, fields recorded as unknown;
   - where to see it: Orbox, `/process/<processId>`;
   - the next action: the draft is ready to submit, and the user can tell you to submit it or do it in Orbox.
4. **Submit only on explicit request**, then poll `get_process_status` and report the outcome truthfully (`mcp-protocol.md`). Never call a process active before `isActive` is `true`.

An unfinished session still has value: what exists is saved in the draft. Name what is left and ask which part to pick up next.

## You decide, the user answers

Decide yourself, without asking: how to split steps, how decisions and parallel work are drawn, which tool calls to make and when, and how content is formatted.

Ask the user: what actually happens next, who does it, what it starts from, what "done" means, and whether a draft value of yours is right.

## Empty values

In order of preference: get the real content from the user; propose a value and wait for an explicit yes; leave it empty and say so. Never invent an SLA, a role or a procedure to fill a field.
