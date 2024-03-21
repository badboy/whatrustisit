#!/usr/bin/env python3

import os
import subprocess
import sys

from mastodon import Mastodon


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

    for toolchain in ["stable", "beta"]:
        res = subprocess.run(["git", "--no-pager", "diff", "--quiet", toolchain])
        if res.returncode != 0:
            with open(toolchain, "r") as fp:
                post(api, toolchain, fp.readline())
