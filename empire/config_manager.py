import logging
import os
import shutil
from pathlib import Path

import yaml

log = logging.getLogger(__name__)

user_home = Path.home()
SOURCE_CONFIG_CLIENT = Path("empire/client/config.yaml")
SOURCE_CONFIG_SERVER = Path("empire/server/config.yaml")
CONFIG_DIR = user_home / ".empire"
CONFIG_CLIENT_PATH = CONFIG_DIR / "client" / "config.yaml"
CONFIG_SERVER_PATH = CONFIG_DIR / "server" / "config.yaml"


def config_init():
    CONFIG_CLIENT_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_SERVER_PATH.parent.mkdir(parents=True, exist_ok=True)

    if not CONFIG_CLIENT_PATH.exists():
        shutil.copy(SOURCE_CONFIG_CLIENT, CONFIG_CLIENT_PATH)
        log.info(f"Copied {SOURCE_CONFIG_CLIENT} to {CONFIG_CLIENT_PATH}")
    else:
        log.info(f"{CONFIG_CLIENT_PATH} already exists.")

    if not CONFIG_SERVER_PATH.exists():
        shutil.copy(SOURCE_CONFIG_SERVER, CONFIG_SERVER_PATH)
        log.info(f"Copied {SOURCE_CONFIG_SERVER} to {CONFIG_SERVER_PATH}")
    else:
        log.info(f"{CONFIG_SERVER_PATH} already exists.")


def check_config_permission(config_dict: dict, config_type: str):
    """
    Check if the specified directories in config.yaml are writable. If not, switches to a fallback directory.
    Handles both server and client configurations.

    Args:
        config_dict (dict): The configuration dictionary loaded from YAML.
        config_type (str): The type of configuration ("server" or "client").
    """
    # Define paths to check based on config type
    if config_type == "server":
        paths_to_check = {
            ("api", "cert_path"): config_dict["api"]["cert_path"],
            ("database", "sqlite", "location"): config_dict["database"]["sqlite"][
                "location"
            ],
            ("starkiller", "directory"): config_dict["starkiller"]["directory"],
            ("logging", "directory"): config_dict["logging"]["directory"],
            ("debug", "last_task", "file"): config_dict["debug"]["last_task"]["file"],
            ("directories", "downloads"): config_dict["directories"].get("downloads"),
        }
        config_path = CONFIG_SERVER_PATH  # Use the server config path

    elif config_type == "client":
        paths_to_check = {
            ("logging", "directory"): config_dict["logging"]["directory"],
            ("directories", "downloads"): config_dict["directories"].get("downloads"),
            ("directories", "generated-stagers"): config_dict["directories"].get(
                "generated-stagers"
            ),
        }
        config_path = CONFIG_CLIENT_PATH  # Use the client config path

    else:
        raise ValueError("Invalid config_type. Expected 'server' or 'client'.")

    # Check permissions and update paths as needed
    for keys, dir_path in paths_to_check.items():
        if not os.access(dir_path, os.W_OK):
            log.info(
                "No write permission for %s. Switching to fallback directory.", dir_path
            )
            user_home = Path.home()
            fallback_dir = os.path.join(
                user_home, ".empire", dir_path.removeprefix("empire/")
            )

            # Update the directory in config_dict
            target = config_dict  # target is a reference to config_dict
            for key in keys[:-1]:
                target = target[key]
            target[keys[-1]] = fallback_dir

            log.info(
                "Updated %s to fallback directory: %s", "->".join(keys), fallback_dir
            )

    # Write the updated configuration back to the correct YAML file
    with open(config_path, "w") as config_file:
        yaml.safe_dump(config_dict, config_file)

    log.info(
        "Updated %s config.yaml to use fallback directory: %s",
        config_type,
        fallback_dir,
    )
