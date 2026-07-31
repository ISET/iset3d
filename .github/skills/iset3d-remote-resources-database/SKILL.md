---
name: iset3d-remote-resources-database
description: Use when rendering ISET3D on a remote host or working with shared PBRT resources — rsync scene staging, the /acorn PBRTResources tree, thisR.useDB, the isetdb Mongo metadata, piTextureResourcesUpload, db.* preferences and modernizeDbUserPrefs, SSH tunnels to the Mongo service, or a remote PBRT "file not found" error.
---

# Remote Rendering, Shared Resources, And The Database

**This is Stanford-specific infrastructure.** Many sites render locally and
never need any of it. Set up local rendering first — see the
`iset3d-docker-rendering` skill — and come here only when you actually have a
remote host.

Off-campus access to `orange.stanford.edu` requires an active Stanford VPN.

## Four Separate Things

The single most common mistake is collapsing these into one mental model.
They are independent, and each can fail on its own.

1. **Local recipe output.** `piWrite` writes a self-contained PBRT scene under
   `<piRootPath>/local/<scene-name>/`.
2. **The remote render host.** Docker runs PBRT there, currently
   `orange.stanford.edu`. Governed by the `ISETDocker` preferences.
3. **Shared file resources.** Reusable PBRT assets under
   `/acorn/data/iset/PBRTResources`. **`acorn` is network-attached storage, not
   the render machine.** The path is mounted on the render host and inside the
   PBRT container at the *same absolute path*, which is why `/acorn/...`
   references work inside remote PBRT.
4. **Mongo metadata.** The `isetdb` class stores records in the `PBRTResources`
   collection describing files in the shared tree. **Metadata does not make
   files exist.** File sync and record creation are separate operations.

## Ordinary Remote Rendering (`thisR.useDB == false`)

This is what a normal `piWRS(thisR)` does when `ISETDocker.remoteHost` is set:

1. `piWRS` calls `piWrite(thisR)`.
2. `piWrite` writes `local/<scene>/` with the main `.pbrt` file,
   `<scene>_materials.pbrt`, `<scene>_geometry.pbrt`, and the `geometry/`,
   `textures/`, `skymaps/`, `spds/`, and `lens/` subfolders.
3. `piRender` calls `isetdocker.render`.
4. `isetdocker.upload` runs `rsync -avz --update` to
   `fullfile(ISETDocker.workDir, sceneFolder)`, i.e.
   `/home/<user>/ISETRemoteRender/<scene>/`. It **excludes** `renderings/` and
   the current `.mat` render artifact.
5. PBRT runs remotely, roughly:

   ```text
   docker --context remote-orange exec -it <container> sh -c \
     "pbrt --gpu --outfile /home/<user>/ISETRemoteRender/<scene>/renderings/<scene>.exr \
       /home/<user>/ISETRemoteRender/<scene>/<scene>.pbrt"
   ```

**The rule that follows: every relative file reference in the PBRT files must
exist under the local output folder before upload.** If the materials file says
`"string filename" "textures/slantedbar.png"`, then
`local/<scene>/textures/slantedbar.png` must exist so rsync can carry it over.

A file being present in the Git checkout is *not* enough. It must be staged.

`isetdocker.startPBRT` mounts both `ISETDocker.workDir` and, when the
preference exists, `ISETDocker.PBRTResources` at the same paths inside the
container.

## Database-Backed Resources (`thisR.useDB == true`)

Recipes read with `piRead(idbScene,'docker',thisDocker)` download a stored
recipe `.mat`, point the input file at the shared resource tree, and leave the
recipe referring to `/acorn/...` paths. Several write helpers consult
`thisR.useDB` to decide whether to copy a file into the output folder or write
an absolute resource path instead. It is a storage and transfer optimization
for large shared assets.

It works only if **both** are true:

- the file exists on the shared resource mount, and
- PBRT runs in a container that sees the same absolute `/acorn/...` path.

Typical `PBRTResources` record fields: `type` (`scene`, `asset`, `texture`,
`skymap`, `lens`), `name`, `filepath`, `mainfile`, `category`, `format`,
`source`, `tags`, `description`, `sizeInMB`.

Examples live in
[`examples/database/underDevelopment/`](../../../examples/database/underDevelopment/):
`s_dbResources.m` (list scenes, assets, skymaps, textures),
`s_PBRTResourcesBuild.m` (expected shared tree layout), `s_dbSceneUpload.m`,
`s_dbTextureUpload.m`, `s_dbRendering.m`, `s_dbRecipeMerge.m`. Treat
`underDevelopment/` files as exploratory rather than first-copy templates.

## Preferences

Rendering preferences are under `ISETDocker` — see `iset3d-docker-rendering`.
For remote work the relevant values are typically `remoteHost`
`orange.stanford.edu`, `renderContext` `remote-orange`, `workDir`
`/home/<remoteUser>/ISETRemoteRender`, and `PBRTResources`
`/acorn/data/iset/PBRTResources`.

Database preferences are under `db`. The current `isetdb` names:

| Preference | Value |
| --- | --- |
| `dbServer` | the stable Mongo endpoint, e.g. `acorn:49153` |
| `dbName` | usually `iset` |
| `dbImage` | usually `mongodb` |
| `dbUsername` | Mongo user |
| `dbPassword` | Mongo password |

Legacy names `server`, `port`, `username`, `password` are still accepted as a
fallback. To rewrite them in current form:

```matlab
isetdb.modernizeDbUserPrefs
```

That maps legacy `server`/`port` into `dbServer`, moves the credentials, writes
`dbName` and `dbImage`, and removes the legacy keys by default.

**Never store a password in a script or a doc.** Enter it interactively, or
keep it in a MATLAB preference only on a trusted machine.

## Mongo Connectivity And Tunnels

Many client machines cannot resolve `acorn` directly, though it is reachable
from `orange`. Open a tunnel in a separate terminal:

```text
ssh -N -o ExitOnForwardFailure=yes -L 49154:acorn:49153 <remoteUser>@orange.stanford.edu
```

Keep that window open while MATLAB uses Mongo; `Ctrl-C` when done.

**Keep the saved `dbServer` preference pointed at the real service endpoint
(`acorn:49153`) and pass the tunnel address as a command-local override.** A
tunnel port is a property of one client session, not of the service, and saving
`localhost:49154` into preferences breaks the next machine.

```matlab
pw = input('Mongo password: ','s');

piTextureResourcesUpload('dry run',false, ...
    'sync files',false, ...
    'db server','localhost:49154', ...
    'db name',getpref('db','dbName'), ...
    'db username',getpref('db','dbUsername'), ...
    'db password',pw);

clear pw
```

## Publishing Textures

`piTextureResourcesUpload` syncs image files from `piDirGet('textures')` to the
shared texture folder and creates missing `PBRTResources` records. **It is a dry
run by default** — nothing remote changes until you say so.

```matlab
piTextureResourcesUpload('dry run',true);                             % review
piTextureResourcesUpload('dry run',false,'create db records',false);  % files only
piTextureResourcesUpload('dry run',false,'sync files',false);         % records only
```

The two halves are genuinely separable: files can land on acorn even if Mongo
record creation fails for credential reasons, and vice versa. `'sync files'`
and `'create db records'` each default to the inverse of `'dry run'`.

Other options: `'local dir'`, `'remote dir'`, `'remote host'`, `'remote user'`,
`'collection name'`, `'extensions'`, `'verbose'`. The remote defaults fall back
to `/acorn/data/iset/PBRTResources/texture` and `orange.stanford.edu` when the
preferences are unset.

File transfer uses SFTP to the render host; metadata uses the `isetdb` Mongo
connection. Related: `filesSyncRemote`, `queryConstruct`, `hashStruct`.

## Failure Modes

| Symptom | Meaning |
| --- | --- |
| `textures/<file>: file not found` | PBRT read the scene but the file is not present relative to the uploaded folder, and is not an accessible absolute resource. Staging problem. |
| `isetdb` falls back to `localhost:27017` | No current `db.*` preferences and no usable legacy values. |
| `Failed to resolve 'acorn'` | The client cannot resolve the storage/database host. Tunnel through orange. |
| `Address already in use` starting the tunnel | Something already listens on that local port. Close it or pick another and pass the matching `localhost:<port>`. |
| `Command listCollections requires authentication` | Mongo was reached; credentials missing or wrong. |
| `no CUDA-capable device is detected` | Stale `PBRTContainer`. See `iset3d-docker-rendering`. |

## Checklists

**Ordinary remote render:**

1. `piDockerDiagnose('render',false)`
2. `piWrite(thisR)`
3. `[~,~,textureList,missingTextures] = piRenderValidate(thisR)` — note this is
   **local**. Passing means the output folder is self-contained enough to
   upload; it does **not** prove the upload happened.
4. Confirm referenced files exist under `thisR.get('output dir')`.
5. Render.
6. To inspect the remote side:

   ```matlab
   thisD = isetdocker;
   remoteSceneDir = fullfile(getpref('ISETDocker','workDir'), ...
       thisR.get('input folder basename'));
   dir(thisD.sftpSession, fullfile(remoteSceneDir,'textures'))
   ```

**DB-backed scene:**

1. The file exists under `/acorn/data/iset/PBRTResources`.
2. The `PBRTResources` record exists.
3. `thisR.useDB == true`.
4. `ISETDocker.PBRTResources` is configured and mounted by the container.

## Architectural Note For Maintainers

Ordinary remote rendering and database-backed resources must stay cleanly
separated in the write helpers. `piTextureText` branches on local files, remote
hosts, and `useDB`; **the ordinary remote-render branch must always leave a
self-contained local output folder for rsync.** Tests should cover local
staging of image-map presets, remote-write staging with `remoteHost` set and
`useDB == false`, resource-library fallback via `piResourceFind`, and
`useDB == true` path rewriting.

Long-form: [docs/remote-rendering.md](../../../docs/remote-rendering.md),
[docs/rendering-database.md](../../../docs/rendering-database.md).

## Related

- `iset3d-docker-rendering` — preferences, contexts, and diagnosis.
- `iset3d-materials-and-textures` — the local texture staging rules.
- `iset3d-scene-sources` — the public SDR download path, which needs none of this.
