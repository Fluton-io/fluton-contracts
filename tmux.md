# Basic tmux Guide

tmux is a **terminal multiplexer**. It lets you run multiple terminal sessions, windows, and panes within a single terminal window. This is useful for keeping processes running even if you disconnect, and for organizing your workspace.

## Prefix Key

Most tmux commands start with a **prefix key**, followed by another key. The default prefix is `Ctrl+b`. To send a command, press `Ctrl+b` then release it, and then press the command key.

## Sessions

*   **Start a new session:** `tmux new -s <session_name>`
*   **Detach from session:** `Ctrl+b d` (leaves the session running in the background)
*   **List sessions:** `tmux ls`
*   **Attach to last session:** `tmux attach` or `tmux a`
*   **Attach to named session:** `tmux attach -t <session_name>`

## Windows

Within a session, you can have multiple "windows" (like tabs).

*   **Create new window:** `Ctrl+b c`
*   **Next window:** `Ctrl+b n`
*   **Previous window:** `Ctrl+b p`
*   **Switch to window number:** `Ctrl+b <number>` (e.g., `Ctrl+b 0` for the first window)

## Panes

Within a window, you can split it into multiple "panes".

*   **Split vertically:** `Ctrl+b %` (divides the current pane into left and right)
*   **Split horizontally:** `Ctrl+b "` (divides the current pane into top and bottom)
*   **Switch to next pane:** `Ctrl+b o` (cycles through panes)
*   **Switch to pane by direction:** `Ctrl+b <arrow key>` (e.g., `Ctrl+b UpArrow`)
*   **Zoom pane:** `Ctrl+b z` (makes the current pane fill the whole window; press again to unzoom)
*   **Close current pane:** `Ctrl+b x` (will ask for confirmation)
*   **Scrooll:** `Ctrl+b [` 

## Exiting

*   **Close pane:** `Ctrl+b x` or type `exit`
*   **Kill session:** `tmux kill-session -t <session_name>`
