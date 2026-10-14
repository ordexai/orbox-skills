# Orbox in Claude (claude.ai and Claude Desktop)

Step by step: connect Orbox to Claude in the browser or the desktop app, add the `orbox-process` skill, and start mapping processes.

**You need:**

- an Orbox account in an organization that has Orbox enabled;
- a Claude plan: Free, Pro, Max, Team or Enterprise (on Free you can add only one custom connector).

Claude Desktop uses your claude.ai account. Set things up once in either of them, and the connector and the skill are available in both. If the desktop app doesn't show them, restart it.

## 1. Add Orbox as a connector

### Free, Pro and Max

1. In Claude, open **Customize → Connectors**.
2. Click **+ Add → Add custom connector**.
3. Name: `Orbox`. URL: `https://orbox.dev/api/mcp`. Click **Continue**.
4. Claude detects the sign-in settings. Keep them and click **Continue**, then **Add**:
   - Authentication: **Sign in now**
   - OAuth client: **Register automatically**
   - Request headers: leave empty
5. The Orbox sign-in opens. Sign in with your Orbox account (Google or password).
6. On the **Připojit aplikaci k Orboxu** screen, check that the app is Claude and that it redirects to `claude.ai`. Then choose the access level and click **Povolit**:
   - **Čtení a zápis** (read/write): Claude can map and edit processes. Choose this to use the skill.
   - **Pouze čtení** (read-only): Claude can only search and read.

### Team and Enterprise

An organization owner adds the connector once for everyone:

1. In Claude, open **Organization settings → Connectors**.
2. Click **Add**, hover over **Custom** and pick **Web**.
3. Name `Orbox`, URL `https://orbox.dev/api/mcp`, and the same settings as in step 4 above. Click **Add**.

Each member then connects with their own Orbox account:

1. Open **Customize → Connectors**, find **Orbox** and click **Connect**.
2. Continue with steps 5–6 above.

Every member works under their own account and sees only what they can see in Orbox.

## 2. Add the `orbox-process` skill

The connector gives Claude the Orbox tools. The skill gives it the method: how to interview you about a process, split it into steps, find roles and tools, and check the result before submitting.

1. Turn on code execution: **Settings → Capabilities → Code execution and file creation**. On Team and Enterprise an owner may have to allow it first in **Organization settings → Plugins & skills**.
2. Download [`orbox-process.zip`](https://github.com/ordexai/orbox-skills/releases/latest/download/orbox-process.zip). Don't unzip it.
3. Open **Customize → Skills**, click **+ → Create skill → Upload a skill**, and choose the zip.
4. Check that **orbox-process** is switched on.

On Enterprise, an owner can upload the skill once for the whole organization in **Organization settings → Plugins & skills**. It then appears for every member.

## 3. Try it

1. Start a new chat.
2. Click **+** at the bottom left → **Connectors**, and check that **Orbox** is switched on.
3. Ask, for example:
   - *What entity types do we have in Orbox?*
   - *I want to map our invoice approval process in Orbox.*
4. Before Claude first uses an Orbox tool, it asks for permission. Choose **Allow once** or **Always allow**.

When mapping, Claude starts by asking how the process starts and ends, then walks through it with you one step at a time. The draft shows up in Orbox as you go. Nothing becomes active until you ask Claude to submit it.

## Troubleshooting

| Problem | What to do |
|---|---|
| Claude says the connection failed or asks you to sign in again | The connection lasts 90 days and can be revoked in Orbox. Go to **Customize → Connectors → Orbox → Connect** and sign in again. |
| Claude can read but not create or edit anything | You chose **Pouze čtení**. In Orbox, open **Nastavení → Aplikace a tokeny** and revoke the Claude connection. Then in Claude disconnect Orbox and connect it again, and choose **Čtení a zápis**. If Claude reconnects without showing the Orbox screen, connect once more. |
| The sign-in ends with an error | Your account must belong to an organization with Orbox enabled. Check that you can log in to Orbox in the browser. |
| Uploading the skill fails | Upload the downloaded zip as it is (not unzipped and re-zipped), and check that code execution is on. |
| Claude doesn't use the skill | Check that **orbox-process** is on in **Customize → Skills**, start a new chat, and mention Orbox in your request. |
| You can't add a second custom connector | The Free plan allows one custom connector. |

You can see and revoke every app connected to your Orbox account in **Nastavení → Aplikace a tokeny**. Organization owners also see their members' connections there.
