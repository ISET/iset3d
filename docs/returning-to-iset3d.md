# Returning To ISET3D After Time Away

Use this when you come back to ISET3D after a few weeks or months and no longer
remember what has to be running. Work from the top and stop at the first
failure, because each step depends on the ones above it. If nothing is wrong,
the list takes a few minutes.

An AI assistant can run nearly all of this for you: ask it to run the ISET3D
startup checks (the `iset3d-session-startup` skill). The VPN and CardinalKey are
the parts only you can do.

For a first-time install, start with
[setting-up-iset3d.md](setting-up-iset3d.md) instead.

## The Checklist

### 1. Stanford access (remote rendering only)

Skip this step if you render locally.

- **Cisco Secure Client** is installed and connected to `su-vpn.stanford.edu`.
  This is required off campus. After a long gap the client may need
  reinstalling.
- **CardinalKey** has not expired. Renew it if it has.

Then confirm from a terminal, replacing `<user>` with your account on `orange`:

```bash
/opt/cisco/secureclient/bin/vpn state      # expect: state: Connected
ssh -o BatchMode=yes <user>@orange.stanford.edu true && echo ssh-ok
docker --context remote-orange version --format '{{.Server.Version}}'
```

### 2. Update both repositories

ISET3D depends on ISETCam, so update them together:

```bash
git -C ~/Documents/MATLAB/isetcam pull
git -C ~/Documents/MATLAB/iset3d pull
```

### 3. Start MATLAB and check the path

```matlab
addpath(genpath(fullfile(getenv('HOME'),'Documents','MATLAB','isetcam')));
addpath(genpath(fullfile(getenv('HOME'),'Documents','MATLAB','iset3d')));

which ieInit      % must print a path inside your isetcam folder
ieInit;           % takes no arguments; see "What ieInit Does" below
```

### 4. See where rendering is set to happen

```matlab
getpref('ISETDocker')
```

Look at `remoteHost`. Empty means local; `orange.stanford.edu` means remote.
These preferences persist across sessions, so you are seeing whatever you last
set, possibly months ago. To change them, see [Preferences](#preferences).

### 5. Check that the renderer is reachable

```matlab
report = piDockerDiagnose('render',false);
```

`report.ok` should be 1. If it is not, read `report.repairHints`.

**This does not run PBRT.** It can report success on a machine that cannot
render at all, so it does not replace step 7.

### 6. Check the code

```matlab
results = iset3dUnitTest;
```

This is the `core` suite, the default. It needs no Docker or network, so **a
pass says nothing about the VPN, Docker, or PBRT.** It took about a minute and a
half when this was written. `iset3dUnitTest('full')` adds 5 render tests and took
about 5 minutes rendering on `orange`.

### 7. Render the chess set

This is the step that proves rendering works. It writes the scene, renders it,
and reads the result back. It took 36 seconds on `orange` when this was written.

```matlab
run = iset3dTutorialTest('selection','t_piIntro_chess');
```

The summary must show `Total Passed: 1` and `Total Skipped: 0`. **A skip is not a
pass.** It means the runner decided the renderer was not ready, and
`ieTestReport(run,'List','skipped')` shows why.

The chess set tutorial uses a pinhole camera. If you are about to work with
lenses, also run `iset3dTutorialTest('selection','t_piIntro_lens')`, which
returns an optical image through a lens file.

## What Each Check Proves

| Check | What a pass proves | What it does not prove |
| --- | --- | --- |
| `iset3dUnitTest` (`core`) | The MATLAB code and its use of ISETCam | Anything about the VPN, Docker, or PBRT |
| `piDockerDiagnose('render',false)` | Docker, rsync, preferences, Docker context, SSH, and GPU visibility | That PBRT can run |
| `piDockerDiagnose('render',true)` | A tiny scene renders end to end | Your scene, or lens cameras |
| `iset3dTutorialTest('selection','t_piIntro_chess')` | A real scene renders end to end, pinhole camera | Lens cameras |
| `iset3dTutorialTest('selection','t_piIntro_lens')` | A real scene renders through a lens file | Other lenses or camera types |
| `iset3dUnitTest('full')` | `core` plus the `_remote` render tests | Tutorials and examples |

**You do not need `iset3dExampleTest` or the full `iset3dTutorialTest` to get
started.** They run every script (95 examples, 64 of which render, and 45
tutorials), so they suit a change to shared code rather than a startup check.
See [testing.md](testing.md).

## What ieInit Does

**`ieInit` takes no parameters.** It is an ISETCam script, not a function, and it
runs in your workspace. It:

1. Closes the ISET windows and all other figures.
2. Runs `clear global`, which removes `vcSESSION`.
3. Runs `clearvars` if `ieSessionGet('init clear')` is true, **which is the
   default**. Everything in your workspace is deleted.
4. Starts a new ISET session.

It does not set the path, change Docker preferences, or start Docker. Because it
is a script, calling it inside a function clears that function's variables,
including its input arguments.

To keep your workspace variables when you call `ieInit`:

```matlab
ieSessionSet('init clear',false);    % saved across sessions
```

The test runners turn this off for the length of a run and restore it afterward.

**`piDockerConfig` does not set preferences either.** It finds the `docker`
command, adds it to `PATH` for this session, and starts Docker Desktop if needed.
You will see `if ~piDockerExists, piDockerConfig; end` at the top of many
tutorials for that reason.

## Preferences

MATLAB preferences are saved per MATLAB release and survive restarts.

| Group | Set by | Do you need to touch it? |
| --- | --- | --- |
| `ISETDocker` | You | **Yes.** This decides where rendering happens. |
| `ISET3d` | `piPrefsInit`, on first use | Rarely. Defaults: `meanluminance` 100, `meanilluminance` 10, `wave` 400:10:700, `verbose` 1. Other fields are timing records. |
| `ISET` | ISETCam, through `ieSessionSet` | Rarely. `initclear`, `waitbar`, and `fontSize` are the settings; most others are window state. |
| `db` | You, for database work only | Not for ordinary rendering. It holds a password, so do not paste its contents anywhere. See [rendering-database.md](rendering-database.md). |
| `docker` | Older ISET3D versions | No. This group is left over, and only `resourceLocation` is still read. |

### ISETDocker

| Preference | Local CPU | Stanford `orange` | Meaning |
| --- | --- | --- | --- |
| `remoteHost` | `''` | `orange.stanford.edu` | **The switch.** Empty means local. |
| `renderContext` | starred name in `docker context ls` | `remote-orange` | Docker context. Used literally, and an empty value fails validation. |
| `remoteUser` | `''` | your account | SSH and SFTP user. |
| `workDir` | `fullfile(piRootPath,'local')` | `/home/<user>/ISETRemoteRender` | Mounted at the same path inside the container. |
| `device` | `'cpu'` | `'gpu'` | |
| `deviceID` | `''` | `'0'` (24 GB) or `'1'` (8 GB) | Which GPU. This is a string. |
| `dockerImage` | `digitalprodev/pbrt-v4-cpu` | `vistalab/pbrt-v4-gpu` | Without AVX-512, add `:test` to the local image. See [below](#illegal-instruction-from-the-cpu-image). |
| `PBRTResources` | remove it | `/acorn/data/iset/PBRTResources` | Shared resources, Stanford only. |
| `PBRTContainer` | never set | never set | Running container. ISET3D manages it. |
| `batch` | omit | omit | If true, a remote render does not download its result. |
| `label` | any text | any text | A name for this configuration. |

To render on `orange`:

```matlab
setpref('ISETDocker','remoteHost','orange.stanford.edu');
setpref('ISETDocker','remoteUser','<user>');
setpref('ISETDocker','renderContext','remote-orange');
setpref('ISETDocker','workDir','/home/<user>/ISETRemoteRender');
setpref('ISETDocker','device','gpu');
setpref('ISETDocker','deviceID','1');
setpref('ISETDocker','dockerImage','vistalab/pbrt-v4-gpu');
setpref('ISETDocker','PBRTResources','/acorn/data/iset/PBRTResources');
```

On a machine that does not have the `remote-orange` context yet, create it once
from a terminal:

```bash
docker context create remote-orange --docker "host=ssh://<user>@orange.stanford.edu"
```

To render locally:

```matlab
setpref('ISETDocker','remoteHost','');
setpref('ISETDocker','remoteUser','');
setpref('ISETDocker','renderContext','desktop-linux');   % the starred name in: docker context ls
setpref('ISETDocker','workDir',fullfile(piRootPath,'local'));
setpref('ISETDocker','device','cpu');
setpref('ISETDocker','deviceID','');
setpref('ISETDocker','dockerImage','digitalprodev/pbrt-v4-cpu');   % add :test on a CPU without AVX-512
if ispref('ISETDocker','PBRTResources'), rmpref('ISETDocker','PBRTResources'); end
```

Run steps 5 and 7 again after switching. `DockerPref` is a GUI for the same
settings.

## Common Problems After A Break

| What you see | What it means | What to do |
| --- | --- | --- |
| `which ieInit` prints nothing | ISETCam is not on the path | Step 3 |
| `ssh` times out, or the `Remote SSH` check fails | The VPN is not connected, or SSH access has lapsed | Step 1 |
| The `Docker context` check fails in local mode, or `failed to connect ... /var/run/docker.sock` | `renderContext` names a context that does not work on this machine, which can happen with `default` on Docker Desktop for Mac | Run `docker context ls` and set `renderContext` to the starred name |
| The `Docker context` check fails in remote mode | The context does not exist on this machine | Create it as shown above |
| `Docker render failed with status 132` and `Illegal instruction` | The PBRT CPU image needs AVX-512, which this CPU lacks | Use `digitalprodev/pbrt-v4-cpu:test`. See below. |
| A tutorial is `Skipped` with `rendering unavailable` | The renderer was not ready, so nothing rendered | Read the reason, then go back to step 5 |
| A GPU render on `orange` never returns, with PBRT using CPU but the GPU at 0% in `nvidia-smi` | PBRT has hung. This was seen once, in a render that normally takes seconds, and three repeats ran normally. MATLAB waits indefinitely. | From a terminal, run `docker --context remote-orange exec <container> pkill pbrt`, using the name in `getpref('ISETDocker','PBRTContainer')`, then render again |
| `no CUDA-capable device is detected` | `PBRTContainer` is stale | `piDockerDiagnose('resetStaleContainer',true)` |
| Mount errors mentioning `/acorn` in local mode | `PBRTResources` is still set | Remove it, as in the local block above |
| Your variables disappear after `ieInit` | `init clear` is on | See [What ieInit Does](#what-ieinit-does) |

### Illegal instruction from the CPU image

PBRT's build compiles for the CPU of the machine doing the build (`-march=native`),
so an image can need instructions that another CPU lacks.
`digitalprodev/pbrt-v4-cpu:latest`, built in June 2024, contains AVX-512
instructions. On an Intel Core i9-9900K iMac, which has no AVX-512, it crashes even
for a one-sphere scene, while `piDockerDiagnose('render',false)` reports no problem.

To check a CPU:

```bash
sysctl -n hw.optional.avx512f    # macOS: 0 means no AVX-512
grep -c avx512f /proc/cpuinfo    # Linux: 0 means no AVX-512
```

On a CPU without AVX-512, use the December 2023 image, which has no AVX-512
instructions:

```matlab
setpref('ISETDocker','dockerImage','digitalprodev/pbrt-v4-cpu:test');
```

On that iMac this image passed `iset3dUnitTest('full')` and the chess set and lens
tutorials. Its pinhole, lens, microlens, ray transfer, and human eye renders were
compared with current PBRT on `orange`. Mean radiance agreed to five digits, and no
single pixel and wavelength band differed by more than 0.7%.

**Compare numbers only between renders from the same image.** On two chess set
scenes, `:latest` differed from current PBRT by up to about 3.5% in individual
wavelength bands, although the overall mean agreed to about 0.03%. `:latest`
predates a commit that turned wavelength jitter back on, which is the likely reason.

These images do not solve the problem:

| Image | Why not |
| --- | --- |
| `vistalab/pbrt-v4-cpu-intel` | On Docker Hub this is the same image as `digitalprodev/pbrt-v4-cpu:latest`, despite its name. A local copy from before that change may be a 2021 build, which fails on lens cameras with `omni: camera type unknown`. Pulling replaces that copy. |
| `vistalab/pbrt-v4-cpu:x86_64` and `:latest` | They contain AVX-512 instructions too. They are on `orange` and cannot be pulled from Docker Hub. |

## Related

- [setting-up-iset3d.md](setting-up-iset3d.md) — first-time local setup.
- [remote-rendering.md](remote-rendering.md) — how remote rendering works.
- [testing.md](testing.md) — the test runners.
