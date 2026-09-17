[English](./README.en.md) | [日本語](./README.md)

# second-opinion

**You ask the AI for advice, and it always sounds plausible.**

Whether you ask about a design decision or a bug you're stuck on, the answer usually sounds coherent and hard to argue with. But is it really the result of thorough consideration? The same model tends to rate its own proposals highly and to lean toward whatever direction you hinted at.

second-opinion **hands only the problem to a model from a different family, lets it answer independently, and then compares that answer with your own.** From Claude Code it asks Codex; from Codex it asks Claude Code. Your proposal is never shown to the other model, so its answer is an independent view rather than an echo.

## Who this is for

- You use both Claude Code and Codex CLI and suspect one model's habits are steering you
- You want a second brain before a design decision without pasting context into another chat
- You have been stuck fixing the same spot over and over
- You already review code, but you never review the reasoning behind it

## Usage

When you are about to decide on an approach, or when you are stuck:

```
/second-opinion:ask
```

The AI extracts only the question, constraints, success criteria, observed facts, and relevant file paths from the conversation, writes a brief, and confirms it in three lines.

```
AI: I'll ask another model the following. Our own proposal is not included.
    - Question: store session state in Redis or in the DB?
    - Constraints / success: existing Redis available / p99 under 50ms
    - Files: src/session.ts, docs/adr/003.md
    OK?

You: OK
```

The other model reads the repository read-only and answers. You get a comparison table.

```
| Point | Ours | Theirs | Agree/Differ | Traceable to evidence? |
|---|---|---|---|---|
| Storage | Redis | Redis | Agree | Both: existing setup |
| TTL | fixed 24h | sliding | Differ | Ours: guess / Theirs: docs/adr/003.md |

### Their answer, verbatim
(full text)

The human decides which to take.
Agreement means "same conclusion", not "verified".
```

When there are differences, the AI offers one line: "Show our proposal and have them attack its weaknesses?" If you accept, the second round sends your proposal and asks for at least three weaknesses.

The AI may also offer, in one line, "Want an independent view from another model on this decision?" It never runs without your yes.

## Why only the problem is sent

Research shows LLMs favor their own generations (self-preference bias) and lean toward opinions shown in the prompt (sycophancy). Ask the same model "what do you think of this plan?" and it usually starts with agreement.

Asking a different model is not enough on its own. The moment you show it your proposal, it starts agreeing too. One study found that wrong peer agreement misleads a correct model more effectively than correct agreement fixes a wrong one. So the order matters: hand over the problem first, let it answer independently, then compare.

One more thing: when the other model agrees with you, that is not verification. Errors are correlated even across vendors, and when two models are both wrong they converge on the same wrong answer about 60% of the time (ICML 2025). That is why the table has a "traceable to evidence?" column, so even agreements are checked against code, specs, or measurements.

The same principle works in human meetings: don't state your proposal before asking for opinions, and don't treat unanimity as proof.

## Prerequisites

- From Claude Code: [Codex CLI](https://developers.openai.com/codex/cli) installed and logged in
- From Codex: [Claude Code](https://code.claude.com/docs) installed and logged in
- Usage of the other model is billed on that side's plan or API

## Installation

### Claude Code

Run the following in Claude Code, in order.

```
/plugin marketplace add saladdays/agent-skills
```

Once the marketplace is added, install the plugin.

```
/plugin install second-opinion@saladdays-skills
```

Then start with `/second-opinion:ask`.

> This uses Claude Code's plugin system. Install once and it stays available.

### Codex CLI

Copy the contents of `skills/ask/` into Codex's skills directory.

```bash
mkdir -p ~/.agents/skills/second-opinion
cp -R plugins/second-opinion/skills/ask/. ~/.agents/skills/second-opinion/
chmod +x ~/.agents/skills/second-opinion/scripts/ask.sh
```

Inside a Codex session, ask for a "second opinion" and it will consult Claude Code.

### Cursor

Not supported in the first release (Cursor has no standard way to invoke an external CLI).

### Other AI tools

Copy SKILL.md, scripts/, and references/ into your tool's skills directory.

## License

MIT
