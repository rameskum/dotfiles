#!/usr/bin/env python3
"""Drives a real interactive shell in a pseudo-terminal, like a person at a keyboard.

    tests/shell-pty.py zsh     (macOS, Linux, WSL: ~/.zshrc)
    tests/shell-pty.py pwsh    (PowerShell 7 on macOS/Linux with the profile)

Checks what only a terminal can show: the startup file loads without errors,
the starship prompt is drawn, Tab completes a path, and a command typed
earlier is offered back as an autosuggestion. Run by the verify scripts.
"""
import fcntl
import os
import pty
import re
import select
import struct
import sys
import termios
import time

ANSI = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b[()][A-Z0-9]|\x1b[=>]")


def read_for(fd, seconds):
    """Collect output until the terminal has been quiet for `seconds`."""
    out = b""
    while True:
        ready, _, _ = select.select([fd], [], [], seconds)
        if not ready:
            return out.decode("utf-8", "replace")
        try:
            chunk = os.read(fd, 65536)
        except OSError:
            return out.decode("utf-8", "replace")
        if not chunk:
            return out.decode("utf-8", "replace")
        out += chunk
        # PowerShell asks the terminal where the cursor is and waits for the
        # answer; a real terminal replies, so do the same.
        for _ in range(chunk.count(b"\x1b[6n")):
            os.write(fd, b"\x1b[1;1R")


def main():
    shell = sys.argv[1] if len(sys.argv) > 1 else "zsh"
    argv = {"zsh": ["zsh", "-i"], "pwsh": ["pwsh", "-NoLogo"]}[shell]
    env = dict(os.environ, TERM="xterm-256color", LANG="C.UTF-8")
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(os.path.expanduser("~"))
        os.execvpe(argv[0], argv, env)

    # A real terminal has a size; PowerShell misbehaves without one.
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
    failures = 0

    def check(ok, msg, detail=""):
        nonlocal failures
        print(("ok   " if ok else "FAIL ") + msg)
        if not ok:
            failures += 1
            if detail:
                print("     " + detail.replace("\n", "\n     "), file=sys.stderr)

    startup = ANSI.sub("", read_for(fd, 4.0))
    check("❯" in startup, "starship prompt is drawn at startup", repr(startup))
    check(
        not re.search(r"(error|can't|not found|no such)", startup, re.I),
        f"{shell} starts with no errors",
        startup,
    )

    # Tab completion.
    os.write(fd, b"ls /et\t")
    completed = ANSI.sub("", read_for(fd, 1.5))
    check("/etc/" in completed or completed.rstrip().endswith("c/"), "Tab completes /et to /etc/", repr(completed))
    os.write(fd, b"\x03")  # Ctrl+C clears the line
    read_for(fd, 0.5)

    # Autosuggestion: run a command, then start typing it again.
    os.write(fd, b"echo suggest_me_please\r")
    read_for(fd, 1.0)
    os.write(fd, b"echo suggest_m")
    typed = ANSI.sub("", read_for(fd, 1.5))
    check("e_please" in typed, "autosuggestion offers the earlier command", repr(typed))

    os.write(fd, b"\x03exit\r")
    read_for(fd, 0.5)
    # Never hang CI on a shell that will not exit.
    deadline = time.time() + 3
    while time.time() < deadline and os.waitpid(pid, os.WNOHANG) == (0, 0):
        time.sleep(0.1)
    else:
        try:
            os.kill(pid, 9)
            os.waitpid(pid, 0)
        except (ProcessLookupError, ChildProcessError):
            pass
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
