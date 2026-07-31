---
name: matlab-environment-setup
description: Use when setting up or troubleshooting a MATLAB session for ISET3D — repository path setup, the ISETCam dependency, "which ieInit" not found, configuring the VS Code MATLAB extension, MATLAB Desktop versus VS Code startup order, guarding startup.m, or running MATLAB non-interactively with -batch from an agent or shell.
---

# MATLAB Environment Setup For ISET3D

ISET3D is a MATLAB toolbox. **ISETCam (`../isetcam`) is a required dependency**
and must be on the path whenever ISET3D is used or tested. ISET3D code and
tests may call ISETCam utilities directly, including `ieInit`, `ieTestReport`,
`ieWebGet`, and `iePublish`. Do not duplicate a utility ISETCam already
supplies.

## Repository Path Setup

After starting MATLAB, paste these into the Command Window of the session you
intend to use:

```matlab
addpath(genpath(fullfile(getenv('HOME'),'Documents','MATLAB','isetcam')));

addpath(genpath(fullfile(getenv('HOME'),'Documents','MATLAB','iset3d')));

which ieInit
```

`which ieInit` returning nothing means ISETCam is not on the path — fix that
before anything else, because most ISET3D failures downstream of a missing
ISETCam are misleading.

Adjust the paths if your checkouts live elsewhere. The canonical copy of this
block is [.github/matlab-paths.md](../../matlab-paths.md).

Rendering needs one more step — Docker configuration. See the
`iset3d-docker-rendering` skill.

## Configuring The VS Code MATLAB Extension

Point the extension at your MATLAB app bundle:

1. Open **Settings** (`Cmd + ,`).
2. Search for `matlab.installPath`.
3. Set it to your installation, e.g. `/Applications/MATLAB_R2025b.app`.

Or edit the JSON directly. Global user settings live at
`~/Library/Application Support/Code/User/settings.json`; a project
`.vscode/settings.json` overrides them.

```jsonc
"MATLAB.installPath": "/Applications/MATLAB_R2025b.app",
"MATLAB.matlabConnectionTiming": "onStart",
"files.associations": {
    "*.m": "matlab"
}
```

Precedence: **workspace settings override user settings.**

## Recommended Startup Order

When you need the MATLAB Desktop or Live Editor, **start MATLAB from the macOS
Desktop first, then open VS Code.** With `matlabConnectionTiming` set to
`onStart`, the extension starts a *second* background MATLAB process for
language-server features once you open a `.m` file. That is expected: the
Desktop session owns the GUI, the VS Code session supports the editor.

Starting the Desktop first avoids a stale VS Code-started MATLAB or MathWorks
ServiceHost process blocking the Desktop app later.

1. Launch MATLAB from `/Applications/MATLAB_R2025b.app`.
2. Wait until the Desktop is fully open and responsive.
3. Open VS Code and this repository.
4. Open a `.m` file so the extension starts its background session.
5. Paste the path commands above into the session you intend to use.

If the Desktop later refuses to open, quit VS Code and MATLAB, then use
Activity Monitor to stop lingering `MATLAB`, `MathWorksServiceHost`,
`MATLABConnector`, and related helper processes before relaunching.

## Guarding `startup.m`

The extension may launch MATLAB differently from the Desktop app. If your
personal `startup.m` does substantial desktop-specific initialization, guard it:

```matlab
% Detect if MATLAB is being launched by VS Code
isVSCode = ~usejava('desktop') || ...
    ~isempty(getenv('VSCODE_PID')) || ...
    ~isempty(getenv('VSCODE_IPC_HOOK_CLI'));

if isVSCode
    disp('Set up ISET3D paths manually — see .github/matlab-paths.md')

    % Share the engine so the VS Code extension can connect for debugging
    matlab.engine.shareEngine;

    fprintf('MATLAB initialized for VS Code.\n');
    return
elseif isdeployed
    % Skip initialization for compiled apps
else
    % Standard Desktop initialization
    reset(groot);
    % Your usual plotting/graphics defaults here
end
```

## Verification

In the MATLAB session, run `path` and confirm both the ISETCam and ISET3D
directories appear. Then:

```matlab
ieInit;
piRootPath
iset3dRootPath
```

## Non-Interactive / CLI MATLAB

A local MATLAB executable is available at
`/Applications/MATLAB_R2025b.app/bin/matlab` and can be used with `-batch` for
non-interactive checks, for example from an agent or a CI-style shell:

```bash
/Applications/MATLAB_R2025b.app/bin/matlab -batch "addpath(genpath('~/Documents/MATLAB/isetcam')); addpath(genpath('~/Documents/MATLAB/iset3d')); results = iset3dUnitTest;"
```

**If launching MATLAB from a sandboxed shell fails silently or exits with
status 1, retry unsandboxed or escalated.** MATLAB needs to write preferences
and cache files outside the repository, and a sandbox blocking that produces a
confusing silent failure rather than a clear error.

Note that ISET3D's Docker preferences also live in MATLAB preferences
(`ISETDocker`), so a session that cannot write preferences cannot render.

## Sessions For Test Runs

Tutorial and example smoke runs call `ieInit` between scripts, which closes
figures and resets `vcSESSION`. Start those runs in a **dedicated MATLAB
session** so they do not destroy work in progress. See the
`iset3d-testing-workflow` skill.

## Related

- `iset3d-docker-rendering` — the other half of a working ISET3D setup.
- `iset3d-testing-workflow` — running the suites once the path is right.
- VS Code specifics: [.vscode/matlab-setup.md](../../../.vscode/matlab-setup.md).
