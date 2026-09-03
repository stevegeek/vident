# Who made this, and how carefully

*A [Rigor, Vouch, Stages](https://rigor.diaconou.com/) disclosure stamp. The format and vocabulary are specified at [rigor.diaconou.com/spec](https://rigor.diaconou.com/spec/), version 1.0.*

<!-- rigor:summary -->
**The idea was mine. Before LLMs, the plan was mine, and worked in depth over
iterations; the implementation was written by me; it was reviewed for quality
and for security, and tested, all by me. Since LLMs, the plan and the
implementation have been reworked by me with an AI, and it has been reviewed for
quality and tested, both by me with an AI; and reviewed for security by an AI.
The project is complete; it will not gain new features. I stand behind this code
as soundly engineered and hold architectural responsibility for it. This
assessment is as of 2026-09-03. I recommend this for use; I put my name behind
it. Statement made by: Stephen Ierodiaconou.**
<!-- /rigor:summary -->

## Notes

Vident began in 2018, inside a private project, as a view component library
of its own; decor was the set of UI components built on it. The setup later
moved onto GitHub's view_component gem, and in 2022 I extracted Vident and
open-sourced it as a Stimulus DSL over view_component, adding Phlex support
after. All of that was before AI: the architecture, the code, the reviews, and
a test suite I kept in good order, are mine, by hand. The implementation in
that era also had help from Tom Spencer and other contributors; the planning
was mine alone.

After AI, Vident was substantially refactored alongside decor, with an AI: new
features, updated DSLs, fixes, and more tests on top of the existing suite. I
have read that work and can account for it. Quality review and testing since
then were mine with an AI; security review since then was the AI's alone.

Vident is mostly feature complete and I intend to keep it active: fixes,
performance work, and updates for new Rails, view_component and Phlex
releases. That is `activity: active` with `scope: complete`. I use it myself
and I recommend it.

## Stamp

```yaml
spec: "1.0"
signed: "Stephen Ierodiaconou"
rigor: owned
vouch: yes
checks:
  comprehended: [human, human-with-ai]
  quality_reviewed: [human, human-with-ai]
  security_reviewed: [human, ai]
  tested: [human, human-with-ai]
  owned: human
stages:
  idea: {by: human}
  plan: {by: [human, human-with-ai], depth: deep}
  implementation: {by: [human, human-with-ai]}
  maintenance: {by: human-with-ai, activity: active, scope: complete}
assessed: 2026-09-03
```

<!--
checks: surface any subset; a done value names who did it.
  comprehended / quality_reviewed / security_reviewed / tested / owned:
    yes | human | ai | human-with-ai | no | not-applicable,
    or a pair [before LLMs, since LLMs] of actors.
  engineered and owned must surface the checks they imply; comprehended
  cannot be satisfied by an AI alone.
Run `rigor-md fmt RIGOR.md` after editing the stamp to refresh the summary.
-->