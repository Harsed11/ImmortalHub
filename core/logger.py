import logging
import os
from logging.handlers import RotatingFileHandler

def setup_logger(app_name="ImmortalHub"):
    logger = logging.getLogger(app_name)
    logger.setLevel(logging.DEBUG)

    if logger.handlers:
        return logger

    # Ensure log directory exists
    app_dir = os.path.join(os.path.expanduser("~"), ".dota2skinchanger")
    os.makedirs(app_dir, exist_ok=True)
    log_file = os.path.join(app_dir, "app.log")

    # Formatter
    formatter = logging.Formatter(
        "[%(asctime)s] [%(levelname)s] [%(filename)s:%(lineno)d] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )

    # File Handler (Rotating, max 5MB, keep 2 backups)
    file_handler = RotatingFileHandler(log_file, maxBytes=5 * 1024 * 1024, backupCount=2, encoding="utf-8")
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)

    # Console Handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)

    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    return logger

logger = setup_logger()
