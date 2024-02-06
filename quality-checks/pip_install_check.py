#!/bin/python3
import os
import sys


EMJOI_CHECK_MARK_BUTTON = "\u2705"
EMJOI_CROSS_MARK = "\u274C"


def check_file_for_pip_install(filepath: str) -> bool:
    """
    Checks if the file contains 'pip install'.

    :param filepath: The path of the file to check.

    :returns True if the check passes (no 'pip install' found), else False.
    """
    with open(filepath, "r") as file:
        for line in file:
            if "pip install" in line:
                return False
    return True


def verify_no_pip_install(directory: str) -> bool:
    """
    Recursively searches through the directory tree and verifies that there
    are no direct use of `pip install`.

    :param directory: The directory to scan.

    :returns True if the verification succeeds, otherwise False.
    """
    # Check if the directory exists
    if not os.path.isdir(directory):
        print(f"The directory {directory} does not exist.")
        return True

    # Walk through the directory tree
    ret_code = True
    for root, _dirs, files in os.walk(directory):
        for filename in files:
            if filename.endswith(".sh"):  # Check for bash scripts
                filepath = os.path.join(root, filename)
                if check_file_for_pip_install(filepath):
                    print(f"{EMJOI_CHECK_MARK_BUTTON} {filepath}")
                else:
                    print(f"{EMJOI_CROSS_MARK} {filepath}.")
                    ret_code = False

    return ret_code


def verify_in_repo_root() -> None:
    """
    Verifies that the script is being executed from within the repository
    root. Exits with non-zero code if that's not the case.
    """
    # Determine the script's directory and the parent directory (which should
    # be <repo root>)
    script_dir = os.path.dirname(os.path.realpath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, ".."))

    # Check if the current working directory is the repo root
    if os.getcwd() != repo_root:
        print(
            "The script must be run from the repo root. Please cd into "
            "the repo root directory and then type: "
            f"./quality-checks/{os.path.basename(__file__)}."
        )
        sys.exit(1)


def main() -> None:
    verify_in_repo_root()

    if verify_no_pip_install("./"):
        sys.exit(0)
    else:
        print(
            "Some files failed the check. Please ensure you are using "
            "`safe-pip-install` in those files instead of directly "
            "calling `pip install`."
        )
        sys.exit(1)


if __name__ == "__main__":
    main()