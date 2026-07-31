---
name: iset3d-scene-sources
description: Use when finding, downloading, or choosing an ISET3D scene — which scenes ship in the repo versus come from the Stanford Digital Repository, ieWebGet, piSDRSceneNames, piSceneDeposit, the data/scenes/web cache, piDirGet resource directories, or building a synthetic test target such as a Macbeth chart, slanted edge, or checkerboard.
---

# Where ISET3D Scenes Come From

Most ISET3D scenes are **not** stored in the Git repository. They arrive by one
of four routes, and confusing them is a common source of "scene not found"
errors. In decreasing order of how often you should reach for them:

1. **Synthetic builders** — constructed in MATLAB, no download at all.
2. **Stanford Digital Repository (SDR)** — public web download, cached locally.
   This is the main route and needs only an internet connection.
3. **In-repository scenes** — a handful under `data/scenes/`.
4. **Database-backed resources** — Stanford-only shared storage. Ignore for
   local work.

## Route 1: Synthetic Scenes

The fastest and most reproducible option. Nothing is downloaded, so these are
good choices for tests and for tutorials that must run anywhere.

```matlab
thisR = piCreateMacbethChart;
thisR = piCreateSlantedBarScene;
thisR = piCreateSlantedBarTextureScene;
thisR = piCreateCheckerboard;
thisR = piCreateSiemensStar;
thisR = piCreateLettersAtDepth;
thisR = piCreateSimplePointScene;
```

Related helpers in [`utilities/scenes/`](../../../utilities/scenes/):
`piChessInit`, `piAddSphere`, `piDrawCube`, `generateCube`, `piWhiteField`,
`piSceneSubmerge` (participating media), `piSceneDepth`, `piGetCropWindow`.

## Route 2: The Stanford Digital Repository

`piRecipeDefault` and `piRecipeCreate` download scenes automatically the first
time you ask for one. Behind the scenes they look locally, miss, fetch the
scene `.zip` from the SDR into `data/scenes/web/`, and unzip it. Later calls
reuse the cache.

```matlab
thisR = piRecipeDefault('scene name','chessset');   % downloads on first use
```

`data/scenes/web/` is git-ignored. Deleting it costs only re-download time.

### Discovering what is available

```matlab
piSDRSceneNames                       % struct of scene names by subdirectory
ieWebGet('list');                     % SDR deposits ISET knows about
ieWebGet('browse','iset3d-scenes');   % open the deposit in a browser
recipe.list                           % scenes the repo knows how to build
piRecipeCreate('help')                % scenes piRecipeCreate can make renderable
```

`piSDRSceneNames` returns three groups, matching the SDR deposit layout:

| Group | Contents |
| --- | --- |
| `sdrNames.iset3d.names` | ISET3D's own scenes — `chessset`, `macbethchecker`, `simplescene`, `cornell_box`, `slantededge`, `sphere`, `materialball`, `lettersatdepth`, `flatsurface`, `bunny`, `car`, `checkerboard`, `testplane`, `teapot-set`, and others |
| `sdrNames.bitterli.names` | Benedikt Bitterli scenes — `bathroom`, `bedroom`, `classroom`, `living-room*`, `staircase*`, `veach-*`, `glass-of-water` |
| `sdrNames.pbrtv4.names` | PBRT-v4 distribution scenes — `bistro`, `crown`, `killeroos`, `kitchen`, `landscape`, `sanmiguel`, `sportscar`, `zero-day`, `disney-cloud` |

The deposit link is <https://purl.stanford.edu/cb706yg0989>.

`piSceneDeposit(sceneName)` maps a scene name to its SDR subdirectory, which is
what `ieWebGet` needs:

```matlab
subDir = piSceneDeposit('macbethchecker');            % -> 'iset3d'
ieWebGet('deposit name',subDir,'deposit file','macbethchecker');
```

`piSDRSceneNames`, `piSceneDeposit`, and the `piRecipeDefault` case statements
are meant to stay in sync. **If you add a scene, update all three.**

The bitterli and pbrtv4 scenes are large and slow. Prefer ISET3D's own scenes
for tutorials and tests.

## Route 3: Scenes In The Repository

Only these ship in Git, under `data/scenes/`:

- `cornellbox`
- `head`
- `low-poly-taxi`
- `simplescene`

Everything else in `data/` is supporting resources, not scenes: `assets`,
`skymaps`, `materials` (including the texture library), `lights`, `spds`,
`bsdf`, `ior`, `basisFunctions`, `raytransfer`, `sdrscenes`.

## Route 4: Database-Backed Scenes

Recipes read with `piRead(idbScene)` point at the shared
`/acorn/data/iset/PBRTResources` tree and set `thisR.useDB = true`. This is
Stanford-only infrastructure and irrelevant to local rendering — use Route 2
instead. See the `iset3d-remote-resources-database` skill if you actually need
it.

## Finding Resource Directories

Never hard-code a resource path. `piDirGet` is the single lookup:

```matlab
piDirGet('help')        % print the valid resource types
piDirGet('scenes')
piDirGet('assets')
piDirGet('textures')    % the local image-texture library
piDirGet('skymaps')
piDirGet('lens')        % note: lives in ISETCam, not ISET3D
piDirGet('local')       % git-ignored scratch and render output
```

Valid types: `data`, `assets`/`asset`, `lights`, `imageTextures`/`textures`/
`texture`, `materials`/`material`, `lens`/`lenses`, `scenes`/`scene`, `local`,
`server local`, `character-assets`, `character-recipes`, `skymaps`,
`resources`. Anything else errors with the list printed.

For a specific file, `piResourceFind(type,name)` searches the ISET3D library
first and then the user's MATLAB path, so a user copy can override the shipped
one. It currently handles `'texture'`. `findFileRecursive` is the blunt
fallback.

## Choosing A Scene

| Need | Use |
| --- | --- |
| A fast smoke test that must run anywhere | a synthetic builder (Route 1) |
| A first render / teaching example | `piRecipeCreate('chess set')` |
| Color or reflectance work | `piCreateMacbethChart` or `piRecipeCreate('macbeth checker')` |
| Resolution, MTF, focus | `piCreateSlantedBarScene`, `piCreateSiemensStar` |
| Global illumination, interreflection | `piRecipeCreate('cornell-box')` |
| Depth and defocus | `piCreateLettersAtDepth`, `piRecipeCreate('chess set')` |
| A visually rich scene for a demo | an SDR bitterli or pbrtv4 scene — expect a slow render |

Prefer `piRecipeCreate` over `piRecipeDefault`: many raw scenes have no lights
and render black, or use an awkward default viewpoint. `piRecipeCreate` fixes
both. `piRecipeDefault` warns (`piRecipeDefault:NoLights`) when it parses a
scene with no lights; you can pass `'add default light',true`.

## Related

- `iset3d-recipe-workflow` — what to do with the recipe once you have it.
- `iset3d-materials-and-textures` — the texture library and staging.
- `iset3d-remote-resources-database` — the shared `/acorn` resource tree.

Long-form: [docs/setting-up-iset3d.md](../../../docs/setting-up-iset3d.md) §3.
