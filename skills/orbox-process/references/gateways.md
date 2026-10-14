# Branching and gateways

This file explains **when and how to branch**. The tool descriptions define the payload of `set_process_branch` and `set_process_join`. Gateways are routing nodes, not work steps: they are created as a side effect of `set_process_branch` / `set_process_join` on existing work steps.

## 1. When to model a branch

A process is rarely a straight line. Add a branch whenever the description contains a decision or a division of work:

- "if / when / in case…";
- a check that **passes / fails**, a request that is **approved / rejected**;
- an **exception** to the normal procedure the user says really happens;
- activities running **concurrently / in parallel / at the same time**;
- **return for rework** (correction followed by another attempt).

Never hide a decision in a linear chain. "Check it and return it for correction if needed" is not one step: it is a check step, a split, and a return path. A conditional outcome belongs in the flow, not only in a step's prose.

## 2. Choose the gateway type

| Type | Use when | Example |
|---|---|---|
| `exclusive` (XOR) | exactly ONE branch is taken | check result yes/no, approved/rejected |
| `parallel` (AND) | ALL branches run concurrently | automated check and peer review at the same time |
| `inclusive` (OR) | one or more branches run according to conditions | escalation goes to several destinations depending on incident type |
| `complex` (N of M) | a join needs a threshold of how many inputs suffice | approval from 2 of 3 approvers is enough |

Most cases are `exclusive` or `parallel`. Use `inclusive` or `complex` only when the facts require them.

## 3. Map the decision to flow calls

- **Split:** `set_process_branch` on the work step where the flow divides into at least two branches. For `exclusive` and `inclusive`, every branch needs a non-empty `label` ("Yes", "No", "Critical", "Standard"). The split's own `label` should be a question about the outcome ("Checks passed?").
- **Mark the positive and the negative branch:** when a split is a positive/negative pair — Yes/No, Approved/Rejected, Passes/Fails — set `polarity: "yes"` on the branch that continues the desired outcome and `polarity: "no"` on the one that refuses, fails or sends the work back. Orbox draws them green and red. Leave `polarity` unset on splits with no positive side (Critical/Standard, Company/Individual), on `parallel` splits, and on a catch-all branch unless it genuinely is the negative outcome.
- **Every `exclusive` split needs a catch-all branch — usually one you already have.** Exactly one branch carries no `condition`; that branch is the default/else. When the branches already cover every outcome (a real Yes/No pair), leave the broader one's `condition` empty and state its meaning in its `label`. Add a further branch only when a result genuinely falls outside the existing ones, and then it must lead somewhere the others do not (typically escalation or an unusual-case end). **Branches must target distinct steps** — two branches into the same step is not a choice and the server rejects it.
- **One way out of a work step.** A step has a single continuation; only a split fans out. Do not connect a step to a second target to express an alternative, and when a step becomes a branch point, remove its plain continuation (`disconnect_process_steps`) — the step it used to point at belongs in the branch list.
- **Join:** `set_process_join` on the step where at least two concurrent paths converge. A join is never `exclusive`: mutually exclusive paths simply both `connect_process_steps` to the same next step. Use a join for `parallel`, `inclusive` or `complex` convergence; `complex` takes a `threshold` within `1..inputs`.
- **Parallel or inclusive flow** normally needs both a split and a matching join.

In a `batch_edit_process_draft` the same operations are the `set_branch`, `clear_branch`, `set_join` and `clear_join` ops, and branch targets may be refs of steps added earlier in the same batch, so a check step, its split and both branch targets can go in one call. After any structural change, use the draft the batch returned (or re-read `get_process_draft`) before relying on connection ids.

## 4. Rework loops

For "return for correction", use an `exclusive` split: one branch continues, another branch points to an earlier correction step that leads back to the check. Use `connect_process_steps` only for ordinary sequence connections, not for the outgoing branches of a split.

Every rework loop needs an exit so it cannot run forever: a branch such as "No (after the Nth attempt)" to escalation or an unsuccessful end, or another route from the loop to an `end`. Do not invent the retry limit N; if the business has no bounded exit, ask about that before finalizing the loop.

If a join must be followed by a split, put a small work step between them ("Evaluate the checks"). Joins and splits attach to work steps, not to each other.

## 5. Keep the graph coherent

`validate_process_draft` (and every batch response) reports the structural blockers. Check the graph yourself as well after structural edits:

- at least one `start` and one `end`; every work step reachable from a start and able to reach an end;
- every non-end step has a continuation; every non-start step has an incoming connection;
- a split has at least two branches, every `exclusive`/`inclusive` branch has a label, a join has at least two inputs, a `complex` join has an in-range threshold;
- every `exclusive` split has exactly one catch-all branch without a `condition`;
- no loop lacks an exit.

Repair what you find silently with the flow tools. Gateways have no body, executor, SLA or escalation.

## 6. Example: code review with parallel work and rework

Flow: a pull request opens → automated checks and peer review run **in parallel** → they converge → "Checks passed?" → yes: merge and deploy; no: the author fixes the issues and the checks are evaluated again.

Model: `start` → "Open pull request" → `parallel` split into "Automated checks" and "Peer review" → `parallel` join into "Evaluate the checks" → `exclusive` split "Checks passed?" with "Yes" (`polarity: "yes"`) → "Merge and deploy" → `end`, and "No" (`polarity: "no"`) → "Author fixes the issues" → back to "Evaluate the checks". Add the confirmed bounded exit for repeated failures so the loop cannot be infinite.
