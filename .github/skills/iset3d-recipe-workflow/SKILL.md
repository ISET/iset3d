---
name: iset3d-recipe-workflow
description: Use when creating, loading, inspecting, or editing an ISET3D recipe, when working with piWRS/piWrite/piRender, when looking up a thisR.get or thisR.set parameter name, when setting render quality (film resolution, rays per pixel, bounces, render type), or when deciding whether a render returns an ISETCam scene or an oi.
---

# ISET3D Recipe Workflow

The `recipe` object (conventionally `thisR`) is the center of ISET3D. It holds
everything PBRT needs: camera, film, sampler, integrator, lookAt, lights,
materials, textures, media, and an asset tree. `piWrite` converts it to PBRT
text files, PBRT renders them inside Docker, and `piRender` reads the result
back as an ISETCam object.

MATLAB never renders anything. It writes files, invokes Docker, and reads EXR
output back. See the `iset3d-docker-rendering` skill for the Docker half.

## The Core Loop

```matlab
ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeCreate('chess set');      % or piRecipeDefault(...)

thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',2);
thisR.set('render type',{'radiance','depth'});

scene = piWRS(thisR,'render flag','hdr');
sceneWindow(scene);
```

Keep film resolution and rays per pixel small while developing. Raise them only
after the scene edits are correct. On macOS the PBRT container is CPU-only and
runs under emulation on Apple Silicon, so a careless resolution can turn a
two-second check into a several-minute one.

## Creating A Recipe

Three entry points, in decreasing order of "just works":

| Call | Use when |
| --- | --- |
| `piRecipeCreate(name)` | You want something renderable **immediately**. It calls `piRecipeDefault` and then adds the lights and camera position the raw scene is missing. |
| `piRecipeDefault('scene name',name)` | You want the scene exactly as parsed from its PBRT files. Some of these scenes have no lights and will render black, or will render from an awkward viewpoint. |
| `piRecipeLoad` / `piRead` | You have a stored recipe `.mat`, or a PBRT file you want to parse directly. |

Discover valid names rather than guessing:

```matlab
validNames = piRecipeCreate('help');   % names piRecipeCreate can fix up
recipe.list                            % scenes known to the repo
thisR.list                             % same list, from an existing recipe
piSDRSceneNames                        % scenes downloadable from the SDR
```

`piRecipeCreate` currently understands `macbethchart`, `chessset`, `head`,
`cornell-box`, `cornellboxreference`, `simplescene`, `arealight`, `bunny`,
`car`, `checkerboard`, `flatsurface`, `lettersatdepth`, `materialball`,
`materialball_cloth`, `sphere`, `slantededge`, `testplane`, and `teapotset`.
Names are matched after `ieParamFormat`, so spacing and case are forgiving:
`'chess set'` and `'chessSet'` both work.

`piRecipeDefault` warns when it parses a scene that has no lights. Either pass
`'add default light',true` or add a light yourself — see the
`iset3d-lights-and-skymaps` skill.

For where scene files come from and how they are downloaded, see the
`iset3d-scene-sources` skill.

## Finding get/set Parameter Names

`thisR.get` and `thisR.set` dispatch to
[`recipeGet.m`](../../../@recipe/recipeGet.m) and
[`recipeSet.m`](../../../@recipe/recipeSet.m), each roughly 2000 lines of a
single `switch` statement. **Do not guess a parameter name — grep the case
list.** This is the fastest reliable lookup in the repository:

```bash
rg "^    case" @recipe/recipeGet.m          # every gettable parameter
rg -n "case.*focal" @recipe/recipeSet.m     # find the spelling you want
```

Parameter names are normalized by `ieParamFormat` before the switch, so
`'film resolution'`, `'filmresolution'`, and `'Film Resolution'` are the same
key. Most cases list several aliases, e.g.
`case {'spatialsamples','filmresolution','spatialresolution'}`.

Commonly used parameters:

```matlab
% Render quality
thisR.set('film resolution',[320 320]);
thisR.set('rays per pixel',128);
thisR.set('n bounces',4);              % aliases: 'maxdepth','bounces'
thisR.set('render type',{'radiance','depth'});

% Camera placement
thisR.set('from',[0 0 -5]);            % alias: 'camera position'
thisR.set('to',[0 0 0]);
thisR.set('up',[0 1 0]);
thisR.get('from to distance');         % alias: 'object distance'

% Field of view and film
thisR.get('fov');
thisR.set('film diagonal',5);          % mm

% Paths
thisR.get('input file');
thisR.get('output dir');               % where piWrite stages the scene
thisR.get('rendered file');
```

`thisR.summarize` and `thisR.show('assets')` are good orientation calls on an
unfamiliar recipe.

## Write, Render, Show

`piWRS` is the high-level helper used by nearly every tutorial:

```matlab
[obj, results, thisD] = piWRS(thisR,'render flag','hdr');
```

It calls `piWrite`, then `piRender`, then opens the appropriate window. Useful
key/value options:

- `'render type'` — cell array; applied locally, **the recipe is not modified**.
- `'render flag'` — `'hdr'`, `'rgb'`, `'gray'`, `'clip'` (display only).
- `'show'` — set `false` to return the object without opening a window.
- `'speed'` — integer `N` divides resolution, bounces, and rays for a fast
  geometry check. Default `1` leaves the recipe alone.
- `'name'` — sets the scene/oi name.
- `'docker'` — pass an `isetdocker` object to override the preference-derived one.
- `'denoise'` — run `piAIdenoise` before returning.

Drop to the two-step form when you need to inspect the staged files between
writing and rendering — this is the standard move when debugging a missing
resource:

```matlab
workingDir = piWrite(thisR);
[~,~,textureList,missingTextures] = piRenderValidate(thisR);
[obj, results] = piRender(thisR);
```

The `results` string is PBRT's terminal output. **Read it when a render looks
wrong.** It carries PBRT warnings and errors, and for lens cameras it reports
the lens-to-film distance and the in-focus distance actually used.

Valid render types: `'radiance'`, `'radiancebasis'`, `'depth'`, `'material'`,
`'instance'`, `'illuminance'`.

## Scene Versus OI

This trips people up and is not explained centrally in the tutorial tree.

`piRender` returns an ISETCam **`scene`** (radiance) or an **`oi`** (optical
image) depending on the camera's optics type:

```matlab
thisR.get('optics type')     % 'pinhole' | 'lens' | 'environment'
thisR.get('camera subtype')  % pinhole, omni, realistic, humaneye, raytransfer, ...
```

- **`pinhole`** (PBRT `perspective`/`pinhole`) → a `scene`. There is no
  aperture, so no optical image is formed. Use `sceneGet`, `sceneWindow`,
  `scenePlot`.
- **`lens`** — `omni`, `realistic`, `realisticdiffraction`, `humaneye`,
  `raytransfer` → an `oi`. Use `oiGet`, `oiWindow`, `oiPlot`.

`thisR.get('camera subtype')` normalizes two legacy spellings: `perspective`
is reported as `pinhole`, and `realisticEye` as `humaneye`.

Calling `sceneGet` on an `oi` fails confusingly, so branch on optics type when
writing a script that must handle both. See the `iset3d-camera-and-optics`
skill for attaching a lens.

## Output Locations

`piWrite` writes a self-contained PBRT scene under:

```text
<piRootPath>/local/<scene-name>/
```

containing the main `.pbrt` file, `<scene>_materials.pbrt`,
`<scene>_geometry.pbrt`, and the `geometry/`, `textures/`, `skymaps/`, `spds/`,
and `lens/` subfolders. Everything a relative PBRT path references must exist
in that folder. For local rendering the container reads it in place; for remote
rendering the folder is rsync'd first. That distinction is the source of most
"file not found" render failures — see `iset3d-remote-resources-database`.

`local/` is git-ignored scratch space. Never treat anything there as a source
of truth.

## Copying And Merging Recipes

```matlab
thisR2 = piRecipeCopy(thisR);        % deep copy; recipe is a handle object
thisR  = piRecipeMerge(thisR,otherR);% bring assets/materials from another recipe
thisR.save('myRecipeName');          % write a recipe .mat
```

`recipe` derives from `matlab.mixin.Copyable`, so plain assignment
(`thisR2 = thisR`) aliases the same object. Use `piRecipeCopy` whenever a script
needs to vary one parameter while keeping the original intact.

## Related Skills

- `iset3d-docker-rendering` — getting a render to run at all, and diagnosing it.
- `iset3d-scene-sources` — where scene files come from.
- `iset3d-lights-and-skymaps`, `iset3d-materials-and-textures`,
  `iset3d-assets-and-transforms` — editing recipe contents.
- `iset3d-camera-and-optics` — lenses, film, and the `oi` path.

Long-form background: [docs/iset3d-introduction.md](../../../docs/iset3d-introduction.md).
