---
name: iset3d-camera-and-optics
description: Use when setting up or changing an ISET3D camera — piCameraCreate, camera subtypes (pinhole, omni, ray transfer, human eye), attaching a lens JSON file, focus distance and accommodation, aperture diameter, film resolution, film size and diagonal, crop window, camera position with from/to/up, camera motion blur, microlens and light-field cameras, or film shape.
---

# Camera And Optics

The camera decides whether a render returns an ISETCam `scene` or an `oi`:

```matlab
thisR.get('optics type')      % 'pinhole' | 'lens' | 'environment'
thisR.get('camera subtype')   % the specific model
```

- **`pinhole`** → a `scene` (radiance). No aperture, so no optical image.
  Use `sceneGet`, `sceneWindow`, `scenePlot`.
- **`lens`** → an `oi` (optical image). Use `oiGet`, `oiWindow`, `oiPlot`.
  Subtypes counted as `lens`: `omni`, `realistic`, `realisticdiffraction`,
  `humaneye`, `raytransfer`.
- **`environment`** → panorama rendering.

`thisR.get('camera subtype')` normalizes two legacy spellings: PBRT
`perspective` is reported as `pinhole`, and `realisticEye` as `humaneye`.

## Creating A Camera

```matlab
piCameraCreate('pinhole')
piCameraCreate('omni','lens file','dgauss.22deg.12.5mm.json')
piCameraCreate('ray transfer','lens file','tmp.json')
piCameraCreate('human eye','lens file','navarro.dat')

thisR.set('camera',piCameraCreate('omni','lens file',lensname));
```

| Type | Use |
| --- | --- |
| `pinhole` (alias `perspective`) | Default. Ideal imaging, infinite depth of field. |
| `omni` | The standard lens model, including an optional microlens array. |
| `ray transfer` | A ray-transfer-function optics model. |
| `human eye` | Physiological optics — navarro, arizona, legrand. See `iset3d-sceneEye`. |

Deprecated subtypes that still appear in older scenes: `light field`
(superseded by `omni` with a microlens), `realisticDiffraction`, and
`realistic` (superseded by `omni` except in some old car scenes).

Lens files live in **ISETCam**, not ISET3D — `piDirGet('lens')` points there.
JSON is the current lens format; `.dat` files persist for the eye models.

```matlab
thisR.get('lens file');
thisR.get('lens dir');
thisR.get('lens basename');
```

## Camera Placement

Placement is the `lookAt` struct: `from` (camera position), `to` (target), and
`up`.

```matlab
thisR.set('from',[0 0 -5]);        % alias: 'camera position'
thisR.set('to',[0 0 0]);
thisR.set('up',[0 1 0]);

thisR.get('lookat');
thisR.get('from to');              % direction vector
thisR.get('from to distance');     % alias: 'object distance'
thisR.get('look at direction');
```

Helpers: `piCameraTranslate`, `piCameraRotate`, `piCameraCalibrate`. Aiming at
a specific object is the common use of `piAssetSearch` — see
`iset3d-assets-and-transforms`.

## Focus

**`focus distance` is the distance in object space that is in focus. It is not
the lens focal length.** The name confuses people; PBRT itself stores it under
different keys per camera model.

```matlab
thisR.get('focus distance');       % meters; aliases: 'focal distance'
thisR.set('focus distance',1.5);
thisR.get('focus distance','mm');  % most distance getters take a unit
```

Behavior by optics type:

- **pinhole** — everything is in focus. The getter prints a message and returns
  an arbitrary stored value.
- **environment** — returns `NaN`.
- **lens** — the real thing. PBRT adjusts the film distance to achieve it.
- **humaneye** — built into the lens model rather than set directly; the value
  comes from the lens file header.

Accommodation is the reciprocal, in diopters:

```matlab
thisR.get('accommodation');        % 1/focusDistance for ordinary lenses
```

For pinhole this warns and returns `Inf`. For `humaneye` it reads the model's
own accommodation — set it with `setNavarroAccommodation` or
`setArizonaAccommodation` (the LeGrand eye cannot be accommodated).

## Film And Sampling

```matlab
thisR.set('film resolution',[320 320]);   % aliases: 'spatial samples', 'spatial resolution'
thisR.set('rays per pixel',128);
thisR.set('n bounces',4);                 % aliases: 'max depth', 'bounces'
thisR.set('film diagonal',5);             % mm
thisR.set('crop window',[0 1 0 1]);

thisR.get('film size');                   % [width height], mm by default
thisR.get('film width','mm');
thisR.get('sample spacing');
thisR.get('fov');                         % shorter dimension
thisR.get('fov other');
thisR.get('aperture diameter','mm');
```

Two things to know:

- **Film width and height are derived**, not stored: `spatial samples` ×
  `sample spacing`. Changing film resolution changes the physical film size
  unless you also adjust the diagonal.
- **For a pinhole camera, `film diagonal` is not used in rendering.** PBRT
  ignores it; ISET3D uses it only to compute sample spacing in physical units.

Keep resolution and rays per pixel small while developing. Raise them once the
scene is correct — especially on macOS, where PBRT runs on the CPU.

## Camera Motion Blur

Motion is expressed as a start and an end transform over the exposure:

```matlab
thisR.set('camera motion translate start',[0 0 0]);
thisR.set('camera motion translate end',[0.02 0 0]);   % 2 cm, meters
thisR.set('camera motion rotate start',piRotationMatrix);
thisR.set('camera motion rotate end',piRotationMatrix('zrot',5));

scene = piWRS(thisR,'render type','radiance','render flag','hdr');
```

Exposure interval:

```matlab
thisR.set('exposure time',t);      % alias: 'camera exposure'
thisR.get('shutter open');
thisR.get('shutter close');
thisR.get('transform times');
```

Reference tutorial:
[`t_cameraMotion.m`](../../../tutorials/camera/t_cameraMotion.m). For *object*
motion instead, see `iset3d-assets-and-transforms` and
[`t_assetsMotion.m`](../../../tutorials/assets/t_assetsMotion.m).

## Chromatic Aberration And Diffraction

```matlab
thisR.get('diffraction');
thisR.get('chromatic aberration');
thisR.get('n cabands');
```

These are lens-camera properties. Enabling them costs render time.

## Microlens And Light Field

```matlab
thisR.get('n microlens');          % alias: 'n pinholes'
thisR.get('n subpixels');
thisR.get('microlens sensor offset');
piCameraInsertMicrolens(...);
piMicrolensInsert(...);
piMicrolensWrite(...);
```

Treat these as advanced follow-ups after the basic lens path:
[`t_cameraLightField.m`](../../../tutorials/camera/t_cameraLightField.m),
[`t_piIntro_microlens.m`](../../../tutorials/introduction/t_piIntro_microlens.m).

## Film Shape

A non-planar film (a curved retina, a bump) is specified by a lookup table:

```matlab
thisR.get('film shape file');
thisR.get('film shape basename');
```

Builders live in [`utilities/filmshape/`](../../../utilities/filmshape/):
`piShapeCreate`, `piShapeLookuptable`, `generateLookupTableSphere`,
`generateLookupTableBump`, `piMapToSphere`, `retinalBump`. This is mostly used
by `sceneEye`, where the retinal geometry getters (`retina distance`,
`retina radius`, `retina semidiam`, `center2chord`, `lens2chord`) also apply.

## Where To Look

- Tutorials: [`tutorials/camera/`](../../../tutorials/camera/) —
  `t_camera.m` renders the chess set through a double Gauss lens and adjusts
  focus. [`t_piIntro_lens.m`](../../../tutorials/introduction/t_piIntro_lens.m)
  is the shortest lens example.
- [`tutorials/lens/`](../../../tutorials/lens/) — `t_lensBasics.m`,
  `t_lensRayTracePSF.m`, `t_lensDiffractionBasics.m`.
- Code: [`utilities/camera/`](../../../utilities/camera/),
  [`utilities/lens/`](../../../utilities/lens/).

## Related

- `iset3d-lens-toolbox` — the imported ISETLENS classes and paraxial optics.
- `iset3d-sceneEye` — human-eye optics.
- `iset3d-recipe-workflow` — scene versus oi, and finding parameter names.
