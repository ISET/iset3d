---
name: iset3d-assets-and-transforms
description: Use when navigating or editing the ISET3D asset tree — finding objects with piAssetSearch or piAssetFind, reading and setting node properties, translating, rotating, or scaling assets, world versus local coordinates, adding, inserting, copying, or deleting nodes, object instances, or asset motion.
---

# The Asset Tree And Transforms

`thisR.assets` is a tree of nodes. Everything geometric in a scene is a node,
including lights.

Three node types (`piAssetCreate('type',...)`):

| Type | Role |
| --- | --- |
| `branch` | Interior node. Holds position, rotation, and scale that **apply to everything beneath it**. |
| `object` | Leaf. A real piece of geometry with a shape and a material name. |
| `light` | Leaf. A light source. See the `iset3d-lights-and-skymaps` skill. |

Two consequences worth internalizing:

- Transforms live on **branch** nodes, not on objects. Translating an "object"
  actually manipulates the branch above it, and `piAssetTranslate` and friends
  will create or find that branch for you.
- Because transforms compose down the tree, a node's world position is the
  product of every branch above it. Use the `world *` getters rather than
  reading a single node's translation.

Nodes are occasionally mislabeled in scenes exported from other tools. If a
transform behaves strangely, check `thisR.get('asset',id,'type')` first.

## Orientation

```matlab
thisR.show('assets');            % opens a window with the node tree
thisR.show('node names');
thisR.show('object positions');
thisR.get('object names');
thisR.get('n objects');
thisR.get('print materials');
piAssetGeometry(thisR);          % 3D plot of object positions and sizes
```

## Finding Nodes

`piAssetSearch` is the everyday tool. It returns **numeric node indices** for
nodes matching a substring (case-insensitive by default):

```matlab
idx = piAssetSearch(thisR,'object name','GroundMaterial');
idx = piAssetSearch(thisR,'material name','Mrke_brikker_004');
idx = piAssetSearch(thisR,'light name','room');
idx = piAssetSearch(thisR,'object name','plane','ignore case',false);
```

Search types: `'object name'`, `'material name'`, `'light name'`,
`'branch name'`. It is a linear scan, so it is slow on large scenes but always
correct.

`piAssetFind(thisR,'id',val)` / `piAssetFind(thisR,'name',name)` is the lower
level lookup returning `[id, assetStruct]`.

Most getters and setters accept either a numeric id or a name, so
`piAssetSearch` output can be passed straight through.

## Reading Node Properties

```matlab
thisR.get('asset',idx,'name');
thisR.get('asset',idx,'type');
thisR.get('asset',idx,'material name');
thisR.get('asset',idx,'size');
thisR.get('asset',idx,'shape');

% Local (this node's own branch)
thisR.get('asset',idx,'translation');
thisR.get('asset',idx,'rotation');
thisR.get('asset',idx,'scale');

% World (composed through every branch above)
thisR.get('asset',idx,'world position');
thisR.get('asset',idx,'world rotation matrix');
thisR.get('asset',idx,'world scale');
```

Whole-scene getters: `thisR.get('object coordinates')`,
`thisR.get('object sizes')`, `thisR.get('object names')`,
`thisR.get('branch names')`, `thisR.get('object name material')`.

Names carry a type suffix (`_O`, `_B`, `_L`). The `no id` variants
(`'object names no id'`, `'branch names no id'`, `'name no id'`) strip the
numeric prefix that keeps duplicate names unique — useful for matching against
names in a PBRT file.

## Editing The Tree

The calling convention is `thisR.set('asset', nameOrID, action, value)`:

```matlab
thisR.set('asset',idx,'translate',[0.1 0 0]);        % local axes, meters
thisR.set('asset',idx,'world translate',[0.1 0 0]);  % world axes
thisR.set('asset',idx,'rotate',[0 45 0]);            % degrees [x y z]
thisR.set('asset',idx,'rotation matrix',R);          % a 4x4
thisR.set('asset',idx,'scale',2);

thisR.set('asset',parentName,'add',newAsset);
thisR.set('asset',assetName,'insert',newAsset);
thisR.set('asset',assetName,'delete');
thisR.set('asset',assetName,'parent',parentID);
thisR.set('asset',idx,'material name',matName);

thisR.set('asset',assetName,'cancel last transformation');
thisR.set('asset',assetName,'clear motion');
```

`'world translate'` converts the requested world-space displacement into the
node's local frame using its world rotation matrix and scale — use it when you
want to move something along a world axis regardless of how its parents are
oriented.

`'cancel last transformation'` (aliases: `remove last trans`,
`cancel last action`) undoes the most recent transform on that node. It affects
transforms only, never motion.

Units are meters. Rotations are degrees, ordered `[x y z]`.

## The Transform Utilities

For work beyond single set calls,
[`utilities/transform/`](../../../utilities/transform/) has the composition
math:

`piTransformCompose`, `piTransformDecompose`, `piTransformConcat`,
`piTransformRotation`, `piTransformRotationInAbsSpace`, `piTransformTranslation`,
`piTransformAxis`, `piTransformWorld2Obj`, `piTransformDegs2RotM`,
`piTransformRotM2Degs`, `piRotate`, `piRotateFrom`, `piAngle2dcm`,
`piDCM2angle`, `piRotationMatrix`.

`piRotationMatrix` is the one you want when building camera-motion transforms:

```matlab
thisR.set('camera motion rotate start',piRotationMatrix);
thisR.set('camera motion rotate end',piRotationMatrix('zrot',5));
```

## Loading, Copying, And Saving Assets

```matlab
thisAsset = piAssetLoad('bunny');          % load a stored asset
thisR     = piRecipeMerge(thisR,otherR);   % merge another recipe's assets
piAssetTreeSave(thisR,idx,fname);
tree      = piAssetTreeLoad(fname);
```

`piAssetGeneratePattern` builds arrays of a repeated asset.
`piAssetObject2Light` turns an object into an area light.

## Object Instances

Instances let PBRT reuse one piece of geometry many times without duplicating
it in memory — the right tool for a crowd of identical objects:

```matlab
thisR = piObjectInstanceCreate(thisR,assetName);
piObjectInstance(thisR);
thisR = piObjectInstanceRemove(thisR,instanceName);

thisR.get('instances');
thisR.get('instance names');
thisR.get('reference objects');
```

Rendering with `'render type','instance'` produces an instance-label image.
Tests: `utilities/asset/_tests_/test_objectInstance.m`.

## Motion

Object motion (as opposed to camera motion) is set on the node:

```matlab
piAssetMotionAdd(thisR,assetName,'translation',[0.02 0 0]);
thisR.set('asset',assetName,'clear motion');
```

Motion is blurred over the exposure defined by
`thisR.set('shutter open'/'shutter close')` or
`thisR.set('exposure time',t)`. See
[`t_assetsMotion.m`](../../../tutorials/assets/t_assetsMotion.m). Camera motion
is a recipe-level setting instead — see `iset3d-camera-and-optics`.

## Where To Look

- Tutorials: [`tutorials/assets/`](../../../tutorials/assets/) — start with
  `t_assets.m`, then `t_assetsMotion.m`.
- Code: [`utilities/asset/`](../../../utilities/asset/),
  [`utilities/transform/`](../../../utilities/transform/).
- Tests: `utilities/asset/_tests_/test_worldCoordinates.m`,
  `test_objectInstance.m`.

## Related

- `iset3d-materials-and-textures` — assigning a material to a found object.
- `iset3d-lights-and-skymaps` — lights are leaves of this same tree.
- `iset3d-recipe-workflow` — how to look up a get/set parameter name.
