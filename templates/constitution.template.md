# Constitution: [Project Name]

<!-- The constitution defines the non-negotiable principles for this project.
     Every task Forge generates will be checked against these rules.
     Be specific. Vague principles are unenforceable.
     Aim for 5–10 rules that are each independently checkable. -->

## Core Principles

<!-- 3–7 values that govern every decision. Think about what you'd refuse to compromise on
     even under deadline pressure. What have you regretted not enforcing before? -->

1. 
2. 
3. 

## Quality Bar

<!-- What level of quality is the minimum bar? What does "done" actually mean? -->

- Minimum acceptable quality: 
- Definition of done: 
- What we never ship: 

## Hard Constraints

<!-- Rules with no exceptions. These become Global Constraints injected into every Forge task.
     Write them as checkable assertions — something that can be verified true or false.
     Examples:
       - "No external dependencies without explicit approval"
       - "All user-facing text reviewed for clarity before shipping"
       - "No changes merged without a second review"
       - "Secrets never stored in source control" -->

- 
- 
- 

## Operating Conventions

<!-- How agents should interact with your working environment while executing tasks.
     Unlike Hard Constraints (rules about what the code/output must BE), these describe
     HOW work is performed so agents don't stomp on running processes, shared resources,
     or your dev loop. These flow into the generated spec and shape task verification.

     The most important convention is the app lifecycle mode, which governs how the
     verifier interacts with any long-running process the project produces:

       - "Lifecycle: oneshot"
         No long-running process — exercise commands run to completion (CLIs, scripts,
         batch jobs, data pipelines).

       - "Lifecycle: external"
         I keep the app running myself (separate terminal, hot-reload / file watcher).
         Verifier must NOT start or stop the app — it runs checks against the already-
         running instance. If the app isn't reachable, verification fails loudly so I
         can start it and retry. Assumes your dev loop reflects current code.

       - "Lifecycle: managed"
         Verifier owns a dedicated instance (typically on a separate port) that it
         starts and stops. My own dev instance, if any, stays untouched. Use this when
         there's no reliable hot-reload, or when isolation from my dev state matters.

     Other examples of conventions worth stating:
       - "Shared dev database — never drop or recreate; migrations only"
       - "Do not kill processes by name without confirmation"
       - "Port 3000 is mine; agents may use 4000-4099 for spawned instances" -->

- 
- 

## Out of Scope — Forever

<!-- What will this project explicitly never do, no matter how reasonable it sounds?
     Stating non-goals prevents scope creep and saves time arguing later. -->

- 
- 

## Review Standards

<!-- How is work evaluated? What approval is needed before something is considered done? -->

- 
