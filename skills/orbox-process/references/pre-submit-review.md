# Pre-submit check

Run this before you tell the user a process is ready to submit, and whenever they ask whether it is ready.

## 1. Structure: `validate_process_draft`

Call `validate_process_draft` (or read the findings returned by your last batch). Fix structural blockers yourself with the flow tools: a missing connection, a dead end, an orphan step, an unlabelled branch. Ask the user only for missing domain facts (an owner, an executor, what a step does), never fill them in yourself.

## 2. Content: read it as a newcomer would

Load the draft fresh with `get_process_draft` and judge only what is written there, not what you remember from the conversation. If your host can run a subagent with a fresh context, give it this file and the draft.

For each work step:

- **Who**: is there an executor, or is it recorded as unknown?
- **Input**: is it clear what the step starts from and where that comes from?
- **How**: does `Jak` say how the work is done, rather than repeat the title?
- **Output**: is it clear what the step leaves behind and how you tell it was done right?
- **Where**: when the step is done in a tool, does it say where inside the tool?

For the process as a whole:

- It starts at the trigger and ends in the stated result, and the result reaches whoever is waiting for it.
- Every decision says what it is decided on, and its outcomes are real branches in the flow, not just a sentence in the prose.
- Before a step that moves money, does something irreversible or goes outside the organization, it is clear what must hold first.
- The steps fit the header's purpose, input and output.

Not gaps: fields recorded as unknown, the locator placeholder, missing step SLAs, and "what if" scenarios the user never raised.

## 3. Take the gaps to the user

Ask about the content gaps in batches of 2–4, most important first, phrased about their work ("What does the manager base the approval on?"), not about the diagram. Write each answer into the draft as it arrives. When the user chooses to leave a gap, accept it and mention it in the closing summary.

When the check comes back clean, close per `interview.md` (Phase 3).
