"""Tests for ModHealthService and integrity checking."""
import json
import os
import shutil
import tempfile
import pytest

from core.health_service import ModHealthService


@pytest.fixture
def fake_dota_env():
    """Create a temporary fake Dota 2 environment for testing."""
    tmp_dir = tempfile.mkdtemp()
    game_dir = os.path.join(tmp_dir, "dota 2 beta", "game")
    dota_dir = os.path.join(game_dir, "dota")
    os.makedirs(dota_dir, exist_ok=True)

    # Valid gameinfo.gi with dota/pak mod hook
    gameinfo_path = os.path.join(dota_dir, "gameinfo.gi")
    with open(gameinfo_path, "w", encoding="utf-8") as f:
        f.write('SearchPaths {\n\t\t\tGame\t\t\t\tdota/pak\n\t\t\tGame\tdota\n}')

    app_dir = os.path.join(tmp_dir, "app_data")
    os.makedirs(app_dir, exist_ok=True)
    manifest_path = os.path.join(app_dir, "installed_mods.json")

    yield {
        "root": tmp_dir,
        "dota": game_dir,
        "gameinfo": gameinfo_path,
        "app_dir": app_dir,
        "manifest": manifest_path,
    }

    shutil.rmtree(tmp_dir, ignore_errors=True)


def test_health_check_clean_env(fake_dota_env):
    service = ModHealthService(
        dota_path=fake_dota_env["dota"],
        manifest_path=fake_dota_env["manifest"],
        app_dir=fake_dota_env["app_dir"],
    )
    report = service.check_integrity()
    assert report["healthy"] is True
    assert report["totalMods"] == 0
    assert report["corruptedCount"] == 0
    assert report["gameinfoIntact"] is True


def test_health_check_missing_vpk(fake_dota_env):
    manifest_data = {
        "sf_arcana_1": {
            "name": "Demon Eater",
            "hero": "nevermore",
            "files": [os.path.join(fake_dota_env["dota"], "dota", "pak01_dir.vpk")],  # missing
        }
    }
    with open(fake_dota_env["manifest"], "w", encoding="utf-8") as f:
        json.dump(manifest_data, f)

    service = ModHealthService(
        dota_path=fake_dota_env["dota"],
        manifest_path=fake_dota_env["manifest"],
        app_dir=fake_dota_env["app_dir"],
    )
    report = service.check_integrity()
    assert report["healthy"] is False
    assert report["corruptedCount"] == 1
    assert len(report["corruptedMods"]) == 1
    assert report["corruptedMods"][0]["name"] == "Demon Eater"


def test_health_check_valid_vpk(fake_dota_env):
    vpk_path = os.path.join(fake_dota_env["dota"], "dota", "pak99_dir.vpk")
    with open(vpk_path, "wb") as f:
        f.write(b"VPK_DATA_VALID_FILE_CONTENT_XYZ")

    manifest_data = {
        "pa_arcana_1": {
            "name": "Manifold Paradox",
            "hero": "phantom_assassin",
            "files": [vpk_path],
        }
    }
    with open(fake_dota_env["manifest"], "w", encoding="utf-8") as f:
        json.dump(manifest_data, f)

    service = ModHealthService(
        dota_path=fake_dota_env["dota"],
        manifest_path=fake_dota_env["manifest"],
        app_dir=fake_dota_env["app_dir"],
    )
    report = service.check_integrity()
    assert report["healthy"] is True
    assert report["intactCount"] == 1
    assert report["corruptedCount"] == 0


def test_health_check_corrupted_gameinfo(fake_dota_env):
    # Overwrite gameinfo with generic steam update content missing dota/pak hook
    with open(fake_dota_env["gameinfo"], "w", encoding="utf-8") as f:
        f.write('SearchPaths {\n\t\t\tGame\tdota\n}')

    service = ModHealthService(
        dota_path=fake_dota_env["dota"],
        manifest_path=fake_dota_env["manifest"],
        app_dir=fake_dota_env["app_dir"],
    )
    report = service.check_integrity()
    assert report["healthy"] is False
    assert report["gameinfoIntact"] is False
    assert "gameinfo.gi" in report["statusMessage"]


def test_repair_gameinfo(fake_dota_env):
    # Valve update wiped dota/pak hook
    with open(fake_dota_env["gameinfo"], "w", encoding="utf-8") as f:
        f.write('SearchPaths {\n\t\t\tGame\tdota\n}')

    service = ModHealthService(
        dota_path=fake_dota_env["dota"],
        manifest_path=fake_dota_env["manifest"],
        app_dir=fake_dota_env["app_dir"],
    )
    success, msg = service.repair_gameinfo_if_needed()
    assert success is True

    # Verify gameinfo now contains dota/pak
    with open(fake_dota_env["gameinfo"], "r", encoding="utf-8") as f:
        content = f.read()
    assert "dota/pak" in content
