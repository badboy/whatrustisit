#!/usr/bin/env python3

import os
import shlex
import subprocess
import sys

from mastodon import Mastodon


def shell_command(command, silent=False):
    command = shlex.split(command)
    return subprocess.check_output(command).decode("utf-8")


def install_rust():
    pass
    # subprocess.run(["rustup", "toolchain", "add", "stable"])
    # subprocess.run(["rustup", "toolchain", "add", "beta"])


def rustc_version(toolchain):
    return shell_command(f"rustup run {toolchain} rustc --version")


def post(api, toolchain, version):
    comp = version.split(" ")
    version = comp[1]
    msg = f"🦀 New Rust {toolchain}: {version}"
    if toolchain == "stable":
        msg += "\n"
        msg += f"📝 Changelog at https://github.com/rust-lang/rust/blob/{version}/RELEASES.md"  # noqa
    print(f"Posting: {msg}\n")
    api.status_post(msg)


MASTO_ACCESS_TOKEN = os.environ["MASTO_ACCESS_TOKEN"]
MASTO_URL = os.environ["MASTO_URL"]
MASTO_CLIENT_ID = os.environ["MASTO_CLIENT_ID"]
MASTO_CLIENT_SECRET = os.environ["MASTO_CLIENT_SECRET"]

if __name__ == "__main__":
    api = Mastodon(
        access_token=MASTO_ACCESS_TOKEN,
        api_base_url=MASTO_URL,
        client_id=MASTO_CLIENT_ID,
        client_secret=MASTO_CLIENT_SECRET,
    )
    if not api:
        print(f"no api: {api}")
        sys.exit(1)

    install_rust()

    for toolchain in ["stable", "beta"]:
        output = rustc_version(toolchain)
        with open(toolchain, "w") as fp:
            fp.write(output)

        res = subprocess.run(["git", "--no-pager", "diff", "--quiet", toolchain])
        if res.returncode != 0:
            post(api, toolchain, output)
