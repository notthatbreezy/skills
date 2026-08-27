# Offscreen Windows UI Automation Against Real Application State

Last updated: 2026-08-20

## Purpose

Use this procedure to test a real Windows desktop application without giving it foreground ownership, covering the operator's desktop, or switching it to synthetic fixture state.

This pattern works with WPF, WinUI, WinForms, and Win32 applications that expose Windows UI Automation. It was proven with DBAgent Workbench running against its real `%LOCALAPPDATA%` state.

The essential rules are:

1. Launch the exact validated executable.
2. Do not pass fixture or temporary-state arguments.
3. Find the real product window, not a framework helper window.
4. Apply `WS_EX_NOACTIVATE` before showing the product window.
5. position it outside the virtual desktop.
6. target UI Automation by PID and exact decimal HWND.
7. use UIA patterns rather than mouse, keyboard, focus, or foreground APIs.
8. continuously reject foreground ownership by any window from the tested PID.
9. stop only exact processes owned by the test.

## Why agents commonly get this wrong

`ShowActivated=false` or a hidden process start is insufficient. Later UI Automation calls can still activate a window unless the native `WS_EX_NOACTIVATE` extended style is applied.

WPF also creates helper windows such as:

- `SystemResourceNotifyWindow`
- `MediaContextNotificationWindow`
- `Default IME`
- untitled `HwndWrapper` windows

The first HWND owned by the process may be one of these helpers. Applying styles or attaching UIA to that HWND can produce a false successful launch while the actual product window remains hidden or later activates normally.

Finally, `winapp ui --window` expects a decimal handle. A hexadecimal value such as `0x4E0CF2` is rejected even though Win32 tools conventionally display HWND values in hexadecimal.

## Prerequisites

- Build the exact application artifact first.
- Ensure no stale application, testhost, or build process owns its output files.
- Record the executable path, SHA-256, source commit, and build command.
- Confirm `winapp` is installed:

```powershell
winapp ui --help
```

Do not use this method for an application whose safety depends on visible operator confirmation. Background UIA may inspect and exercise ordinary product flows, but cloud mutations, destructive actions, outbound messages, or other independent confirmation boundaries still require their prescribed authorization.

## Launch the real application offscreen without activation

The following reusable PowerShell function:

- starts the exact executable;
- waits for the titled product window;
- ignores WPF helper windows;
- applies `WS_EX_NOACTIVATE` and `WS_EX_TOOLWINDOW`;
- moves the window to `-32000,-32000`;
- shows it without activation; and
- proves that no tested-process window owns the foreground.

```powershell
function Start-OffscreenApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ExecutablePath,

        [Parameter(Mandatory)]
        [string] $WorkingDirectory,

        [Parameter(Mandatory)]
        [string] $ExpectedWindowTitle,

        [string[]] $Arguments = @(),

        [int] $Width = 1440,

        [int] $Height = 900,

        [int] $TimeoutSeconds = 90
    )

    $nativeSource = @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class OffscreenWindowNative
{
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(
        EnumWindowsProc callback,
        IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(
        IntPtr hWnd,
        out uint processId);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(
        IntPtr hWnd,
        StringBuilder text,
        int count);

    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW")]
    public static extern IntPtr GetWindowLongPtr(
        IntPtr hWnd,
        int index);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW")]
    public static extern IntPtr SetWindowLongPtr(
        IntPtr hWnd,
        int index,
        IntPtr value);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(
        IntPtr hWnd,
        IntPtr insertAfter,
        int x,
        int y,
        int width,
        int height,
        uint flags);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(
        IntPtr hWnd,
        int command);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
'@

    if (-not ('OffscreenWindowNative' -as [type])) {
        Add-Type -TypeDefinition $nativeSource
    }

    $resolvedExecutable = (Resolve-Path $ExecutablePath).Path
    $resolvedWorkingDirectory = (Resolve-Path $WorkingDirectory).Path

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $resolvedExecutable
    $startInfo.WorkingDirectory = $resolvedWorkingDirectory
    $startInfo.UseShellExecute = $true
    $startInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    foreach ($argument in $Arguments) {
        $null = $startInfo.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::Start($startInfo)
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $productWindow = [IntPtr]::Zero

    do {
        Start-Sleep -Milliseconds 100
        $script:offscreenCandidate = [IntPtr]::Zero

        [OffscreenWindowNative]::EnumWindows({
            param($hWnd, $state)

            $ownerPid = 0
            [OffscreenWindowNative]::GetWindowThreadProcessId(
                $hWnd,
                [ref] $ownerPid) | Out-Null

            if ($ownerPid -ne $process.Id) {
                return $true
            }

            $title = [Text.StringBuilder]::new(512)
            [OffscreenWindowNative]::GetWindowText(
                $hWnd,
                $title,
                $title.Capacity) | Out-Null

            if ($title.ToString() -eq $ExpectedWindowTitle) {
                $script:offscreenCandidate = $hWnd
                return $false
            }

            return $true
        }, [IntPtr]::Zero) | Out-Null

        $productWindow = $script:offscreenCandidate
    }
    while (
        $productWindow -eq [IntPtr]::Zero -and
        [DateTime]::UtcNow -lt $deadline -and
        -not $process.HasExited)

    if ($process.HasExited) {
        throw "Application exited during launch with code $($process.ExitCode)."
    }

    if ($productWindow -eq [IntPtr]::Zero) {
        $process.Kill($true)
        $process.WaitForExit()
        throw "The product window '$ExpectedWindowTitle' was not created within $TimeoutSeconds seconds."
    }

    $GWL_EXSTYLE = -20
    $WS_EX_TOOLWINDOW = 0x00000080
    $WS_EX_NOACTIVATE = 0x08000000
    $SWP_NOACTIVATE = 0x0010
    $SWP_SHOWWINDOW = 0x0040
    $SW_SHOWNOACTIVATE = 4

    $currentStyle = [OffscreenWindowNative]::GetWindowLongPtr(
        $productWindow,
        $GWL_EXSTYLE).ToInt64()

    $newStyle = $currentStyle -bor $WS_EX_TOOLWINDOW -bor $WS_EX_NOACTIVATE
    [OffscreenWindowNative]::SetWindowLongPtr(
        $productWindow,
        $GWL_EXSTYLE,
        [IntPtr] $newStyle) | Out-Null

    [OffscreenWindowNative]::SetWindowPos(
        $productWindow,
        [IntPtr]::Zero,
        -32000,
        -32000,
        $Width,
        $Height,
        $SWP_NOACTIVATE -bor $SWP_SHOWWINDOW) | Out-Null

    [OffscreenWindowNative]::ShowWindow(
        $productWindow,
        $SW_SHOWNOACTIVATE) | Out-Null

    # WPF may restore persisted placement during first layout after ShowWindow.
    Start-Sleep -Milliseconds 750
    [OffscreenWindowNative]::SetWindowPos(
        $productWindow,
        [IntPtr]::Zero,
        -32000,
        -32000,
        $Width,
        $Height,
        $SWP_NOACTIVATE -bor $SWP_SHOWWINDOW) | Out-Null

    $foreground = [OffscreenWindowNative]::GetForegroundWindow()
    $foregroundPid = 0
    if ($foreground -ne [IntPtr]::Zero) {
        [OffscreenWindowNative]::GetWindowThreadProcessId(
            $foreground,
            [ref] $foregroundPid) | Out-Null
    }

    if ($foregroundPid -eq $process.Id) {
        throw "The tested process unexpectedly owns the foreground."
    }

    [pscustomobject]@{
        ProcessId = $process.Id
        WindowHandle = $productWindow.ToInt64()
        WindowHandleHex = '0x{0:X}' -f $productWindow.ToInt64()
        Executable = $resolvedExecutable
        StartedAt = $process.StartTime
    }
}
```

Example:

```powershell
$app = Start-OffscreenApplication `
    -ExecutablePath 'C:\path\to\Product.exe' `
    -WorkingDirectory 'C:\path\to\repository' `
    -ExpectedWindowTitle 'Product Title'

$app | Format-List
```

Do not pass fixture arguments or a temporary state root when the purpose is production-state validation.

## Confirm that the correct window was selected

List all windows for the PID:

```powershell
winapp ui list-windows -a $app.ProcessId --show-hidden --json
```

The selected HWND must have the expected product title. Reject:

- `SystemResourceNotifyWindow`;
- `MediaContextNotificationWindow`;
- `Default IME`;
- `PopupHost`;
- an empty title unless the application contract explicitly has no title; or
- a window owned by another PID.

Use the decimal handle for `-w`:

```powershell
$hwnd = $app.WindowHandle
winapp ui wait-for NavEnvironments -w $hwnd -t 15000 --json
```

Do not pass `$app.WindowHandleHex` to `winapp ui --window`.

Immediately read one known element's `BoundingRectangle` after attachment. Its
coordinates must remain outside the virtual desktop (for this example, near
`-32000,-32000`). WPF can restore persisted window placement during first
layout, after the initial native move; if coordinates are visible, reapply
`SetWindowPos` and fail the run if the second assertion does not remain
offscreen.

## Drive the UI without foreground input

Prefer these pattern-based commands:

```powershell
winapp ui wait-for AutomationId -w $hwnd -t 10000 --json
winapp ui get-property AutomationId -w $hwnd --json
winapp ui get-value AutomationId -w $hwnd --json
winapp ui invoke AutomationId -w $hwnd --json
winapp ui set-value AutomationId 'value' -w $hwnd --json
winapp ui scroll-into-view AutomationId -w $hwnd --json
winapp ui inspect -w $hwnd --interactive --json
```

Avoid during background-safe validation:

- `click`;
- `focus`;
- `send-keys`;
- global keyboard input;
- global pointer input;
- hover-driven behavior;
- foreground APIs such as `SetForegroundWindow`; and
- desktop-wide element searches.

Use the exact HWND rather than only `-a <PID>` after attachment. A WPF process can own several windows, and application-only selection can attach to a helper.

## Foreground ownership guard

Do not require the foreground HWND to remain unchanged. The operator may legitimately switch between Teams, a browser, or another application while testing runs.

The correct invariant is: **no window owned by the tested PID may become foreground**.

```powershell
function Assert-TestedProcessDoesNotOwnForeground {
    param([Parameter(Mandatory)][int] $AppPid)

    $foreground = [OffscreenWindowNative]::GetForegroundWindow()
    if ($foreground -eq [IntPtr]::Zero) {
        return
    }

    $foregroundPid = 0
    [OffscreenWindowNative]::GetWindowThreadProcessId(
        $foreground,
        [ref] $foregroundPid) | Out-Null

    if ($foregroundPid -eq $AppPid) {
        throw "Foreground ownership violation: PID $AppPid owns HWND $('0x{0:X}' -f $foreground.ToInt64())."
    }
}
```

Call this after every interaction that could create a new window or dialog.

## Dialogs and dynamic windows

After invoking an action that opens a dialog:

1. enumerate windows again for the same PID;
2. identify the newly titled dialog or owner relationship;
3. apply `WS_EX_NOACTIVATE` and offscreen positioning to the new HWND if the application did not inherit them;
4. attach by the dialog's decimal HWND; and
5. verify foreground ownership before continuing.

Never assume a dialog is part of the original UIA tree. WPF and WinUI dialogs can use separate HWNDs or popup hosts.

## Real-state versus fixture-state validation

Real-state validation:

- launches the production executable;
- uses the normal LocalAppData state resolver;
- passes no test fixture flags;
- exercises actual process supervision, API clients, and durable state; and
- respects every independent mutation confirmation.

Fixture validation:

- passes an explicit isolated state root;
- may seed synthetic records; and
- proves layout or deterministic UI behavior only.

Do not describe fixture evidence as connected production proof.

If an application has a built-in no-activation argument that requires a test state root, do not bypass its path validation or redirect it to LocalAppData. Use the native wrapper above for real-state observation.

## Evidence requirements

For each evidence artifact, record:

- filename;
- SHA-256;
- capture UTC;
- source commit;
- executable and relevant DLL SHA-256;
- executable start time and PID;
- capture mode: `real-state offscreen WS_EX_NOACTIVATE`;
- exact producer command;
- tested environment or scope identifier; and
- whether the interaction was read-only, local-only, metadata mutation, or externally confirmed mutation.

Screenshots of an offscreen window can be unreliable with some renderers. Prefer:

1. source-backed UIA properties;
2. application-provided render or evidence export;
3. `PrintWindow` only when its limitations are documented; and
4. visible screenshots only in a dedicated interactive desktop.

Do not claim pixel evidence when the capture path clips title bars, popups, hardware-accelerated content, or occluded windows.

## Safe cleanup

Close the application through its UIA Window pattern when that is part of the test:

```powershell
winapp ui invoke BtnClose -w $hwnd --json
```

If no app-owned close action exists, use the window-close UIA command supported by the harness. Allow the application's normal shutdown path to stop or reconcile owned children.

Afterward:

1. wait for the exact application PID to exit;
2. inspect only process identities launched or recorded by the application;
3. stop a remaining process only when PID and process start time both match the owned identity;
4. never kill by process name; and
5. confirm no testhost, helper, or application process remains.

Do not delete real application state as test cleanup.

## Failure checklist

When the test cannot find an element:

1. confirm the application PID still exists and is responsive;
2. enumerate all PID-owned windows;
3. confirm the product HWND still has the expected title;
4. verify the `-w` argument is decimal;
5. inspect the exact product HWND;
6. check whether the element is in a new dialog or popup HWND;
7. check whether navigation completed before searching;
8. verify the element is enabled and not virtualized; and
9. confirm no fixture-only AutomationId was assumed.

When the application takes focus:

1. record the offending foreground HWND and PID;
2. stop the background-safe run;
3. verify `WS_EX_NOACTIVATE` was applied to the product window and any newly created dialogs;
4. remove `click`, `focus`, `send-keys`, or global-input commands;
5. replace desktop-wide discovery with exact PID/HWND targeting; and
6. rerun from a clean application launch.

## Minimal acceptance bar

An offscreen run is valid only when:

- the exact production executable hash is recorded;
- production state, not fixture state, is used when intended;
- the correct product HWND is selected;
- every UI action uses PID/HWND-scoped UIA patterns;
- no tested-process window owns the foreground;
- the operator can continue using unrelated applications;
- all created dialogs remain non-activating and offscreen;
- shutdown is bounded; and
- no tested or helper process remains.
