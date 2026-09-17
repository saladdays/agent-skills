[English](./README.en.md) | [日本語](./README.md)

# saladdays/agent-skills

A collection of plugins for AI coding tools. Works with Claude Code and Cursor.

## Plugins

| Plugin | Description | Skill |
|---|---|---|
| [design-md](./plugins/design-md/) | Bring consistency to AI-generated UI. Generate a DESIGN.md through dialogue | `/design-md:generate` |
| [best-practice](./plugins/best-practice/) | Research real-world best practices and compile them into a structured report | `/best-practice:search` |
| [roundtable](./plugins/roundtable/) | Assemble experts from diverse fields for structured discussion, multi-angle evaluation, and recommendations | `/roundtable:start` |
| [context-handoff](./plugins/context-handoff/) | Automatically carry context across sessions. No manual saving or resuming required | `/context-handoff:save` |
| [second-opinion](./plugins/second-opinion/) | Hand only the problem to a model from a different family, get an independent answer, and compare it with your own | `/second-opinion:ask` |

## Installation

### Claude Code

```
/plugin marketplace add saladdays/agent-skills
```

Once the marketplace is added, install the plugins you want.

```
/plugin install design-md@saladdays-skills
/plugin install best-practice@saladdays-skills
/plugin install roundtable@saladdays-skills
/plugin install context-handoff@saladdays-skills
/plugin install second-opinion@saladdays-skills
```

### Cursor

Search for the plugin in the Cursor plugin marketplace and install it.

> [Cursor Marketplace](https://cursor.com/marketplace) — one-click install available once published.

## License

MIT
