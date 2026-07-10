# Bug report: `uifigure()` corrupts its Position when a normalized `DefaultFigurePosition` is set on `groot`

## Summary

Setting a normalized root default figure position/units (a long-standing,
documented customization, typically done once in `startup.m`) causes
`uifigure()` to compute a wildly incorrect `Position` — millions of pixels
wide/tall — instead of the intended default. On MATLAB R2025b this produces a
huge, off-screen window but MATLAB survives. On MATLAB R2026a the same
corrupted `Position` hangs MATLAB Desktop, requiring a force-quit. No crash
dump is produced in either case, consistent with a hang rather than a
segmentation fault.

This was originally reported as "MATLAB crashes" while running an ISET3D
tutorial (`t_assetsWorldRot.m`), which calls `thisR.assets.show` — the first
line of code in a whole test run that happens to call `uifigure()`. ISET3D
code is not implicated: a bare `uifigure()` call with no ISET3D code loaded
reproduces the same corruption and the same hang.

## Environment

|                                             |                                             |
| ------------------------------------------- | ------------------------------------------- |
| Machine                                     | Apple Silicon Mac (`MACA64`)              |
| macOS                                       | 26.5 (Build 25F71)                          |
| MATLAB (crashes)                            | R2026a,`26.1.0.3276743 (R2026a) Update 3` |
| MATLAB (does not crash, but still corrupts) | R2025b,`25.2.0.3042426 (R2025b) Update 1` |
| Screen size (`get(0,'ScreenSize')`)       | `[1 1 2560 1440]`                         |

## Minimal reproduction

```matlab
reset(groot);
set(groot, 'DefaultFigureUnits', 'normalized');
set(groot, 'DefaultFigurePosition', [0.0070, 0.55, 0.28, 0.36]);

uifigure   % R2025b: opens a huge, mostly off-screen window
           % R2026a: hangs MATLAB Desktop; requires force-quit
```

No other toolboxes, ISET3D, or third-party code are required. This is a
two-line `groot` customization (of the kind many users place in `startup.m`)
followed by a plain `uifigure()` call.

### What a clean session produces

With no custom `groot` defaults, `uifigure()` behaves normally:

```matlab
>> f = uifigure;
>> f.Units
ans = pixels
>> f.Position
ans = 1000   818   560   420
```

### What the corrupted session produces

After the two `set(groot, ...)` calls above:

```matlab
>> f = uifigure;
>> f.Units
ans = pixels
>> f.Position
ans = 2560001  1177921  1433600   604800
```

Notice `Units` reports `pixels` in both cases — `uifigure` does not adopt
`'normalized'` — but the numeric `Position` in the corrupted case is not a
sane pixel position on a 2560x1440 screen.

## Root cause analysis (decoded)

The corrupted `Position` is not random. It matches this formula exactly,
where `[1000, 818, 560, 420]` is `uifigure`'s own clean-session default
`Position` and `[2560, 1440]` is the real screen size:

```
X' = ScreenWidth  * DefaultX + 1  = 2560 * 1000 + 1 = 2,560,001   (matches)
Y' = ScreenHeight * DefaultY + 1  = 1440 *  818 + 1 = 1,177,921   (matches)
W' = ScreenWidth  * DefaultWidth  = 2560 *  560     = 1,433,600   (matches)
H' = ScreenHeight * DefaultHeight = 1440 *  420     =   604,800   (matches)
```

This is consistent with `uifigure`'s internal normalized-to-pixel conversion
being applied twice: once correctly (turning the customized `groot` position
into `uifigure`'s own already-computed default pixel `Position`), and once
more by treating that pixel-valued result as if it were still a normalized
fraction and re-multiplying by the screen size. The `+1` on X/Y but not on
width/height is consistent with an off-by-one from the screen origin
(`get(0,'ScreenSize')` itself starts at `[1 1 ...]`, not `[0 0 ...]`) entering
the position calculation but not the size calculation.

The resulting request — a window roughly 1.43M x 0.6M pixels — is what each
MATLAB release then handles differently:

- **R2025b**: creates a very large, mostly off-screen window rather than
  crashing. Already wrong behavior (no real display is 1.4 million pixels
  wide), but survivable.
- **R2026a**: the same request appears to hang the whole Desktop session
  indefinitely (no crash dump is written; consistent with a UI-thread
  deadlock rather than a segfault, and consistent with force-quit being the
  only way out).

## Why `'pixels'` units avoid it

Setting the same intended position using `'pixels'` units (pre-multiplying
the normalized fractions by the actual screen size once, ourselves) does not
trigger the bug — but only because `uifigure` ignores the custom default
entirely in that case and silently falls back to its own built-in default,
rather than honoring the requested position:

```matlab
reset(groot);
ss = get(0, 'ScreenSize');
set(groot, 'DefaultFigureUnits', 'pixels');
set(groot, 'DefaultFigurePosition', [0.0070, 0.55, 0.28, 0.36] .* ss([3 4 3 4]));

f1 = figure;    % Position = [17.92  792  716.8  518.4]  -- honors the custom default, as expected
f2 = uifigure;  % Position = [1000   818  560    420]    -- ignores the custom default; uses its own stock default instead
```

So `uifigure`'s handling of root `Default*` figure properties is inconsistent
in both cases relative to `figure()`: normalized units corrupt the geometry
(sometimes fatally), pixel units are silently ignored.

## Impact / severity

- Any user with a `startup.m`/`startup_vscode.m`-style customization that sets
  `DefaultFigureUnits`/`DefaultFigurePosition` in normalized units — a common,
  long-documented pattern for sizing/positioning figure windows consistently —
  will hit this the moment any code (their own, a toolbox, or an App
  Designer-based app) calls `uifigure()`.
- On R2026a this is a full Desktop hang with no diagnostic crash dump,
  requiring a force-quit and loss of any unsaved session state.
- The trigger does not require any unusual code: `uifigure` with zero
  arguments is enough.

## Workaround (applied locally)

Use `'pixels'` units for the root default instead of `'normalized'`,
precomputing the equivalent pixel position from the current screen size at
startup time:

```matlab
% before (triggers the bug)
set(groot, 'DefaultFigureUnits', 'normalized');
set(groot, 'DefaultFigurePosition', [0.0070, 0.55, 0.28, 0.36]);

% after (avoids it)
set(groot, 'DefaultFigureUnits', 'pixels');
ss = get(0, 'ScreenSize');
set(groot, 'DefaultFigurePosition', [0.0070, 0.55, 0.28, 0.36] .* ss([3 4 3 4]));
```

This preserves the intended placement/size for classic `figure()` windows
(which honor the custom default correctly in both unit systems) and lets
`uifigure()` fall back to its own safe built-in default instead of computing
a corrupted one.

## How this was diagnosed

1. `t_assetsWorldRot.m` (an ISET3D tutorial) reliably hung MATLAB Desktop at
   the same point across repeated runs, and running it standalone reproduced
   the same hang.
2. Running the identical script headlessly (`matlab -batch`) completed
   successfully end to end, including the render calls and the `uifigure`
   call — ruling out Docker/rendering and pointing at something specific to
   the interactive Desktop session.
3. Instrumenting `thisR.assets.show` (ISET3D's asset-tree viewer, which calls
   `uifigure`+`uitree`) with `fprintf`/`drawnow` checkpoints showed execution
   reaching "calling `uifigure()`" but never "`uifigure()` returned" — i.e.
   the hang is inside MATLAB's own `uifigure` constructor.
4. A bare `f = uifigure;` at the command line, with no ISET3D code loaded,
   reproduced the same hang, fully isolating it from ISET3D.
5. Running the same bare call on R2025b did not hang, but revealed a huge,
   off-screen window — the clue that pointed at a `groot` graphics default
   rather than an installation-level MATLAB problem, since a personal
   `startup_vscode.m` sets exactly such a default and only runs in genuine
   interactive Desktop sessions (not in `-batch` runs launched from an
   environment with `VSCODE_PID` set, which is why earlier headless testing
   never encountered it).
6. Reproducing just the two `set(groot, ...)` lines from that startup script
   followed by `uifigure` reproduced the exact corrupted `Position` shown
   above on both R2025b and R2026a, confirming the root cause and letting the
   fix be verified before applying it.
