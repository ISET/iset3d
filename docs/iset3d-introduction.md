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
tutorials also expect Docker-based PBRT rendering to be configured. Start with
local rendering on your own computer. Remote rendering is useful later for
larger scenes, GPU rendering, or shared database-backed resources, but it is
not needed for the first tutorials.

In a fresh MATLAB session, the common setup pattern is:

```matlab
ieInit;
if ~piDockerExists
    piDockerConfig;
end
```

If you have not configured local rendering yet, follow
[setting-up-iset3d.md](setting-up-iset3d.md) first. It covers installing
Docker, pulling the CPU image, setting the `ISETDocker` preferences, and
downloading scenes &mdash; everything needed to render on your own computer
without Stanford servers. This tutorial guide assumes that setup is done.

You can check the current rendering preferences with:

```matlab
getpref('ISETDocker')
```

For a local setup, `remoteHost` should be empty. The render output and staged
PBRT files will be written under the repository's `local/` folder.

If rendering fails before PBRT starts, check Docker first:

```matlab
piDockerDiagnose('render',false);
```

See [remote-rendering.md](remote-rendering.md) only when you are ready to use
a remote rendering host. See [testing.md](testing.md) for how tutorials are
smoke-tested.

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

## Local Rendering First

The first rendering tutorial should run on your own computer with local Docker
preferences. This is the shortest useful local-rendering loop:

```matlab
ieInit;
if ~piDockerExists
    piDockerConfig;
end

thisR = piRecipeDefault('scene name','chessset');
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',2);
thisR.set('render type',{'radiance','depth'});

scene = piWRS(thisR,'render flag','hdr');
sceneWindow(scene);
scenePlot(scene,'depth map');
```

This is the pattern in
[t_piIntro_chess.m](../tutorials/introduction/t_piIntro_chess.m). Keep the
film resolution and rays per pixel small while learning. Increase them only
after the scene edits are correct.

## Common Next Edits

Once you can render the chess set locally, the next useful tasks are small
recipe edits. The snippets below show the important API calls and point to the
tutorials that expand each topic.

### Add Camera Motion

Camera motion is specified as start and end transforms over the exposure.
[t_cameraMotion.m](../tutorials/camera/t_cameraMotion.m) demonstrates
translation and rotation blur. A calibrated translation uses metric units:

```matlab
startPos = [0 0 0];
endPos = [0.02 0 0];      % 2 cm lateral motion

thisR.set('camera motion translate start',startPos);
thisR.set('camera motion translate end',endPos);
thisR.set('camera motion rotate start',piRotationMatrix);
thisR.set('camera motion rotate end',piRotationMatrix);

scene = piWRS(thisR,'render type','radiance','render flag','hdr');
```

To add a small rotation over the same exposure, replace the final rotation:

```matlab
thisR.set('camera motion rotate end',piRotationMatrix('zrot',5));
```

### Change The Skymap

A skymap is an environment light. The introductory chess tutorial shows the
basic pattern:

```matlab
[~, skyMap] = thisR.set('skymap','room.exr');
thisR.set('light',skyMap.name,'rotate',[30 0 0]);
```

Use this after deleting or inspecting other lights when you want the
environment to be the main illumination. See
[t_piIntro_chess.m](../tutorials/introduction/t_piIntro_chess.m) for a simple
rendered example and [t_skymapDaylight.m](../tutorials/skymap/t_skymapDaylight.m)
for spectral daylight calculations that can guide sky color choices.

### Change Light Color

Light color is controlled by the light spectrum. Use a named illuminant, a
blackbody temperature, or a spectrum file, depending on the experiment.
[t_piLightSpectrum.m](../tutorials/lights/t_piLightSpectrum.m) shows this
directly:

```matlab
thisR.set('light','all','delete');
spotLight = piLightCreate('spot1', ...
    'type','spot', ...
    'spd','equalEnergy', ...
    'specscale float',1, ...
    'coneangle',20, ...
    'cameracoordinate',true);
thisR.set('light',spotLight,'add');

thisR.set('lights','spot1_L','spd','D50');
thisR.set('lights','spot1_L','spd',3000);   % 3000 K blackbody
```

For a first illumination tutorial, see
[t_piIntro_illumination.m](../tutorials/introduction/t_piIntro_illumination.m).

### Change Material Properties

Materials are stored in the recipe and assigned to assets. The usual workflow
is to find an asset, inspect its material, edit or create a material, and then
assign it:

```matlab
assetID = piAssetSearch(thisR,'object name','figure_3m');
matName = thisR.get('asset',assetID,'material name');

thisR.get('material',matName,'reflectance');
thisR.set('material',matName,'reflectance',[0 0.5 0]);

glassMaterial = piMaterialCreate('blueGuyGlass','type','dielectric');
thisR.set('material','add',glassMaterial);
thisR.set('asset',assetID,'material name',glassMaterial.name);
```

Start with [t_materials.m](../tutorials/materials/t_materials.m) for
inspection, editing, and reassignment. Use
[t_piIntro_material.m](../tutorials/introduction/t_piIntro_material.m) for the
shortest example of creating a diffuse material from a spectral reflectance.

## Related Examples

Tutorials are the best first source for these controls. Examples are useful
once you want a workflow to adapt:

- Camera motion: the main reference is still
  [t_cameraMotion.m](../tutorials/camera/t_cameraMotion.m). There is not
  currently a stable `examples/` script dedicated to calibrated camera motion.
  For object motion rather than camera motion, see
  [t_assetsMotion.m](../tutorials/assets/t_assetsMotion.m).
- Skymaps: [s_piMaterials.m](../examples/materials/s_piMaterials.m) uses a
  room skymap while comparing material changes, and
  [s_lightHeadlamp.m](../examples/arealights/s_lightHeadlamp.m) uses a night
  skymap in an applied lighting setup.
- Light color: [s_arealight.m](../examples/arealights/s_arealight.m) assigns
  different RGB spectra to area lights, and
  [s_slantedBarMTF.m](../examples/metrics/s_slantedBarMTF.m) illuminates a
  target with a blue spot light.
- Materials: [s_piMaterials.m](../examples/materials/s_piMaterials.m) changes a
  sphere from diffuse to mirror and coated green materials. It is the most
  directly related applied example for material property edits.

Some under-development examples also touch these topics, especially database
skymaps and custom scene construction. Treat files under `examples/*/underDevelopment/`
as exploratory rather than as first-copy templates.

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

## Optional Remote Rendering

Most introductory work should use local Docker rendering. Move to remote
rendering when a scene is too slow locally, when you need a remote GPU, or when
you are using shared remote resources. On systems configured for remote
rendering, MATLAB stores the Docker context, host, image, work directory, and
container state in preferences under `ISETDocker`.

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
t_piIntro_chess
```

If you are checking whether a tutorial still runs cleanly in the automated
smoke-test style, use the tutorial runner with a selection:

```matlab
runInfo = iset3dTutorialTest('selection','t_piIntro_chess');
ieTestReport(runInfo,'List','all');
```

The runner starts each selected tutorial with fresh ISET state, which is useful
for catching hidden dependencies on variables left behind by earlier scripts.

## Current Tutorial Notes

The tutorial collection is broad. This guide is meant to provide the first
orientation layer; a few points still matter as you move deeper:

- The difference between a rendered `scene` and a rendered `oi` appears across
  several tutorials, but is not explained centrally in the tutorial tree.
- Several valuable advanced tutorials are marked `% SkipFile` or are intended
  for interactive exploration, so they should be treated as optional follow-ups
  rather than first-run material.
- When you need applied workflows rather than short API orientation, use
  `examples/` instead of `tutorials/`.

## Local Docker Setup

Local rendering setup &mdash; installing Docker, pulling the CPU or GPU image,
setting the `ISETDocker` preferences, clearing the Stanford resource mount, and
downloading scenes with `ieWebGet` &mdash; now lives in one place:
[setting-up-iset3d.md](setting-up-iset3d.md). Follow that guide before running
the tutorials above.
