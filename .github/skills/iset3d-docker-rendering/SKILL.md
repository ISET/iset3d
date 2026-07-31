---
name: iset3d-docker-rendering
description: Use when setting up ISET3D rendering on a new machine, when configuring ISETDocker MATLAB preferences for local CPU or GPU rendering, when a render fails before PBRT produces output, or when diagnosing piDockerConfig, piDockerDiagnose, stale PBRTContainer, Docker context, or GPU-visibility problems.
---

# Docker And PBRT Rendering Setup

MATLAB never renders anything itself. ISET3D writes PBRT text files, invokes
`docker ... pbrt ...`, and reads the resulting `.exr` back as an ISETCam
`scene` or `oi`. So every setup question reduces to: **where does the Docker
container run, and can it see a GPU?**

One preference decides that: `ISETDocker.remoteHost`.

- **Empty → local rendering.** MATLAB talks to the Docker daemon on this
  machine. The scene is written to `iset3d/local/<scene>/`, rendered in place
  with no file copying, and read straight back.
- **Set → remote rendering.** The local `docker` client is pointed at a remote
  daemon over SSH; the scene folder is uploaded, rendered there, and the result
  downloaded.

**Prefer local rendering.** Many sites render locally and never touch the
Stanford remote infrastructure. Set up local first; treat remote as an
optimization for large scenes or when a remote GPU is genuinely needed.

## Local Setup

### 1. Pull the image

```bash
docker pull digitalprodev/pbrt-v4-cpu
```

Docker Desktop (macOS/Windows) or Docker Engine (Linux) must be installed and
running. You can also let Docker pull the image on the first render.

**macOS renders on the CPU only.** Docker Desktop on macOS cannot pass a GPU
into a container, and there are no arm64 builds of these images, so on Apple
Silicon the CPU image runs under emulation — correct, just slow. Keep film
resolution and rays per pixel small.

### 2. Set the preferences

Set them directly rather than using the interactive `isetdocker.setUserPrefs`
wizard, whose menu is oriented toward the Stanford hosts. The canonical local
CPU block:

```matlab
setpref('ISETDocker','device','cpu');
setpref('ISETDocker','deviceID','');
setpref('ISETDocker','dockerImage','digitalprodev/pbrt-v4-cpu');
setpref('ISETDocker','remoteHost','');
setpref('ISETDocker','remoteUser','');
setpref('ISETDocker','renderContext','default');
setpref('ISETDocker','workDir',fullfile(piRootPath,'local'));
```

The two fields that matter most are `remoteHost` empty (keeps rendering local)
and `renderContext` set to `default` (this machine's Docker daemon).

**Clear the Stanford resource mount.** `PBRTResources` points at
`/acorn/data/iset/PBRTResources`, which does not exist off the Stanford
network. If it is set, Docker will try to mount it and fail:

```matlab
if ispref('ISETDocker','PBRTResources')
    rmpref('ISETDocker','PBRTResources');
end
```

Never set `PBRTContainer` by hand. It is transient state that ISET3D writes and
clears as it starts and stops containers.

### 3. Wire it up and verify

```matlab
getpref('ISETDocker')

ieInit;
if ~piDockerExists, piDockerConfig; end

piDockerDiagnose('render',false);
```

Then a small render:

```matlab
thisR = piRecipeDefault('scene name','chessset');
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',2);
scene = piWRS(thisR,'render flag','hdr');
sceneWindow(scene);
```

### Local GPU (Linux, or Windows via WSL2)

Requires NVIDIA drivers plus the NVIDIA Container Toolkit so Docker can pass
the GPU through with `--gpus`:

```matlab
setpref('ISETDocker','device','gpu');
setpref('ISETDocker','deviceID','0');
setpref('ISETDocker','dockerImage','vistalab/pbrt-v4-gpu');
setpref('ISETDocker','remoteHost','');
setpref('ISETDocker','remoteUser','');
setpref('ISETDocker','renderContext','default');
setpref('ISETDocker','workDir',fullfile(piRootPath,'local'));
```

Command-line preflight:

```bash
docker pull vistalab/pbrt-v4-gpu
docker run --rm --gpus device=0 vistalab/pbrt-v4-gpu nvidia-smi
```

`sceneEye` (human-eye optics) always renders on the CPU regardless of this
setting — see the `iset3d-sceneEye` skill.

## The Diagnostic Entry Point

`piDockerDiagnose` is the first thing to run when a render fails, and it is
cheaper and more informative than poking at Docker by hand:

```matlab
report = piDockerDiagnose('render',false);            % no render; fast
report = piDockerDiagnose('render',true);             % adds a tiny acceptance render
report = piDockerDiagnose('resetStaleContainer',true);% repair stale container state
```

It checks the `docker` and `rsync` commands, validates the `ISETDocker`
preference structure, checks the Docker context, SSH/SFTP reachability (remote
only), GPU visibility, and stale PBRT container state.

The returned struct has `ok`, `errors`, `warnings`, `checks`, `repairHints`,
and `prefs`. **Read `report.repairHints`** — it names the command to run.

Related helpers: `piDockerExists` (is Docker findable at all),
`piDockerConfig` (set up the context and MATLAB environment),
`piDockerCurrentContext`, `piDockerTest`, `piDockerWarmup`.

## Preference Reference

All under the `ISETDocker` preference group. They are machine-specific and
persist across MATLAB sessions.

| Preference | Meaning |
| --- | --- |
| `remoteHost` | SSH host; **empty means local**. Commonly `orange.stanford.edu`. |
| `remoteUser` | SSH/SFTP user for remote rendering. |
| `renderContext` | Docker context name. `default` locally; commonly `remote-orange`. |
| `workDir` | Local: `fullfile(piRootPath,'local')`. Remote: `/home/<user>/ISETRemoteRender`. |
| `dockerImage` | `digitalprodev/pbrt-v4-cpu` or `vistalab/pbrt-v4-gpu`. |
| `device` / `deviceID` | `cpu`/`gpu` and which GPU index. |
| `PBRTResources` | Shared resource mount. Stanford-only; **clear it for local work**. |
| `PBRTContainer` | Transient running-container name. ISET3D owns this; do not set it. |

`DockerPref` is an App Designer GUI that displays and validates these
preferences and can apply named presets from
`docker/config/dockerpresets.json`. It is a convenience, not a requirement, and
most shipped presets target the Stanford servers — after applying one, confirm
`remoteHost` is empty and `PBRTResources` is cleared before rendering locally.

## Common Failures

**Docker not found even though the terminal finds it.** MATLAB launched from
the Dock/Spotlight/Finder does not inherit the login shell `PATH`.
`piDockerExists` and `piDockerConfig` already prepend `/usr/local/bin` and
`/opt/homebrew/bin` on macOS to work around this. If a different install
location is involved, add it to `PATH` with `setenv`.

**`no CUDA-capable device is detected`.** Usually a stale `PBRTContainer`
preference pointing at a container that no longer sees a GPU. Run
`piDockerDiagnose('render',false)` first for the diagnosis, then
`piDockerDiagnose('resetStaleContainer',true)` rather than removing containers
by hand.

**Cleanup failure at MATLAB shutdown.** `docker/finish.m` removes the current
PBRT container when `ISETDocker.PBRTContainer` is set. If it reports a failure,
read the message — silently ignored cleanup failures are a common cause of
later rendering confusion.

**Mount errors mentioning `/acorn`.** `PBRTResources` is set on a machine that
cannot see the Stanford storage. Clear it.

**`textures/<file>: file not found`.** This is *not* a Docker problem — PBRT
started and read the scene. It is a resource-staging problem; see the
`iset3d-materials-and-textures` and `iset3d-remote-resources-database` skills.

## Remote Rendering

Remote rendering is a separate topic with its own failure modes (rsync staging,
the shared `/acorn` resource tree, `useDB`, Mongo metadata). Configure it only
after local rendering works, and see the `iset3d-remote-resources-database`
skill. Off-campus access to `orange.stanford.edu` requires an active Stanford
VPN connection.

You do **not** need the Stanford VPN, an `orange` account, or the `acorn` mount
for local rendering.

## Related

- `iset3d-recipe-workflow` — the write/render/show loop this setup serves.
- `iset3d-remote-resources-database` — remote hosts, staging, and the database.
- `iset3d-testing-workflow` — how `_remote` tests are excluded when Docker is
  unavailable.

Long-form: [docs/setting-up-iset3d.md](../../../docs/setting-up-iset3d.md),
[docs/remote-rendering.md](../../../docs/remote-rendering.md).
