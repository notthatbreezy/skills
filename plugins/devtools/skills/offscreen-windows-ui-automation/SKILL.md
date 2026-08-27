---
name: offscreen-windows-ui-automation
description: Use when planning or validating Windows desktop UI automation that must exercise real application state without taking foreground focus. Covers WPF, WinUI, WinForms, and Win32 UI Automation.
---

# Offscreen Windows UI Automation

Read `references/guide.md` before designing or running an offscreen Windows UI test.

Follow the guide's complete safety procedure. In particular:

- launch the exact validated executable against its real state;
- identify the titled product window rather than a framework helper window;
- apply `WS_EX_NOACTIVATE` before showing the product window;
- move the window outside the virtual desktop;
- target UI Automation by process ID and exact decimal window handle;
- use UI Automation patterns instead of mouse, keyboard, focus, or foreground APIs;
- continuously reject foreground ownership by any window from the tested process; and
- stop only the exact processes owned by the test.

Do not use this method to bypass an application's visible confirmation or authorization boundary.
Cloud mutations, destructive operations, outbound messages, and similar effects still require their
normal approval.
