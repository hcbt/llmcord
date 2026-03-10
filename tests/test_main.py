import asyncio
import importlib
import sys


def test_import_is_side_effect_free(monkeypatch):
    called = {"asyncio_run": False}

    def fake_run(*args, **kwargs):
        called["asyncio_run"] = True

    monkeypatch.setattr(asyncio, "run", fake_run)
    sys.modules.pop("llmcord", None)

    module = importlib.import_module("llmcord")

    assert hasattr(module, "main")
    assert called["asyncio_run"] is False


def test_get_config_loads_yaml(tmp_path):
    import llmcord

    config_file = tmp_path / "config.yaml"
    config_file.write_text(
        """
bot_token: test-token
models:
  openai/gpt-5: {}
""".strip()
        + "\n",
        encoding="utf-8",
    )

    loaded = llmcord.get_config(str(config_file))

    assert loaded["bot_token"] == "test-token"
    assert "openai/gpt-5" in loaded["models"]


def test_main_delegates_to_asyncio_run(monkeypatch):
    import llmcord

    called = {"asyncio_run": False}

    async def fake_main_async(config_file="config.yaml"):
        return config_file

    def fake_run(coro):
        called["asyncio_run"] = True
        coro.close()

    monkeypatch.setattr(llmcord, "main_async", fake_main_async)
    monkeypatch.setattr(llmcord.asyncio, "run", fake_run)

    llmcord.main()

    assert called["asyncio_run"] is True


def test_main_async_starts_bot_and_closes_client(monkeypatch):
    import llmcord

    called = {}

    def fake_initialize_runtime(config_file="config.yaml"):
        called["config_file"] = config_file
        llmcord.config = {
            "bot_token": "token-123",
            "models": {"openai/gpt-5": {}},
        }
        llmcord.curr_model = "openai/gpt-5"

    async def fake_start(token):
        called["token"] = token

    async def fake_aclose():
        called["closed"] = True

    monkeypatch.setattr(llmcord, "initialize_runtime", fake_initialize_runtime)
    monkeypatch.setattr(llmcord.discord_bot, "start", fake_start)
    monkeypatch.setattr(llmcord.httpx_client, "aclose", fake_aclose)

    asyncio.run(llmcord.main_async("custom-config.yaml"))

    assert called["config_file"] == "custom-config.yaml"
    assert called["token"] == "token-123"
    assert called["closed"] is True
