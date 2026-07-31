---
name: iset3d-sceneEye
description: Use when rendering retinal images with the ISET3D human eye models — the sceneEye class, the navarro, arizona, and legrand schematic eyes, accommodation, retinal geometry (retina distance, radius, semidiam), lens density, the pinhole debug mode, or why sceneEye renders on the CPU instead of the GPU.
---

# sceneEye: Human Physiological Optics

`sceneEye` wraps an ISET3D recipe configured with PBRT's `humaneye` camera so a
render returns the **retinal spectral irradiance** — an ISETCam `oi`. It is the
analogue of ISETBio's `scene` structure, implemented as a MATLAB class with its
own methods.

The recipe is in `thisSE.recipe`. Ideally you rarely reach into it, but every
recipe get/set described in `iset3d-recipe-workflow` is available there.

## Creating One

```matlab
thisSE = sceneEye;                                  % empty recipe, navarro
thisSE = sceneEye('chessset');                      % a named scene
thisSE = sceneEye('bathroom','eye model','legrand');
```

`'eye model'` accepts `navarro` (default), `arizona`, or `legrand`. The legacy
alias `'human eye'` still works.

The constructor builds the scene with `piRecipeCreate`, creates a `humaneye`
camera, and immediately writes the model's lens file (`navarroWrite`,
`arizonaWrite`, or `legrandWrite`) at 0 diopters accommodation.

## The Three Eye Models

| Model | Notes |
| --- | --- |
| `navarro` | Default. Accommodates 0–10 diopters. **The Navarro accommodation values do not match the Zemax values**, so ISET3D converts the requested value internally. |
| `arizona` | Accommodating clinical model. |
| `legrand` | **Cannot be accommodated** — a fixed schematic eye. |

Model code is in [`human/models/`](../../../human/models/): a `*LensCreate`, a
`*RefractiveIndices`, and a `*Write` per model. Accommodation setters are in
[`human/accommodation/`](../../../human/accommodation/).

## Accommodation

Changing accommodation for a human eye **rewrites the lens file** — it is not a
single scalar in the camera struct. That is why it goes through dedicated
functions rather than a plain set:

```matlab
thisSE.set('accommodation',4);      % 4 diopters -> focus at 0.25 m
thisSE.get('accommodation');
```

0 diopters means focus at infinity; 10 diopters means 0.1 m. Under the hood
this calls `setNavarroAccommodation` or `setArizonaAccommodation`, which write
a new lens file into `thisR.get('lens output dir')` and point the recipe at it.
Those two functions are marked deprecated as direct entry points — prefer the
`set('accommodation',...)` form.

`convertToNavarroAccomm` performs the Zemax conversion;
`getNavarroRefractiveIndices` returns the wavelength-dependent indices.

For a general lens (not a human eye), accommodation is simply
`1/focusDistance` — see `iset3d-camera-and-optics`.

## Retinal Geometry

PBRT models the retina as a spherical surface, so the "film" is a chord on the
back of a sphere. Field of view, retina distance, and resolution are coupled:

```matlab
thisSE.get('retina distance');      % lens to retina
thisSE.get('retina radius');        % alias: 'eye radius'
thisSE.get('retina semidiam');
thisSE.get('center2chord');
thisSE.get('lens2chord');           % alias: 'distance2chord'

thisSE.set('fov',30);
thisSE.get('width');                % mm of imaged retina — dependent
thisSE.get('height');
thisSE.get('sample size');
thisSE.get('angular support');      % degrees per pixel
```

`width`, `height`, `sampleSize`, and `angularSupport` are **dependent
properties** derived from `fov`, `retinaDistance`, and the film resolution.
`sampleSize` assumes square samples and loses accuracy at wide fields;
`angularSupport` stays accurate at wide angles but not when a crop window is
in use.

Indices of refraction for the model's media are `ior1` through `ior4`.

## Other Properties

```matlab
thisSE.get('model name');
thisSE.set('lens density',1);       % lens pigment density, as in ISETBio's Lens
thisSE.set('use pinhole',true);     % debug mode
thisSE.get('use optics');
```

**Pinhole debug mode.** `usePinhole = true` swaps in a pinhole camera with the
same field of view. It renders much faster and returns a **`scene`** rather
than an `oi`. Use it to check geometry, framing, and lighting before paying for
a full physiological-optics render.

## Rendering

```matlab
[oi, terminalOutput] = thisSE.render;
oi = thisSE.piWRS;                  % write, render, show
thisSE.summary;
```

`render` writes the PBRT file, renders in the container, and loads the result.
Useful key/value pairs: `'render type'`, `'scale illuminance'` (default true),
`'docker'`, and `'write'` (set false to skip `piWrite` when debugging).

It returns an **`oi`** for true human-eye optics and a **`scene`** in pinhole
debug mode.

## sceneEye Always Renders On The CPU

This is deliberate and worth knowing before you go looking for a GPU bug.

PBRT's `HumanEyeCamera` is CPU-only in practice, so
[`human/@sceneEye/render.m`](../../../human/@sceneEye/render.m) and
[`human/@sceneEye/piWRS.m`](../../../human/@sceneEye/piWRS.m) force a CPU
configuration for non-pinhole renders — `device = 'cpu'`, `deviceID = ''`, and
`dockerImage = 'digitalprodev/pbrt-v4-cpu'` when the requested image is empty
or GPU-specific. Pinhole preview renders keep whatever renderer is configured.

The reason: PBRT's GPU wavefront path generates camera rays inside a
`PBRT_CPU_GPU_LAMBDA`, so everything reachable from the selected camera's
`GenerateRay()` must be valid GPU device code. `HumanEyeCamera` is not.

Practical consequence: **keep film resolution and rays per pixel modest.** A
sceneEye render will not get faster by pointing at a GPU host.

Background and the path toward GPU support:
[docs/sceneEye-gpu.md](../../../docs/sceneEye-gpu.md). The PBRT source is at
<https://github.com/ISET/pbrt-v4> (`src/pbrt/cameras.{h,cpp}`).

## Where To Look

- Class: [`human/@sceneEye/`](../../../human/@sceneEye/) — `sceneEye.m`,
  `eyeGet.m`, `eyeSet.m`, `render.m`, `piWRS.m`, `write.m`, `setOI.m`,
  `summary.m`.
- Tests: [`human/_tests_/`](../../../human/_tests_/) — `test_sceneEye.m`,
  `test_sceneEyePiWRS.m`, runner `humanUnitTest`.
- Tutorials: [`tutorials/sceneEye/`](../../../tutorials/sceneEye/).
- `human/deprecated/` holds cloud and RTB-era code. Do not build on it.

Gullstrand eye workflows from ISETLENS were deliberately deferred and are not
yet imported — see [`lens/ISETLENS-IMPORT.md`](../../../lens/ISETLENS-IMPORT.md).

## Related

- `iset3d-camera-and-optics` — the general camera model and film shape.
- `iset3d-lens-toolbox` — lens ray tracing and paraxial optics.
- `iset3d-docker-rendering` — why the CPU image matters for setup.
