# Orbox skills

Agent skills for [Orbox](https://orbox.dev).

**`orbox-process`** teaches your AI agent to map a business process into Orbox by interviewing you, and to edit processes that are already there. It works through the Orbox MCP server, so you need both: the MCP connection gives the agent the tools, and the skill gives it the method.

## 1. Connect the Orbox MCP server

Server URL: `https://orbox.dev/api/mcp`. You sign in with your Orbox account in the browser, with no token to copy. On the consent screen pick **Čtení a zápis** (read/write) if the agent should map processes; **Pouze čtení** (read-only) only lets it look things up.

**Claude Code**

```bash
claude mcp add --transport http --scope user orbox https://orbox.dev/api/mcp
```

Then run `/mcp` in a session, select `orbox` and choose **Authenticate**.

**claude.ai and Claude Desktop**

**Customize → Connectors → + Add → Add custom connector**: name `Orbox`, URL `https://orbox.dev/api/mcp`, keep the detected sign-in settings, then sign in. On Team and Enterprise an owner adds the connector first. Claude Desktop uses your claude.ai account, so set it up once in either. Step-by-step guide: [docs/claude-app.md](docs/claude-app.md).

**Codex**

```bash
codex mcp add orbox --url https://orbox.dev/api/mcp
codex mcp login orbox
```

Scripts and clients without OAuth can use a personal API token instead: create one in Orbox under Nastavení → Aplikace a tokeny and send it as `Authorization: Bearer <token>`. Keep it in an environment variable or your secret manager, never in a committed file or in the URL.

## 2. Install the skill

**Claude Code** (as a plugin, with updates):

```bash
claude plugin marketplace add ordexai/orbox-skills
claude plugin install orbox@orbox
```

**claude.ai and Claude Desktop**

1. Download [`orbox-process.zip`](https://github.com/ordexai/orbox-skills/releases/latest/download/orbox-process.zip).
2. **Customize → Skills → + → Create skill → Upload a skill**, and pick the zip. Code execution must be on (Settings → Capabilities).

On Enterprise, an organization owner can upload the skill once for everyone in Organization settings → Plugins & skills. Details: [docs/claude-app.md](docs/claude-app.md).

**Codex, Cursor, opencode and other agents** (via [`skills`](https://github.com/vercel-labs/skills)):

```bash
npx skills add ordexai/orbox-skills -g
```

Pick your agents when asked, or pass them, e.g. `-a codex`.

Start a new session after installing; skills are loaded at startup.

## 3. Try it

> I want to map our invoice approval process in Orbox.

The agent should start by asking how the process starts and ends, then walk through it with you one step at a time. The draft appears in Orbox as you go; nothing becomes active until you ask the agent to submit it.

## Updating

| Where | How |
|---|---|
| Claude Code | `claude plugin marketplace update orbox`, then `claude plugin update orbox@orbox` |
| `npx skills` | `npx skills update` |
| claude.ai / Desktop | Download the new zip and upload it again |

## License

For use with Orbox only. See [LICENSE](LICENSE).
