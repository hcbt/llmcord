# llmcord

llmcord transforms Discord into a collaborative LLM frontend. It works with practically any LLM, remote or locally hosted.

## Features

### Reply-based chat system:
Just @ the bot to start a conversation and reply to continue. Build conversations with reply chains!

You can:
- Branch conversations endlessly
- Continue other people's conversations
- @ the bot while replying to ANY message to include it in the conversation

Additionally:
- When DMing the bot, conversations continue automatically (no reply required). To start a fresh conversation, just @ the bot. You can still reply to continue from anywhere.
- You can branch conversations into [threads](https://support.discord.com/hc/en-us/articles/4403205878423-Threads-FAQ). Just create a thread from any message and @ the bot inside to continue.
- Back-to-back messages from the same user are automatically chained together. Just reply to the latest one and the bot will see all of them.

---

### Model switching with `/model`:
![image](https://github.com/user-attachments/assets/568e2f5c-bf32-4b77-ab57-198d9120f3d2)

llmcord supports remote models from:
- [OpenAI API](https://platform.openai.com/docs/models)
- [xAI API](https://docs.x.ai/docs/models)
- [Google Gemini API](https://ai.google.dev/gemini-api/docs/models)
- [Mistral API](https://docs.mistral.ai/getting-started/models/models_overview)
- [Groq API](https://console.groq.com/docs/models)
- [OpenRouter API](https://openrouter.ai/models)

Or run local models with:
- [Ollama](https://ollama.com)
- [LM Studio](https://lmstudio.ai)
- [vLLM](https://github.com/vllm-project/vllm)

...Or use any other OpenAI compatible API server.

---

### And more:
- Supports image attachments when using a vision model (like gpt-5, grok-4, claude-4, etc.)
- Supports text file attachments (.txt, .py, .c, etc.)
- Customizable personality (aka system prompt)
- Distinguishes users via their Discord IDs
- Streamed responses (turns green when complete, automatically splits into separate messages when too long)
- Hot reloading config (you can change settings without restarting the bot)
- Displays helpful warnings when appropriate (like "⚠️ Only using last 25 messages" when the customizable message limit is exceeded)
- Caches message data in a size-managed (no memory leaks) and mutex-protected (no race conditions) global dictionary to maximize efficiency and minimize Discord API calls
- Fully asynchronous
- Core runtime in one Python source file: `src/llmcord/llmcord.py`

## Quick Start (Run Only)

1. Clone the repo and enter it:
   ```bash
   git clone <your-repo-url>
   cd llmcord
   ```

2. Create a local runtime config:
   ```bash
   cp config-example.yaml config.yaml
   ```

3. Edit `config.yaml` with at least:
   - `bot_token`
   - one working provider/model combination in `providers` + `models`

4. Run the app:
   ```bash
   nix run
   ```
   Equivalent explicit target:
   ```bash
   nix run .#llmcord
   ```

`nix run` is enough for this flake because `apps.<system>.default` points to the `llmcord` executable.
The app expects `config.yaml` in the current working directory, so run from the repo root.

## Development Setup

1. Enter the development shell:
   ```bash
   nix develop --impure
   ```
   `--impure` is required for `devenv` in this flake setup.

2. Sync dependencies (recommended explicit step):
   ```bash
   uv sync --frozen
   ```

3. (Contributors) Install git hooks once per clone:
   ```bash
   prek install --hook-type pre-commit --hook-type pre-push
   ```

Why run `uv sync --frozen` if a lockfile already exists?
- `uv.lock` pins versions, but does not itself install them.
- `uv sync --frozen` installs exactly what's pinned and fails if lock data is inconsistent.
- In this repo, `nix develop --impure` already triggers uv sync via `devenv`, so this step can look redundant; it's still useful as an explicit CI/dev verification command.

## Command Reference

| Command | Purpose |
| --- | --- |
| `nix run` | Run the app via the default flake app target (`llmcord`). |
| `nix run .#llmcord` | Run the app via explicit app target name. |
| `nix develop --impure` | Enter the devenv development shell. |
| `uv sync --frozen` | Install exact locked dependencies (no lockfile updates). |
| `prek run --all-files` | Run configured formatting/lint/hooks checks. |
| `uv run python -m pytest` | Run test suite. |
| `nix flake check --impure` | Run flake-level checks (package + pre-commit check). |
| `nix develop --impure --command uv build` | Build source/wheel distributions. |

## PyPI Publishing (Maintainers)

Publishing is handled by `.github/workflows/publish.yml` and runs on `v*` tags:

1. Build wheel + sdist once.
2. Publish to TestPyPI (`environment: testpypi`).
3. Publish to PyPI (`environment: pypi`) after TestPyPI succeeds.

Required one-time setup outside the repo:

1. Create GitHub environments named `testpypi` and `pypi`.
2. On TestPyPI, add a Trusted Publisher:
   - owner: `hcbt`
   - repo: `llmcord`
   - workflow: `.github/workflows/publish.yml`
   - environment: `testpypi`
   - project: `llmcord`
3. On PyPI, add the same Trusted Publisher but with environment `pypi`.
4. For the first publish of a new project, use pending publisher flow and ensure the project name is exactly `llmcord`.

## Configuration

### Discord settings:

| Setting | Description |
| --- | --- |
| **bot_token** | Create a new Discord bot at [discord.com/developers/applications](https://discord.com/developers/applications) and generate a token under the "Bot" tab. Also enable "MESSAGE CONTENT INTENT". |
| **client_id** | Found under the "OAuth2" tab of the Discord bot you just made. |
| **status_message** | Set a custom message that displays on the bot's Discord profile.<br /><br />**Max 128 characters.** |
| **max_text** | The maximum amount of text allowed in a single message, including text from file attachments.<br /><br />Default: `100,000` |
| **max_images** | The maximum number of image attachments allowed in a single message.<br /><br />Default: `5`<br /><br />**Only applicable when using a vision model.** |
| **max_messages** | The maximum number of messages allowed in a reply chain. When exceeded, the oldest messages are dropped.<br /><br />Default: `25` |
| **use_plain_responses** | When set to `true` the bot will use plaintext responses instead of embeds. Plaintext responses have a shorter character limit so the bot's messages may split more often.<br /><br />Default: `false`<br /><br />**Also disables streamed responses and warning messages.** |
| **allow_dms** | Set to `false` to disable direct message access.<br /><br />Default: `true` |
| **permissions** | Configure access permissions for `users`, `roles` and `channels`, each with a list of `allowed_ids` and `blocked_ids`.<br /><br />Control which `users` are admins with `admin_ids`. Admins can change the model with `/model` and DM the bot even if `allow_dms` is `false`.<br /><br />**Leave `allowed_ids` empty to allow ALL in that category.**<br /><br />**Role and channel permissions do not affect DMs.**<br /><br />**You can use [category](https://support.discord.com/hc/en-us/articles/115001580171-Channel-Categories-101) IDs to control channel permissions in groups.** |

### LLM settings:

| Setting | Description |
| --- | --- |
| **providers** | Add the LLM providers you want to use, each with a `base_url` and optional `api_key` entry. Popular providers (`openai`, `openrouter`, `ollama`, etc.) are already included.<br /><br />**Only supports OpenAI compatible APIs.**<br /><br />**Some providers may need `extra_headers` / `extra_query` / `extra_body` entries for extra HTTP data. See the included `azure-openai` provider for an example.** |
| **models** | Add the models you want to use in `<provider>/<model>: <parameters>` format (examples are included). When you run `/model` these models will show up as autocomplete suggestions.<br /><br />**Refer to each provider's documentation for supported parameters.**<br /><br />**The first model in your `models` list will be the default model at startup.**<br /><br />**Some vision models may need `:vision` added to the end of their name to enable image support.** |
| **system_prompt** | Write anything you want to customize the bot's behavior!<br /><br />**Leave blank for no system prompt.**<br /><br />**You can use the `{date}` and `{time}` tags in your system prompt to insert the current date and time, based on your host computer's time zone.**<br /><br />**It is recommended to include something like `"User messages are prefixed with their Discord ID as <@ID>. Use this format to mention users."` in your system prompt to help the bot understand the user message format.** |
