# Remote Rendering And Resource Staging

This note summarizes how ISET3d writes PBRT scenes, moves files to a remote
render host, and uses the shared PBRT resource database. It is intended to
make failures such as a remote PBRT error for `textures/slantedbar.png: file
not found` easier to diagnose.

## Two Different Remote Concepts

ISET3d has two related but distinct mechanisms:

1. **Ordinary remote rendering**
   - A recipe is written locally under `piRootPath/local/<scene>/`.
   - The entire local scene output folder is uploaded to the configured remote
     render work directory, usually:
     `/home/<remoteUser>/ISETRemoteRender/<scene>/`.
   - PBRT runs inside a Docker container on the remote host and reads the
     uploaded copy of the scene.
   - This is the path used by a normal `piWRS(thisR)` when `ISETDocker.remoteHost`
     is configured.

2. **Database-backed remote resources**
   - Large reusable resources live under the shared PBRT resource tree,
     usually:
     `/acorn/data/iset/PBRTResources/`.
   - The Docker container mounts that tree at the same absolute path.
   - Recipes with `thisR.useDB == true` may write references to files already
     present in the shared resource tree instead of copying those files into
     the local scene output folder.
   - The Mongo-backed `isetdb` metadata describes what exists in the shared
     tree; it does not by itself make files available to PBRT.

These paths can both involve `orange.stanford.edu`, but they are not
interchangeable. A file copied into the local Git checkout is available to
`piWrite`, but remote PBRT sees it only if it is staged into the scene output
folder and uploaded, or if the recipe intentionally points to a mounted shared
resource path.

## Configuration

Remote rendering is controlled by MATLAB preferences in the `ISETDocker`
preference group. Important fields include:

- `renderContext`: Docker context name, commonly `remote-orange`.
- `remoteHost`: SSH host, commonly `orange.stanford.edu`.
- `remoteUser`: SSH/SFTP user.
- `workDir`: remote per-user render working directory, commonly
  `/home/<remoteUser>/ISETRemoteRender`.
- `PBRTResources`: shared resource mount, commonly
  `/acorn/data/iset/PBRTResources`.
- `PBRTContainer`: transient running PBRT container name. This can become stale.
- `device`, `deviceID`, `dockerImage`: CPU/GPU and container image settings.

Use `piDockerConfig` to set these preferences and `piDockerDiagnose` to inspect
them. `piDockerDiagnose('render',false)` checks Docker, rsync, SSH, preference
structure, Docker context, GPU visibility, and stale container state without
running a full scene render.

When the PBRT container starts, `isetdocker.startPBRT` mounts both:

- `ISETDocker.workDir` at the same path inside the container.
- `ISETDocker.PBRTResources` at the same path inside the container, when that
  preference exists.

This same-path mount convention is why absolute paths under `/home/...` and
`/acorn/...` can work inside remote PBRT.

## Ordinary Remote Render Flow

The standard `piWRS(thisR)` flow is:

1. `piWRS` calls `piWrite(thisR)`.
2. `piWrite` writes the local scene folder:
   `piRootPath/local/<scene>/`.
3. `piWrite` also writes or copies resources that PBRT should find relative to
   the scene folder:
   - main PBRT file
   - `<scene>_materials.pbrt`
   - `<scene>_geometry.pbrt`
   - `geometry/`
   - `textures/`
   - `skymaps/`
   - `spds/`
   - `lens/`
4. `piRender` calls `isetdocker.render`.
5. `isetdocker.render` computes the remote scene folder:
   `fullfile(ISETDocker.workDir, sceneFolder)`.
6. `isetdocker.upload` uses `rsync -avz --update` to upload the local output
   folder contents to the remote scene folder. It excludes `renderings/` and
   the current `.mat` render artifact.
7. PBRT runs remotely with a command like:

   ```text
   docker --context remote-orange exec -it <container> sh -c \
     "pbrt --gpu --outfile /home/<user>/ISETRemoteRender/<scene>/renderings/<scene>.exr \
       /home/<user>/ISETRemoteRender/<scene>/<scene>.pbrt"
   ```

For this ordinary path, every relative file reference in the PBRT files must
exist under the local output folder before upload. If the materials file says
`"string filename" "textures/slantedbar.png"`, then the local output folder
must contain `textures/slantedbar.png` so rsync can upload it.

## Database Resource Flow

The database resource flow starts from `isetdb` records in the `PBRTResources`
collection. Records describe resources by fields such as:

- `type`: `scene`, `asset`, `texture`, `skymap`, `lens`, and related resource
  categories.
- `name`: searchable resource name.
- `filepath`: absolute path in the shared remote resource tree.
- `mainfile`: main PBRT, texture, or other representative file.
- `category`, `format`, `source`, `tags`, and size metadata.

Database examples live in `examples/database/`. In particular:

- `s_dbResources.m` lists scenes, assets, skymaps, and textures.
- `s_PBRTResourcesBuild.m` documents the expected shared resource tree,
  including `/acorn/data/iset/PBRTResources`.
- `s_dbSceneUpload.m` shows the intended pattern for uploading a scene folder
  into the shared resource tree and creating a database record.
- `s_dbTextureUpload.m` shows the same idea for texture resources.

Reading a database scene uses `piRead(idbScene,'docker',thisDocker)`. The
database read path downloads a stored recipe `.mat` file, sets the recipe input
file to the remote resource path, and leaves the recipe configured to refer to
the resource tree.

In this mode, `thisR.useDB == true` is important. Several write helpers use it
to decide whether a filename should be copied into the ordinary output folder
or rewritten to a remote resource location. This is a performance and storage
optimization for large shared resources.

## Texture Handling

Material presets can create PBRT textures. Examples:

- `checkerboard` and `dots` are procedural PBRT textures and do not need image
  files.
- `slantededge`, `ringsrays`, and `macbethchart` are image-map textures and do
  need PNG files.

The material preset `slantededge` uses:

```matlab
piTextureCreate(materialName, ...
    'format', 'spectrum', ...
    'type', 'imagemap', ...
    'filename', 'textures/slantedbar.png')
```

`piTextureText` is the key write-time function. It composes the PBRT `Texture`
line and tries to ensure texture files are present. The important behavior is:

- If the texture is already in the output folder or output `textures/` folder,
  it is referenced as `textures/<filename>`.
- If the texture is found through `piResourceFind('texture', filename)`, local
  rendering copies it into the output `textures/` folder.
- When `ISETDocker.remoteHost` is configured and `thisR.useDB == false`, a
  locally found image-map texture should still be copied into the output
  folder. Ordinary remote rendering depends on this local staging step because
  rsync only uploads the output folder.
- If `thisR.useDB == true`, the code may instead trust a remote database
  resource path.

That last pair of bullets is the trap: ordinary remote rendering still depends
on rsyncing the local output folder. A local texture library file must be staged
into the output folder, not merely found somewhere under the local repository.

## Example Failure: `slantedbar.png`

The failure:

```text
cornell_box_materials.pbrt:2:0:
textures/slantedbar.png: file not found.
Error: 1 missing textures
```

means PBRT successfully reached the remote scene and read the remote materials
file, but the relative texture file did not exist at:

```text
/home/<remoteUser>/ISETRemoteRender/cornell_box/textures/slantedbar.png
```

For ordinary remote rendering, the expected chain is:

```text
local data/materials/textures/slantedbar.png
  -> piWrite stages local/cornell_box/textures/slantedbar.png
  -> rsync uploads /home/<user>/ISETRemoteRender/cornell_box/textures/slantedbar.png
  -> PBRT reads textures/slantedbar.png relative to cornell_box.pbrt
```

The local texture library restore is necessary, but not sufficient. The texture
must also be staged into the local output scene folder before `isetdocker.upload`
runs.

## Validation Checklist

For an ordinary remote render:

1. Confirm Docker preferences:

   ```matlab
   piDockerDiagnose('render', false)
   ```

2. Write the scene without rendering:

   ```matlab
   piWrite(thisR);
   ```

3. Check local staged resources:

   ```matlab
   fullfile(thisR.get('output dir'), 'textures', 'slantedbar.png')
   ```

4. Validate local recipe file references:

   ```matlab
   [~,~,textureList,missingTextures] = piRenderValidate(thisR);
   ```

   This validation is local. Passing it means the local output folder is
   self-contained enough to upload; it does not prove that the remote upload
   has already occurred.

5. For remote upload debugging, compare the remote folder after `piWRS` starts
   or by using the `isetdocker` SFTP session:

   ```matlab
   thisD = isetdocker;
   remoteSceneDir = fullfile(getpref('ISETDocker','workDir'), ...
       thisR.get('input folder basename'));
   dir(thisD.sftpSession, fullfile(remoteSceneDir, 'textures'))
   ```

For a database-backed scene:

1. Confirm `thisR.useDB == true`.
2. Confirm the recipe input file points to the shared resource tree, usually
   under `/acorn/data/iset/PBRTResources`.
3. Confirm `ISETDocker.PBRTResources` is configured and mounted when the PBRT
   container starts.
4. Confirm the database record and the actual file both exist. The metadata
   alone is not enough.

## Current Architectural Risk

The remote texture failure showed that ordinary remote rendering and
database-backed resources must stay cleanly separated in helper functions.
`piTextureText` has branches for local files, remote hosts, and `useDB`; the
ordinary remote-render branch must always leave a self-contained local output
folder for rsync.

Tests should cover at least:

- local render staging of image-map texture presets;
- ordinary remote-write staging with `ISETDocker.remoteHost` set and
  `thisR.useDB == false`;
- resource-library fallback staging when a texture is found through
  `piResourceFind`;
- database-backed path rewriting with `thisR.useDB == true`.

The first case protects local data presence. The second and third protect the
`slantedbar.png` failure mode. The final case protects the shared-resource
optimization.
