---
name: iset3d-lights-and-skymaps
description: Use when adding, deleting, inspecting, or editing lights in an ISET3D recipe — piLightCreate, piLightSet, piLightGet, thisR.set('light',...) add/delete/rotate/translate, light types (point, spot, distant, area, infinite), light spectra (named illuminant, blackbody temperature, RGB), specscale, cameracoordinate, area-light geometry, or setting and rotating an environment skymap.
---

# Lights And Skymaps

A scene with no lights renders black. `piRecipeDefault` warns
(`piRecipeDefault:NoLights`) when it parses one; `piRecipeCreate` adds a
reasonable light for you.

Lights in ISET3D are **nodes in the asset tree**, not a separate list. Adding a
light creates a branch node (named `<light>_B`) under the root plus a light
node (named `<light>_L`) beneath it. That is why lights are moved with the same
rotate/translate machinery as objects, and why `thisR.set('light',name,'delete')`
is implemented as an asset delete.

Light names are normalized by `piLightNameFormat` to end in `_L`. Duplicate
names are automatically suffixed with a random index and a message is printed —
if you see "Adjusting duplicate light name", pick a unique name.

## The Common Pattern

Delete what is there, create a light, add it:

```matlab
thisR.set('light','all','delete');

newLight = piLightCreate('mainLight', ...
    'type','point', ...
    'spd','equalEnergy', ...
    'cameracoordinate',true);

thisR.set('light',newLight,'add');
```

`'cameracoordinate',true` places the light at the camera's `from` position,
which is the quickest way to get a scene lit and visible. It applies to point,
spot, and area lights.

## Light Types

```matlab
lightTypes = piLightCreate('list available types');
piLightProperties('spot')     % settable properties for one type
```

Valid types: `point`, `spot`, `distant`, `area`, `infinite`, `goniometric`,
`projection`. Default is `point`.

| Type | Notes |
| --- | --- |
| `point` | Equal illumination in all directions. Takes `from`/`to`. |
| `spot` | A cone of directions. Takes `from`, `to`, `coneangle`, `conedeltaangle`. |
| `distant` | Directional source "at infinity". Takes `from`/`to`. |
| `area` | An emitting surface. Takes `shape` (a geometry file or a string such as `'sphere'`) and `radius` in meters. |
| `infinite` | Global illumination from all directions — a **skymap**, backed by an `.exr` file. |
| `goniometric`, `projection` | Less used; see the PBRT v4 file format reference. |

`piLightCreate` key/value pairs are **not** run through `ieParamFormat`, so use
the exact strings shown in its header.

Reference: <https://pbrt.org/fileformat-v4#lights>

## Light Spectra

`spd` decides the emitted spectrum and has three forms:

```matlab
% 1. Named spectrum — a .mat file from isetcam/data/lights
lgt = piLightCreate('L1','type','point','spd','D50');
thisR.set('lights','spot1_L','spd','equalEnergy');

% 2. Blackbody — a color temperature in kelvin; PBRT computes the spectrum
thisR.set('lights','spot1_L','spd',3000);      % 3000 K

% 3. RGB — for a plain RGB rendering
lgt = piLightCreate('L1','type','spot','rgb spd',[1 1 1]);
```

Use `specscale` to set relative weights when a scene has several lights. It
scales the spectrum without changing its shape:

```matlab
thisR.set('light','fill_L','specscale',0.25);
```

`piLightCreate` also accepts `'specscale float',1` as a creation-time pair.

For daylight and sky spectra specifically, see
[`t_skymapDaylight.m`](../../../tutorials/skymap/t_skymapDaylight.m).

## Editing Lights Through The Recipe

`thisR.set('light',...)` takes the light identifier first and the action
second:

```matlab
thisR.set('light',newLight,'add');            % struct, or a cell array of structs
thisR.set('light',lightName,'delete');
thisR.set('light','all','delete');
thisR.set('light',lightName,'replace',newLight);
thisR.set('light',lightName,'rotate',[xrot yrot zrot]);
thisR.set('light',lightName,'translate',[dx dy dz]);
thisR.set('light',lightName,'specscale',val);
thisR.set('light',lightName,'spread val',20);
thisR.set('light',lightName,'spd',[0.5 0.3 1]);
```

The identifier may be a light name (char), an index (numeric), or a light
struct (when adding). Getting:

```matlab
thisR.get('light','names');
thisR.get('lights');
lgt = thisR.get('light',lightName);
thisR.show('lights');
piLightPrint(thisR);
```

Direct struct manipulation uses `piLightSet` / `piLightGet`, but prefer the
recipe-level `thisR.set('light',...)` form so the asset tree stays consistent.

Note that `piLightGet` also returns the PBRT text for a light as a second
output — it is used by `piWrite`, and is more of a text-generation helper than
a clean accessor.

## Skymaps (Environment Lights)

A skymap is an `infinite` light backed by an `.exr` image:

```matlab
[~, skyMap] = thisR.set('skymap','room.exr');
thisR.set('light',skyMap.name,'rotate',[30 0 0]);
```

`thisR.set('skymap',...)` returns the created light as its second output, which
is how you get the generated name for a follow-up rotate.

The extension defaults to `.exr` if you omit it. The setter then stages the
file into the output folder's `skymaps/` directory, searching in this order:

1. already in the output dir → used as-is
2. `piDirGet('skymaps')` — the repository skymap library
3. anywhere on the MATLAB path (`which`)
4. an absolute or relative path you passed

If none match it warns `Unable to find skymap: ...` **and returns without
creating a light** — so a typo in a skymap name produces a black render rather
than an error. Check the light list after setting a skymap.

An `IDBContent` object of type `skymap` may also be passed, which uses the
shared database resource path instead of staging a copy.

Rotating a skymap is the normal way to change the direction of environment
illumination. Skymaps are a good source of realistic ambient light; HDRIs from
sources like <https://polyhaven.com> work once converted. `piDockerImgtool` is
the helper for creating and converting skymap `.exr` files.

## Area Lights

```matlab
lgt = piLightCreate('panel','type','area','shape','sphere','radius',30);
thisR.set('light',lgt,'add');
```

`piAssetObject2Light` converts an existing scene object into an area light,
which is how you make a lamp geometry actually emit. `piLightCube` builds a cube
of lights. Area lights interact with the asset tree more than other types, so
inspect with `thisR.show('assets')` after conversion.

Worked examples: [`t_arealight.m`](../../../tutorials/lights/t_arealight.m),
[`s_arealight.m`](../../../examples/arealights/s_arealight.m),
[`s_lightHeadlamp.m`](../../../examples/arealights/s_lightHeadlamp.m).

## Where To Look

- Tutorials: [`tutorials/lights/`](../../../tutorials/lights/) — start with
  `t_piIntro_light.m`, then `t_arealight.m`, `t_piLightSpectrum.m`.
- Examples: [`examples/arealights/`](../../../examples/arealights/).
- Code: [`utilities/light/`](../../../utilities/light/).
- Tests: `utilities/_tests_/test_piLights.m`,
  `utilities/_tests_/test_skymap_remote.m`.

## Related

- `iset3d-recipe-workflow` — the recipe get/set conventions.
- `iset3d-assets-and-transforms` — lights are asset-tree nodes.
- `iset3d-materials-and-textures` — emissive materials versus area lights.
