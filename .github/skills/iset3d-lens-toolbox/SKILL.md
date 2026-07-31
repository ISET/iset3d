---
name: iset3d-lens-toolbox
description: Use when working with the lens ray-tracing code imported from ISETLENS — lensC, rayC, surfaceC, filmC, psfCameraC, lensFocus, lensCombine, paraxial matrix optics, black box model (bbm) analysis, point spread and MTF calculation with piCalculateSlantedEdgeMTF, or the lens/ subtree layout and its tests.
---

# The Lens Toolbox

`lens/` is a curated runtime import of the former sibling `isetlens`
repository. It provides sequential ray tracing through multi-element lenses and
paraxial (matrix) optics, independent of PBRT — you can analyze a lens without
running a scene render.

Provenance and scope are recorded in
[`lens/ISETLENS-IMPORT.md`](../../../lens/ISETLENS-IMPORT.md). Keep it current
if you import more.

There is **no separate ISETLENS unit-test runner** in this merged layout. The
imported tests live in `lens/**/_tests_` and are discovered by `iset3dUnitTest`
as part of the ordinary core suite.

## The Classes

| Class | Role |
| --- | --- |
| `@lensC` | A multi-element lens: a sequence of spherical surfaces and circular apertures. |
| `@surfaceC` | One spherical surface or aperture — curvature, position, index of refraction. |
| `@rayC` | A bundle of rays with origin, direction, wavelength, and validity. |
| `@filmC` | The image plane the rays land on. |
| `@psfCameraC` | Lens + film + point source; computes point spread functions. |

### Geometry conventions (get these right or nothing makes sense)

- **Distance units are millimeters** unless specified otherwise.
- Rays travel **left to right**: scene → lens surfaces → film.
- Zero is the **right-most spherical surface**. Surface positions are negative;
  the film is at a **positive** position.

```text
Scene ->  | Lens Surfaces ->|   Film
               -            0     +
```

- Apertures are circular and centered at (0,0), so one parameter — diameter in
  mm — describes them.
- A surface's index of refraction `n` is a function of wavelength.

```matlab
lens = lensC('filename','dgauss.22deg.12.5mm.json');
lens = lensC('filename',f,'wave',400:10:700,'aperture middle d',5);
lens.draw;
```

Other `lensC` options: `'name'`, `'type'`, `'units'` (`um`/`mm`/`m`),
`'surface array'`, `'microlens'`, `'aperture sample'`,
`'diffraction enabled'` (runs HURB), `'figure handle'`, `'blackbox model'`.

## Focus

```matlab
[filmDistance, lens] = lensFocus('2ElLens.json',objDistance);   % mm in, mm out
```

`lensFocus` runs the autofocus method to find the film distance that best
focuses a point at `objDistance`. As the object distance grows the film
distance approaches the focal length. A negative return means **the lens cannot
focus an object at that distance** — worth checking before setting
`thisR.set('focus distance',...)` on a recipe using the same lens.

Other utilities in [`lens/utility/lens/`](../../../lens/utility/lens/):
`lensList`, `lensCombine`, `lensMatrix`, `lensPinhole`, `lensPolyFit`,
`lensRayPairs`, `lensRaysOcclusion`.

General ray utilities in [`lens/utility/`](../../../lens/utility/):
`rayDirection`, `rayIntersection`, `raysVisualize`, `pointVisualize`,
`psCreate`, `psf2lsf`, `ilInitPLF`.

## Paraxial (Matrix) Optics

[`lens/paraxial/`](../../../lens/paraxial/) implements first-order optics via
system matrices — fast, analytic, and the right tool for cardinal points,
pupils, and Petzval sums.

Typical flow:

```matlab
surf   = paraxCreateSurface(...);
optSyst= paraxCreateOptSyst(...);
imagSyst = paraxCreateImagSyst(...);
paraxGet(imagSyst,'...');
```

Key functions: `paraxCreateSurface`, `paraxCreateOptSyst`,
`paraxCreateImagSyst`, `paraxCreateObject`, `paraxCreateFilm`,
`paraxComputeSurfaceMatrix`, `paraxComputeTranslationMatrix`,
`paraxComputeOptSystMatrix`, `paraxComputeOverallMatrix`,
`paraxMatrix2CardinalPoints`, `paraxFindPupils`, `paraxFindPupil4Object`,
`paraxComputePetzvalSum`, `paraxEffectiveNumericalAperture`,
`paraxFindFoV4ImagSyst`, `paraxGet`, `paraxGetOptSyst`, `paraxGetImagSyst`.

`parax2wvfZernike` bridges to wavefront/Zernike representations.

Tests: `lens/paraxial/_tests_/test_paraxialBasics.m`, runner `paraxialUnitTest`.

## Black Box Model

[`lens/utility/bbm/`](../../../lens/utility/bbm/) reduces a full lens to an
equivalent paraxial description that can then be used in place of ray tracing:
`paraxAnalyze`, `paraxOpt2Imag`, `paraxCreateScene3DSystem`,
`coordCart2Polar3D`, `coordPolar2Cart3D`.

Tests: `lens/utility/bbm/_tests_/test_bbmCoordinates.m`, runner
`bbmUtilityUnitTest`.

## MTF

Use **`piCalculateSlantedEdgeMTF`**. It renders the ISET3D slanted-edge target
through a PBRT camera and estimates the MTF with ISETCam's ISO12233
implementation:

```matlab
mtfData = piCalculateSlantedEdgeMTF('camera',camera,'filmwidth',filmWidthMM);
mtfData = piCalculateSlantedEdgeMTF('oi',oi);          % analysis only, no render
[mtfData,oiList,recipeList] = piCalculateSlantedEdgeMTF(...);
```

Key/value pairs: `'distances'` (chart distances in mm), `'resolution'`
(default 1024), `'rays'` (default 64), `'roifraction'` (default 0.65),
`'plot'`, `'quiet'`.

Passing an existing `oi` skips rendering entirely — the cheap path when you
already have the optical image.

**`piCalculateMTF` is deprecated.** It used the `stepfunction` scene and a
single high-resolution line, differentiating the ESF to an LSF and Fourier
transforming to an MTF. Do not build on it; see
[`t_lensMTF.m`](../../../tutorials/lens/t_lensMTF.m) for the current approach.

Other analysis helpers in [`utilities/lens/`](../../../utilities/lens/):
`piRelativeIlluminance`, `piMicrolensInsert`, `piMicrolensWrite`.

## Test Runners

Each class folder has a colocated suite:

```matlab
lensUnitTest        % lens/tests/lensC/_tests_
rayUnitTest
surfaceUnitTest
filmUnitTest
psfCameraUnitTest
paraxialUnitTest
bbmUtilityUnitTest
lensUtilityUnitTest
```

Plus `utilities/_tests_/test_lensMTF.m` and
`utilities/_tests_/test_isetlensIntegration.m`.

## Where To Look

- Tutorials: [`tutorials/lens/`](../../../tutorials/lens/) — `t_lensBasics.m`
  (create and inspect a lens with no scene render), `t_lensRayTracePSF.m`,
  `t_lensDiffractionBasics.m`, `t_lensMTF.m`.
- Examples: [`examples/lens/`](../../../examples/lens/),
  [`examples/psf/`](../../../examples/psf/),
  [`examples/blackboxLens/`](../../../examples/blackboxLens/).

Gullstrand and other human-eye materials from ISETLENS were **deliberately not
imported**; they belong with the sceneEye eye-model work. See the
`iset3d-sceneEye` skill.

## Related

- `iset3d-camera-and-optics` — attaching a lens file to a recipe and rendering
  through it.
- `iset3d-sceneEye` — physiological optics.
