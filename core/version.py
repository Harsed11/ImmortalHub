"""
Single source of truth for application identity and versioning.

Every module that needs the app name or version should import it from here
instead of hardcoding string literals across the codebase.
"""

import re

APP_NAME = "ImmortalHub"
APP_VERSION = "1.2.0"


def parse_version(version: str) -> tuple[int, int, int]:
    """
    Convert a version string like 'v1.2.3-rc1' into a comparable (major, minor, patch) tuple.

    Non-numeric suffixes are ignored and missing parts are treated as 0.
    """
    numbers = re.findall(r"\d+", version or "")
    nums = [int(n) for n in numbers[:3]]
    while len(nums) < 3:
        nums.append(0)
    return (nums[0], nums[1], nums[2])