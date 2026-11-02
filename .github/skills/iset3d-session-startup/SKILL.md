---
name: iset3d-session-startup
description: Use at the start of ISET3D work after time away, or when asked to check, verify, or restore a setup — "I'm back", "startup checks", "is everything working", before a session's first render — or when the topic is Cisco Secure Client, the Stanford VPN, CardinalKey, SSH to orange, which ISETDocker setpref values to use, what ieInit does or whether it takes parameters, or whether iset3dUnitTest or iset3dExampleTest proves that rendering works.
---

# ISET3D Session Startup

The person may have been away for months and may not remember the setup. Run the
checks yourself where you can, say plainly what only they can do, and finish with
a short list of what passed, what failed, and what was not checked.

Stop at the first failure, because later checks depend on earlier ones. Do not
change saved preferences unless asked.

The version written for people, with the full preference reference, is
[docs/returning-to-iset3d.md](../../../docs/returning-to-iset3d.md). When a fact
here changes, update that file too.

## Only The Person Can Do These

- Connect Cisco Secure Client to the Stanford VPN. It is required off campus and
  may need reinstalling after a long gap.
- Check that their CardinalKey has not expired.

Ask about these only if the checks below fail. They do not apply to local
rendering.

## The Checks, In Order

Read `ISETDocker.remoteHost` first. Empty means local, and the Stanford checks do
not apply.

| # | Check | Pass |
| --- | --- | --- |
| 1 | `/opt/cisco/secureclient/bin/vpn state` | `state: Connected` |
| 2 | `ssh -o BatchMode=yes <user>@orange.stanford.edu true` | Exit 0 |
| 3 | `docker --context remote-orange version` | Shows a server version |
| 4 | `git fetch`, then `git status -sb`, in `iset3d` and `../isetcam` | Not behind. Report it if behind or dirty, and do not pull without asking. |
| 5 | `which ieInit` with both repositories on the path | A path inside `isetcam` |
| 6 | `getpref('ISETDocker')` | Tell the person which mode this is |
| 7 | `piDockerDiagnose('render',false)` | `report.ok` is 1 |
| 8 | `iset3dUnitTest` | No failures |
| 9 | `iset3dTutorialTest('selection','t_piIntro_chess')` | `Total Passed: 1` and `Total Skipped: 0` |

Add `iset3dTutorialTest('selection','t_piIntro_lens')` if the work involves
lenses.

## What A Pass Does Not Prove

- **`iset3dUnitTest` defaults to `core`,** which excludes every `_remote` test. It
  never touches Docker, the VPN, or PBRT.
- **`piDockerDiagnose('render',false)` never runs PBRT.** On an Intel i9-9900K
  iMac it returned `ok = 1` while every render crashed with `Illegal instruction`
  (status 132).
- **A render script can report `Skipped` rather than `Failed`** when the renderer
  is not ready, so a summary with no failures may mean nothing rendered. Check the
  skip count.
- **`t_piIntro_chess` uses a pinhole camera,** so it does not exercise lens files.
- **Remote and local modes take different paths through `piWrite`.** A pass in one
  mode does not establish the other.

`iset3dExampleTest` and a full `iset3dTutorialTest` are not startup checks. They
run 95 and 45 scripts. Use them after a change to shared code.

## ieInit And Preferences

**`ieInit` takes no parameters.** It is a script: it closes figures, clears
globals, and runs `clearvars` when `ieSessionGet('init clear')` is true, which is
the default. Called inside a function, it deletes that function's variables,
including its arguments, so call it from a small helper function.

**`piDockerConfig` does not set preferences.** It finds `docker` and adjusts `PATH`
for the session. Set `ISETDocker` values with `setpref` or `DockerPref`. The values
for each mode are tabulated in the doc linked above.

`renderContext` is used literally, and leaving it empty fails validation. In local
mode use the starred name from `docker context ls`, since `default` can fail on
Docker Desktop for Mac. It did on an Intel iMac, where `desktop-linux` worked.

## Running Checks From An Agent Shell

- Plain `matlab -batch` works for renders, with no pseudo-terminal wrapper, even
  though the render command uses `docker exec -it`. See the
  `matlab-environment-setup` skill for launching it.
- **Protect saved preferences.** To try another mode, set `MATLAB_PREFDIR` to a
  scratch folder holding a copy of `matlabprefs.mat` from `prefdir`, and confirm
  `prefdir` inside MATLAB before changing anything.
- **Never print `getpref('db')`.** It holds a password. Print `fieldnames` only.
- **Use a fresh output folder when testing file staging.** `thisR.set('outputfile',...)`
  can point it under `local/`. Old copies in `local/<scene>/lens/` and in
  `~/ISETRemoteRender/<scene>/lens/` on the host can hide a staging bug. The
  remote folder name must match the input scene folder name, because
  `isetdocker.render` uses one for the upload and the other for the render
  command.
- **`docker -v` creates a missing host path owned by root.** Create it over SSH
  first, and pass `--user` so the output is removable.
- The default shell may be zsh, which does not split `$VAR` into words and treats
  `$VAR:u` as a modifier. Use a shell function and `${VAR}`.
- `docker/finish.m` removes the session's PBRT container when MATLAB exits.
  Confirm with `docker ps`, and leave old exited containers alone unless asked.
- The tutorial runner leaves a dated run folder in `local/`, and `t_piIntro_chess`
  rewrites `local/chessset/`. Both are git-ignored.

## Related

- `matlab-environment-setup` — paths, VS Code, and launching MATLAB.
- `iset3d-docker-rendering` — preference details and render failures.
- `iset3d-remote-resources-database` — remote staging and `/acorn`.
- `iset3d-testing-workflow` — the test runners.
