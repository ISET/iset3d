# Setting Up ISET3D For Local Rendering

This guide is for people who want to render ISET3D scenes on their **own
computer**, or on another machine in their own environment, without access to
the Stanford render servers (`orange.stanford.edu`) or the shared Stanford
storage (`acorn`). If you have a laptop or desktop that can run Docker, you can
render the introductory scenes and work through the tutorials.

If you are at Stanford and have access to the remote GPU servers, use
[remote-rendering.md](remote-rendering.md) instead. This document deliberately
avoids the Stanford-only infrastructure.

## How Rendering Actually Works

The most important thing to understand is that **MATLAB never renders anything
itself.** ISET3D builds a scene description (a *recipe*), writes it out as PBRT
text files, and then asks **PBRT** &mdash; the physically based renderer &mdash;
to do the actual work. PBRT always runs **inside a Docker container**. MATLAB
just orchestrates: write the files, invoke `docker ... pbrt ...`, then read the
rendered `.exr` image back and wrap it as an ISETCam `scene` or `oi`.

So the entire setup problem reduces to one question: **where does the Docker
container run, and can it see a GPU?**

Everything follows from a single decision inside ISET3D. When it renders, it
looks at one preference, `ISETDocker.remoteHost`:

- **`remoteHost` is empty &rarr; local rendering.** MATLAB talks to the Docker
  daemon on your own machine. The scene is written to `iset3d/local/<scene>/`,
  the container renders it in place (no file copying), and the result is read
  straight back. **This is the whole game for rendering on your own computer,
  and it is what this guide sets up.**
- **`remoteHost` is set &rarr; remote rendering.** MATLAB points the local
  `docker` command at a remote daemon over SSH, uploads the scene, renders
  there, and downloads the result. This is the advanced path covered briefly at
  the end.

## Prerequisites

1. **MATLAB.** ISET3D is a MATLAB toolbox.
2. **ISETCam and ISET3D on the MATLAB path.** ISETCam is a required dependency.
   Clone both repositories, add them to your path, and start a session with
   `ieInit` (provided by ISETCam). See the
   [ISETCam wiki](https://github.com/iset/isetcam/wiki) for installation.
3. **Docker.** Install Docker Desktop (macOS, Windows) or Docker Engine
   (Linux) and make sure it is running before you render. Only the `docker`
   command-line client is needed; ISET3D drives it for you.

You do **not** need the Stanford VPN, an `orange` account, or the `acorn`
storage mount for local rendering.

## Step 1: Pull The Rendering Image

ISET3D renders with a public PBRT Docker image. For CPU rendering, use:

```bash
docker pull digitalprodev/pbrt-v4-cpu
```

The name has no registry host, so Docker treats it as a Docker Hub image and
downloads it for you. You can pull it ahead of time as shown, or simply let
Docker download it the first time you render.

> **macOS note.** On a Mac you should render with the **CPU** image. Docker
> Desktop on macOS cannot pass a GPU through to a container, so local GPU
> rendering is not available on any Mac. There are also no Apple-Silicon
> (arm64) builds of these images, so on an M-series Mac the CPU image runs
> under emulation: it works correctly, just more slowly. Keep the film
> resolution and rays per pixel small while you are learning.

## Step 2: Configure The MATLAB Preferences

ISET3D stores its Docker configuration in MATLAB preferences under the
`ISETDocker` group. The most reliable way to set up a local machine is to set
these preferences directly, rather than running the interactive
`isetdocker.setUserPrefs` wizard, whose menu is oriented toward the Stanford
hosts.

The canonical local **CPU** configuration is:

```matlab
setpref('ISETDocker','device','cpu');
setpref('ISETDocker','deviceID','');
setpref('ISETDocker','dockerImage','digitalprodev/pbrt-v4-cpu');
setpref('ISETDocker','remoteHost','');
setpref('ISETDocker','remoteUser','');
setpref('ISETDocker','renderContext','default');
setpref('ISETDocker','workDir',fullfile(piRootPath,'local'));
```

The key fields are `remoteHost` empty (so rendering stays local) and
`renderContext` set to `default` (your own machine's Docker daemon).

**Remove the Stanford resource mount.** `PBRTResources` points at a Stanford
storage path (`/acorn/data/iset/PBRTResources`) that does not exist on your
machine. If it is set, clear it so Docker does not try to mount it:

```matlab
if ispref('ISETDocker','PBRTResources')
    rmpref('ISETDocker','PBRTResources');
end
```

Confirm the result and let ISET3D wire up the local Docker path:

```matlab
getpref('ISETDocker')

ieInit;
if ~piDockerExists
    piDockerConfig;
end
```

Do **not** set `PBRTContainer` yourself. It is a transient preference that
ISET3D creates and clears automatically as it starts and stops containers.

### Optional GUI Helper: DockerPref

ISET3D includes an App Designer app, `DockerPref`, that displays the current
`ISETDocker` preferences in an editable panel, validates them, and can apply
named **presets** stored in `docker/config/dockerpresets.json` (or a personal
`local/config/dockerpresets.json`). Launch it from the MATLAB command window:

```matlab
DockerPref
```

`DockerPref` is a convenience, not a requirement. The `setpref` block above is
the canonical local-CPU specification for this guide; `DockerPref` is being
brought into alignment with it. Most of its shipped presets target the Stanford
servers, so if you apply a preset, confirm afterward that `remoteHost` is empty
and that `PBRTResources` is cleared before you render locally.

## Step 3: Get A Scene

Most scenes are **not** stored in the GitHub repository, and they do **not**
come from the Stanford database. They come from the public **Stanford Digital
Repository (SDR)** over ordinary web downloads, and ISET3D fetches them for you
automatically. This needs only an internet connection.

A few scenes ship inside the repository (`data/scenes/`): `cornellbox`, `head`,
and `low-poly-taxi`. For anything else, the recipe helpers download the scene
the first time you ask for it:

```matlab
thisR = piRecipeDefault('scene name','chessset');
```

Behind the scenes this looks for the scene locally, does not find it, and
downloads the scene `.zip` from SDR into `data/scenes/web/` (a git-ignored
cache), then unzips it. Later calls reuse the cached copy.

To see what is available:

```matlab
ieWebGet('list');                       % deposits ISET3D knows about
ieWebGet('browse','iset3d-scenes');     % open the SDR page in a browser
piSDRSceneNames                         % scene names you can download
```

The database-backed resource path (`useDB`, `piRead(idbScene)`, the Mongo
service on `acorn`) described in [remote-rendering.md](remote-rendering.md) is
Stanford-only. Ignore it for local work and use the `ieWebGet` path above.

## Step 4: Verify Your Setup

First run the Docker diagnostic without rendering. It checks that Docker is
reachable, the context is valid, and the preferences are well formed:

```matlab
piDockerDiagnose('render',false);
```

When that passes, run a small render. Keep it low resolution so the first CPU
render finishes quickly:

```matlab
thisR = piRecipeDefault('scene name','chessset');
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',2);
thisR.set('render type',{'radiance','depth'});

scene = piWRS(thisR,'render flag','hdr');
sceneWindow(scene);
```

`piWRS` writes the PBRT scene, renders it in the local container, and returns
the result. If you see a chess-set image in the scene window, your local
rendering setup is working.

If the render fails before PBRT starts, go back to
`piDockerDiagnose('render',false)` and confirm Docker is running and the image
has been pulled.

## Platform Notes

- **macOS:** CPU rendering only (see the note in Step 1). Use the
  `digitalprodev/pbrt-v4-cpu` image and the CPU preferences above.
- **Linux or Windows (WSL2) with an NVIDIA GPU:** You can render on a local GPU
  if you have the NVIDIA drivers and the NVIDIA Container Toolkit installed so
  that Docker can pass the GPU through with `--gpus`. Use the GPU image and
  device preferences instead of the CPU block:

  ```matlab
  setpref('ISETDocker','device','gpu');
  setpref('ISETDocker','deviceID','0');
  setpref('ISETDocker','dockerImage','vistalab/pbrt-v4-gpu');
  setpref('ISETDocker','remoteHost','');
  setpref('ISETDocker','remoteUser','');
  setpref('ISETDocker','renderContext','default');
  setpref('ISETDocker','workDir',fullfile(piRootPath,'local'));
  ```

  A quick command-line preflight for a one-GPU machine:

  ```bash
  docker pull vistalab/pbrt-v4-gpu
  docker run --rm --gpus device=0 vistalab/pbrt-v4-gpu nvidia-smi
  ```

- **`sceneEye` (human-eye optics):** always renders on the CPU, regardless of
  your setup. See [sceneEye-gpu.md](sceneEye-gpu.md) for why.

## Optional: Rendering On Another Machine You Control

If you have a separate GPU box in your own environment (not a Stanford server),
you have two choices:

1. **Run MATLAB on that machine.** Then it is simply *local* rendering on that
   box, and this guide applies directly &mdash; use the local GPU preferences
   above.
2. **Keep MATLAB on your laptop and render remotely on your box.** This uses the
   same remote code path as the Stanford setup, just pointed at your own host:
   create a Docker context over SSH to your machine, then set `remoteHost`,
   `remoteUser`, and `workDir` to your own values. It requires SSH key access,
   Docker on the remote machine, and (for GPU) the NVIDIA Container Toolkit
   there. No Stanford VPN or `orange` account is involved.

   The mechanics are the same ones documented in
   [remote-rendering.md](remote-rendering.md); read that as a reference and
   substitute your own host, user, and (optionally) a shared resource path in
   place of the Stanford values.

## Next Steps

Once a local render works, start the tutorials. See
[iset3d-introduction.md](iset3d-introduction.md) for the recommended first
tutorial path and the core recipe-editing workflow.
