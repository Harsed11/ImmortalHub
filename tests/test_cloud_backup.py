"""Tests for CloudBackupService and sync system."""
import json
import os
import shutil
import tempfile
import pytest

from core.cloud_backup import CloudBackupService


@pytest.fixture
def backup_env():
    tmp_dir = tempfile.mkdtemp()
    yield tmp_dir
    shutil.rmtree(tmp_dir, ignore_errors=True)


def test_create_payload(backup_env):
    service = CloudBackupService(app_dir=backup_env)
    payload = service.create_payload(
        presets=[{"name": "TI12 Loadout"}],
        installed_mods={"heroes::Pudge": {"name": "Arcana", "hero": "pudge"}},
        favorites={"heroes::SF": {"name": "Demon Eater"}},
        settings={"accentHue": "emerald"}
    )

    assert payload["appName"] == "ImmortalHub"
    assert payload["version"] == 2
    assert len(payload["presets"]) == 1
    assert "heroes::Pudge" in payload["installedMods"]
    assert "heroes::SF" in payload["favorites"]
    assert payload["settings"]["accentHue"] == "emerald"
    assert "createdAt" in payload


def test_export_import_local_file(backup_env):
    service = CloudBackupService(app_dir=backup_env)
    payload = service.create_payload(
        presets=[{"id": "p_1", "name": "Pro Preset"}],
        installed_mods={"mod_1": {"id": "mod_1", "name": "Fire Mod"}},
        favorites={"mod_1": True},
        settings={"accentHue": "amethyst"}
    )

    file_path = os.path.join(backup_env, "test_backup.ihub_backup")
    success, msg = service.export_to_file(file_path, payload)
    assert success is True
    assert os.path.exists(file_path)

    # Read back and verify
    ok, msg, imported = service.import_from_file(file_path)
    assert ok is True
    assert imported is not None
    assert imported["appName"] == "ImmortalHub"
    assert imported["settings"]["accentHue"] == "amethyst"
    assert "mod_1" in imported["installedMods"]


def test_cloud_code_formatting():
    # Bytebin ID format tests
    key = "aBcDeFg123"
    code = f"IHUB-CLOUD-{key}"
    extracted = CloudBackupService.extract_key(code)
    assert extracted == "aBcDeFg123"


def test_invalid_import_file(backup_env):
    service = CloudBackupService(app_dir=backup_env)
    bad_file = os.path.join(backup_env, "corrupt.ihub_backup")
    with open(bad_file, "w") as f:
        f.write("NOT VALID JSON CONTENT")

    ok, msg, data = service.import_from_file(bad_file)
    assert ok is False
    assert data is None
