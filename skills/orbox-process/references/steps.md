# Steps: granularity, structure and completeness

Turn what the user described into concrete steps. Quality depends on useful boundaries (neither oversized steps nor needless fragmentation) and on recording only facts the user gave or confirmed.

## 1. What is one step?

A step normally has:

- one clear input (what must be ready for it to start);
- one clear output (an artifact or state change it leaves behind);
- one executor position (one role or automation, or a pool of interchangeable ones; see *Executor*);
- at most one tool/system;
- no internal handoff or system switch.

**Boundary rule:** end a step when another role takes over or the work moves to another tool. "Find it in A and fill it into B" is two steps. Several inputs or outputs may stay in one step when they belong to the same unit of work.

## 2. Signals that a "step" is really a sequence

- "and then", "after that", "once … is done";
- several systems used one after another;
- several distinct outputs or decisions;
- a handoff between roles;
- a catch-all verb ("process", "handle", "prepare", "check") instead of a concrete piece of work.

These are signals, not proof. Keep one step when the apparent sequence is just the inner detail of one action by one executor in one tool.

Example: "I prepare the supplier contract" may really be: find the supplier in the CRM → check the record is complete → generate the contract from the template → fill in the commercial terms in Word → attach it to the procurement ticket.

Conditional results (approved/rejected, passes/fails), parallel work and rework are branches, not a straight line; see `gateways.md`.

## 3. Step structure: header plus three body sections

Rendered in Orbox roughly like this:

```markdown
### 3. Check the supplier invoice against the order (Accounts Payable Clerk)

**Tool:** @Xero
**Who:** @Accounts Payable Clerk

#### Vstupy
The supplier invoice from the *Invoices to approve* queue in @Xero and the matching purchase order number.

#### Jak
The @Accounts Payable Clerk opens the invoice in @Xero in the *Invoices to approve* queue, finds the purchase order by the number on the invoice and compares amount, quantities and supplier bank account. If the bank account differs from the one on record, the clerk stops and escalates to the @Finance Manager.

#### Výstupy
The invoice is marked *Matched* in @Xero. ☐ Amount and quantities agree with the purchase order. ☐ The bank account matches the supplier record.
```

**Header fields:**

- **Executor** (`assigneeIds`): any one of them may do the step; it is not a list of co-participants. Each entry is a `role` when a PERSON does the work or an `automatizace` when a MACHINE does it (script, integration, RPA, workflow, AI agent); see `entities.md`. Never a named person; map a person to their role.
- **SLA** (`sla`): free text such as `8h`, `2 days`, `best effort`. Not required for a step, and never asked for. Record it only when the user states it, as a bare `<number> <unit>` or `best effort`; `noTimeLimit: true` for "no deadline", `slaUnknown: true` for "don't know".
- **Tool** (`toolId`): at most one `nastroj` entity. Omit it when the step uses no specific system; `toolUnknown: true` when the user does not know.

**Exactly three body sections** (`bodySections`, identifiers fixed):

- **`Vstupy`**: what must be ready before the step starts, and where it comes from;
- **`Jak`**: prose describing how the executor does the work, with exceptions and escalation inline ("If X, escalates to the @Legal Counsel");
- **`Výstupy`**: what the step leaves behind and how you tell it was done right; use `☐` for checklist-style criteria.

The primary tool goes in `toolId`, an executing automation in `assigneeIds`. Rules, knowledge sources and other entities go as `@ExactName` mentions in `Jak` or `Výstupy`; the entity must exist in the catalog first (`entities.md`). The `@` in the rendered **Tool** and **Who** lines is only how Orbox displays the ids; set those fields with ids.

Write in the third person as fluent prose ("The clerk checks…"), not imperatives or telegraphic bullets.

## 4. Write down what the user told you

- **`Jak` must not restate the title.** "The clerk enters the data into @ERP" says nothing new. Write what is entered, from where, and in what form, using the specifics the user gave (field names, amounts, who signs, what is checked against what).
- **`Výstupy` must not be the title in the past tense.** Name what now exists and how a reader recognises it is right.
- **A decision step says what the decision is based on.** "The manager reviews the request and decides" is not enough; ask for the criterion and write it into `Jak`.
- **A step done in a tool says where inside it** (the locator):
  - a fixed place (folder, project, board, channel, form, saved view): name it, with its link if the user has one;
  - a record that is different every time (a ticket, a deal, a payment): describe how to find it, for example the view or filter, or the identifier it is looked up by;
  - when the user has neither, write `(add link)` (in the content language) where the link belongs. Never invent a URL. A step that only *sends* something out (an e-mail, a message) has no locator; write who receives it instead.
- **The result has to reach whoever is waiting for it.** If nobody is told the outcome, the path is not complete: ask how they find out, and add that step.

## 5. Step completeness

| Question | Where it belongs |
|---|---|
| **What** (output) | `Výstupy` |
| **Who** (executor) | `assigneeIds`, or `assigneesUnknown` |
| **Where** (place inside the tool) | `Vstupy` and `Jak`, as prose |
| **When** (input; SLA if stated) | `Vstupy`; `sla` |
| **How** (the work) | `Jak` |

Without What, Who, How or the input, a task cannot be submitted. Where is prose, so no check sees it: a step can pass every structural check and still never say where the work happens. A missing step SLA is not a defect. `start`, `end` and gateway nodes are exempt.

Ask about what is missing instead of guessing; independent gaps go in one batch of questions.

## 6. Writing steps

- Add each step and wire it into the flow in the same write, preferably one `batch_edit_process_draft` per turn (`mcp-protocol.md`, `interview.md`). Keep the returned step ids.
- Later changes go through `update_step` / `update_process_step` on that id; only the fields you send change. Sending a body section replaces that section's text, so read the current text first.
- Do not leave a step floating. The only exception is the pair of boundary steps, which stay unconnected until the first work step bridges them; never connect `start → end` directly.
- Gateways are routing nodes without body, executor, SLA or tool. They are created by branch and join operations, never with `add_step`.
