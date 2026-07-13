# Getting Started With ISET3D Tutorials

ISET3D is a MATLAB toolbox for building and rendering three-dimensional
scenes with PBRT. The rendered output is returned as ISETCam-compatible data,
usually either a scene radiance object (`scene`) or, when an optical system is
part of the camera model, an optical image (`oi`).

The tutorials are meant to be read and run as short teaching scripts. Start
with the introductory files, then move into the topic folders when you want to
edit assets, lights, materials, cameras, or lenses more deeply.

## Before You Start

ISET3D expects ISETCam to be installed and on the MATLAB path. Most rendering
tutorials also expect Docker-based PBRT rendering to be configured, often using
a remote rendering host.

In a fresh MATLAB session, the common setup pattern is:

```matlab
ieInit;
if ~piDockerExists
    piDockerConfig;
end
```

If rendering fails before PBRT starts, check the Docker and remote rendering
configuration first:

```matlab
piDockerDiagnose('render',false);
```

See [remote-rendering.md](remote-rendering.md) for the full remote rendering
workflow and [testing.md](testing.md) for how tutorials are smoke-tested.

## First Tutorial Path

Run these tutorials first. They introduce the recipe object, basic rendering,
and the main controls you will reuse throughout ISET3D.

1. [t_piIntro_chess.m](../tutorials/introduction/t_piIntro_chess.m) - render
   the chess set, set basic render quality, inspect depth, and use `sceneGet`.
2. [t_piIntro_camera.m](../tutorials/introduction/t_piIntro_camera.m) - inspect
   the default perspective camera, field of view, film resolution, and one
   environment light.
3. [t_piIntro_illumination.m](../tutorials/introduction/t_piIntro_illumination.m)
   - replace default lighting with a new light and inspect illuminant spectra.
4. [t_piIntro_material.m](../tutorials/introduction/t_piIntro_material.m) -
   create a material, assign it to an object, render, and check luminance.
5. [t_piIntro_texture.m](../tutorials/introduction/t_piIntro_texture.m) - add a
   material preset with texture and render the result.

These scripts are intentionally small. They are a better first stop than the
longer topic tutorials because they keep render sizes and sample counts modest.

## Core Workflow

Most rendering tutorials follow the same pattern.

Create or load a recipe:

```matlab
thisR = piRecipeCreate('chess set');
% or
thisR = piRecipeDefault('scene name','chessset');
```

Adjust recipe properties:

```matlab
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',2);
```

Edit scene components such as lights, cameras, assets, and materials:

```matlab
thisR.set('light','all','delete');
newLight = piLightCreate('mainLight_L','type','point', ...
    'spd','equalEnergy','cameracoordinate',true);
thisR.set('light',newLight,'add');
```

Render and inspect the output:

```matlab
scene = piWRS(thisR,'render flag','hdr');
sceneWindow(scene);
scenePlot(scene,'depth map');
fprintf('Mean luminance %.3f\n',sceneGet(scene,'mean luminance'));
```

`piWRS` is the high-level helper used in most tutorials. It writes the PBRT
scene, renders it, and shows or returns the result. Lower-level workflows may
call `piWrite` and `piRender` separately when they need finer control.

## Scene Editing Path

After the first path, choose the topic folder that matches what you want to
change.

- [tutorials/assets](../tutorials/assets/) explains the asset tree, object
  search, transforms, copying, deleting, motion, and world transforms. Start
  with [t_assets.m](../tutorials/assets/t_assets.m).
- [tutorials/materials](../tutorials/materials/) covers material inspection,
  edits, presets, and assignment. Start with
  [t_materials.m](../tutorials/materials/t_materials.m).
- [tutorials/lights](../tutorials/lights/) covers point lights, environment
  lights, area lights, spectra, size, spread, arrays, and light geometry. Start
  with [t_piIntro_light.m](../tutorials/lights/t_piIntro_light.m), then move
  to [t_arealight.m](../tutorials/lights/t_arealight.m).
- [tutorials/scene](../tutorials/scene/) covers scene-oriented targets and
  measurements such as Macbeth rendering, depth maps, z maps, and instances.
  Start with [t_piIntro_macbeth.m](../tutorials/scene/t_piIntro_macbeth.m).

## Optics Path

Without a lens model, ISET3D renders scene radiance and returns a `scene`.
When you attach a lens or camera model that forms an optical image, the render
can return an `oi`. Use `sceneGet` and `scenePlot` for `scene` objects; use
`oiGet`, `oiWindow`, and `oiPlot` for `oi` objects.

Good next tutorials are:

- [t_piIntro_lens.m](../tutorials/introduction/t_piIntro_lens.m) - attach a
  JSON lens file to a recipe and render an optical image.
- [t_camera.m](../tutorials/camera/t_camera.m) - render the chess set through a
  double Gauss lens and adjust focus distance.
- [t_lensBasics.m](../tutorials/lens/t_lensBasics.m) - create and inspect a
  lens object without running a full scene render.
- [t_lensRayTracePSF.m](../tutorials/lens/t_lensRayTracePSF.m) and
  [t_lensDiffractionBasics.m](../tutorials/lens/t_lensDiffractionBasics.m) -
  explore lens-derived optical image behavior and diagnostics.

Light-field and microlens tutorials are useful but more advanced. Treat
[t_cameraLightField.m](../tutorials/camera/t_cameraLightField.m) and
[t_piIntro_microlens.m](../tutorials/introduction/t_piIntro_microlens.m) as
optional follow-ups after the basic lens path.

## Remote Rendering

Most ISET3D render tutorials eventually call PBRT through Docker. On systems
configured for remote rendering, MATLAB stores the Docker context, host, image,
work directory, and container state in preferences under `ISETDocker`.

Before running a render-heavy tutorial, a short checklist is:

- ISETCam and ISET3D are both on the MATLAB path.
- Stanford VPN is active if the remote host requires it.
- `piDockerConfig` has been run on this machine.
- `piDockerDiagnose('render',false)` passes before attempting a full render.
- Stale PBRT containers have been diagnosed with `piDockerDiagnose` before
  manually changing Docker state.

For details about ordinary remote rendering, database-backed resources,
texture staging, and common failure modes, use
[remote-rendering.md](remote-rendering.md).

## How To Run One Tutorial

From MATLAB, you can run a tutorial script directly:

```matlab
run(fullfile(piRootPath,'tutorials','introduction','t_piIntro_chess.m'));
```

If you are checking whether a tutorial still runs cleanly in the automated
smoke-test style, use the tutorial runner with a selection:

```matlab
runInfo = iset3dTutorialTest('selection','t_piIntro_chess');
ieTestReport(runInfo,'List','all');
```

The runner starts each selected tutorial with fresh ISET state, which is useful
for catching hidden dependencies on variables left behind by earlier scripts.

## Current Tutorial Coverage Gaps

The tutorial collection is broad, but a new user may still need a little
orientation:

- There is not yet a single "first 30 minutes" tutorial that walks from
  `ieInit` through recipe creation, scene edits, rendering, and display in one
  continuous beginner narrative.
- The difference between a rendered `scene` and a rendered `oi` appears across
  several tutorials, but is not explained centrally in the tutorial tree.
- Remote rendering is documented in detail, but beginners may benefit from a
  short configuration checklist before running render-heavy tutorials.
- Several valuable advanced tutorials are marked `% SkipFile` or are intended
  for interactive exploration, so they should be treated as optional follow-ups
  rather than first-run material.
- The tutorials demonstrate many individual controls, but users may need more
  guidance on when to use `piRecipeCreate`, `piRecipeDefault`, `piWRS`, and
  the lower-level `piWrite`/`piRender` pair.
