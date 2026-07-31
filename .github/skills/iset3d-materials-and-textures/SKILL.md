---
name: iset3d-materials-and-textures
description: Use when creating, inspecting, editing, or assigning ISET3D materials and textures — piMaterialCreate, piMaterialSet/Get, piMaterialPresets, piMaterialsInsert, thisR.set('material',...), piTextureCreate, image-map versus procedural textures, texture file staging, or a PBRT "file not found" error naming a texture.
---

# Materials And Textures

Materials live in the recipe as a `containers.Map` (`thisR.materials.list`)
plus an ordering cell array (`thisR.materials.order`). Objects in the asset
tree reference materials **by name**. Textures live in a parallel structure and
are referenced by materials.

## The Standard Edit

Find the object, read its material, change it or assign a new one:

```matlab
assetID = piAssetSearch(thisR,'object name','figure_3m');
matName = thisR.get('asset',assetID,'material name');

thisR.get('material',matName,'reflectance');
thisR.set('material',matName,'reflectance',[0 0.5 0]);

glassMaterial = piMaterialCreate('blueGuyGlass','type','dielectric');
thisR.set('material','add',glassMaterial);
thisR.set('asset',assetID,'material name',glassMaterial.name);
```

Orientation calls on an unfamiliar scene:

```matlab
thisR.get('print materials');     % numbered list of materials in the recipe
thisR.get('n materials');
thisR.show('object materials');   % table of objects and their materials
piMaterialPrint(thisR);
piAssetMaterialPrint(thisR);
```

## Creating Materials

```matlab
piMaterialCreate('list available types')
piMaterialProperties('coateddiffuse')     % settable properties for one type
```

Valid types: `diffuse`, `coateddiffuse`, `coatedconductor`, `conductor`,
`diffusetransmission`, `dielectric`, `thindielectric`, `hair`, `measured`,
`subsurface`, `mix`, `interface`. Default is `diffuse`.

Property keys use a **`'TYPE NAME'` two-word form** — the space is how the
parser splits the PBRT parameter type from its name:

```matlab
m = piMaterialCreate('m1','type','kdsubsurface','kd rgb',[1 1 1]);
m = piMaterialCreate('m2','type','uber','spectrum kd',[400 1 800 1]);
```

Either order works (`'kd rgb'` or `'rgb kd'`). Internally the space is replaced
with `_` before parsing, so do not pass an already-underscored key.

PBRT's own parameter reference: <https://pbrt.org/fileformat-v4>

## Material Presets

`piMaterialPresets` encapsulates appearance-tuned materials collected from PBRT
examples. This is usually a better starting point than building a material from
raw parameters.

```matlab
allMaterials = piMaterialPresets('list');       % numbered list, returns a cell array
piMaterialPresets('glass list');                % one class
piMaterialPresets('preview');                   % previewable materials
piMaterialPresets('preview','fabric-leather-var1.jpg');

newMat = piMaterialPresets('wood-medium-knots','woodfloor');
thisR.set('material','add',newMat);
```

Classes include `diffuse`, `glossy`, `glass`, `metal`, `car`, `marble`,
`testpatterns`, `wood`, `fabric`, `brick`. The set grows over time — use
`'list'` rather than a memorized name.

**A preset may carry textures.** `piMaterialPresets` returns a struct with a
`.material` field and possibly a `.texture` field (a struct or a cell array).
`thisR.set('material','add',newMat)` detects this and adds the textures first,
then the material. If you unpack the struct yourself, you must add both.

To insert several at once:

```matlab
thisR = piMaterialsInsert(thisR,'names',{'wood-medium-knots'});
thisR = piMaterialsInsert(thisR,'groups',{'glass','metal'});
thisR.get('print materials');
```

Note `piMaterialsInsert` does not currently guard against overwriting a
material that already exists under the same name.

## The Recipe Material Interface

```matlab
thisR.set('material','add',newMaterial);
thisR.set('material','delete',matName);            % name or index
thisR.set('material',matName,'replace',newMaterial);
thisR.set('material',matName,'PARAM TYPE',value);  % e.g. 'reflectance', [0 .5 0]
thisR.set('material',materialList);                % replace the whole containers.Map
```

Getting: `thisR.get('material',matName,param)`, `thisR.get('materials')`,
`piMaterialGet`, `piMaterialFind`. `piMaterialPlot` draws a material's spectral
properties — prefer it over ad hoc plotting.

Fluorescence has its own helpers: `piMaterialFluorescent`,
`piMaterialApplyFluorescence`, `piMaterialGenerateEEM`, `piMaterialMixEEM`,
`piDeleteFluorescent`.

## Textures

```matlab
tTypes = piTextureCreate('help');
piTextureProperties('checkerboard');
```

Valid types: `constant`, `scale`, `mix`, `bilerp`, `imagemap`, `checkerboard`,
`dots`, `fbm`, `wrinkled`, `marble`, `windy`.

```matlab
texture = piTextureCreate('checkerboard_texture', ...
    'type','checkerboard', ...
    'uscale',8,'vscale',8, ...
    'tex1',[.01 .01 .01], ...
    'tex2',[.99 .99 .99]);

thisR.set('texture','add',texture);
thisR.get('print textures');
```

The critical distinction:

- **Procedural textures** — `checkerboard`, `dots`, `fbm`, `wrinkled`,
  `marble`, `windy`, `constant`. PBRT computes them. **No image file needed.**
- **Image-map textures** — `imagemap`. These reference a PNG or EXR **file that
  must be present when PBRT runs.**

```matlab
piTextureCreate(materialName, ...
    'format','spectrum', ...
    'type','imagemap', ...
    'filename','textures/slantedbar.png')
```

Among the material presets, `checkerboard` and `dots` are procedural;
`slantededge`, `ringsrays`, and `macbethchart` are image maps and need files.

## Texture File Staging — The Common Failure

A PBRT error like:

```text
cornell_box_materials.pbrt:2:0:
textures/slantedbar.png: file not found.
Error: 1 missing textures
```

means PBRT started fine and read the materials file, but the referenced image
was not there. **This is a staging problem, not a Docker problem.**

The local texture library is `data/materials/textures`, reachable as
`piDirGet('textures')`. Being present *there* is not enough — the file must be
copied into the scene's output folder:

```text
data/materials/textures/slantedbar.png
  -> piWrite stages local/<scene>/textures/slantedbar.png
  -> (remote only) rsync uploads it with the scene folder
  -> PBRT reads "textures/slantedbar.png" relative to <scene>.pbrt
```

`piTextureText` is the write-time function that composes the `Texture` line and
performs this staging. Its behavior:

- Already in the output folder or its `textures/` subfolder → referenced as
  `textures/<filename>`.
- Found via `piResourceFind('texture',filename)` → copied into the output
  `textures/` folder.
- Remote host configured **and `thisR.useDB == false`** → still copied locally,
  because rsync only uploads the output folder.
- `thisR.useDB == true` → an absolute `/acorn/...` resource path may be written
  instead of copying.

An absolute path that starts with `/` is treated as a remote resource reference
**unless** the parameter is `filename`, `useDB` is false, and the file exists
locally — in which case it is staged. That conditional is the trap: ordinary
remote rendering must always leave a self-contained local output folder.

### Diagnosing it

```matlab
piWrite(thisR);
[~,~,textureList,missingTextures] = piRenderValidate(thisR);
fullfile(thisR.get('output dir'),'textures','slantedbar.png')
```

`piRenderValidate` is **local**. Passing means the output folder is
self-contained enough to upload; it does not prove the upload happened. For the
remote side, see the `iset3d-remote-resources-database` skill.

## Assigning Materials To Objects

```matlab
assetID = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset',assetID,'material name',matName);
```

See the `iset3d-assets-and-transforms` skill for locating objects in the tree.
`piMaterialTextureAdd` attaches a texture to an existing material.

## Where To Look

- Tutorials: [`tutorials/materials/`](../../../tutorials/materials/) — start
  with `t_materials.m`; `t_piIntro_material.m` and `t_piIntro_texture.m` are
  the shortest introductions.
- Examples: [`s_piMaterials.m`](../../../examples/materials/s_piMaterials.m)
  changes a sphere between diffuse, mirror, and coated green.
- Code: [`utilities/material/`](../../../utilities/material/),
  [`utilities/texture/`](../../../utilities/texture/).
- Tests: `utilities/_tests_/test_piMaterials.m`,
  `test_textureAssets.m`, `test_materials_remote.m`, `test_texture_remote.m`.

## Related

- `iset3d-assets-and-transforms` — finding the object to assign to.
- `iset3d-remote-resources-database` — the `useDB` path and remote staging.
- `iset3d-recipe-workflow` — `piWrite` output layout.
