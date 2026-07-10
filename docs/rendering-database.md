# Rendering Database And Remote Resource Notes

This note summarizes the ISET3D remote rendering database pieces as they are
currently understood. It focuses on the distinction between file resources,
render execution, and Mongo metadata because those three ideas are easy to
collapse into one mental model.

## Components

Remote rendering touches four separate things:

1. **Local recipe output**
   - `piWrite` writes a self-contained PBRT scene under:

     ```text
     <piRootPath>/local/<scene-name>
     ```

   - Ordinary remote rendering uploads this folder to the render host before
     PBRT runs.

2. **Remote render host**
   - The current common render host is `orange.stanford.edu`.
   - Docker runs PBRT on this host.
   - `ISETDocker` MATLAB preferences define the SSH host, Docker context,
     remote user, remote work directory, Docker image, GPU settings, and shared
     resource mount.

3. **Shared file resources**
   - Reusable PBRT resources live under:

     ```text
     /acorn/data/iset/PBRTResources
     ```

   - `acorn` is network attached storage, not the PBRT render machine.
   - The resource path is mounted on orange and into the PBRT Docker container,
     so absolute paths under `/acorn/data/iset/PBRTResources` can work inside
     remote PBRT when the container volume is mounted.

4. **Mongo metadata**
   - The `isetdb` class stores metadata in the Mongo database, usually in the
     `PBRTResources` collection.
   - Metadata records describe files in the shared resource tree; they do not
     make the files exist.
   - File sync and metadata creation are separate operations.

## Ordinary Remote Rendering

The ordinary remote render path is used when `thisR.useDB == false`.

The expected flow is:

1. `piWrite(thisR)` writes the local scene folder.
2. Write helpers stage local resources such as `textures/`, `geometry/`,
   `skymaps/`, `spds/`, and `lens/` under that scene folder.
3. `isetdocker.upload` syncs the local scene folder to:

   ```text
   /home/<remoteUser>/ISETRemoteRender/<scene-name>
   ```

4. PBRT runs on orange inside Docker and reads the uploaded scene folder.

For this path, every relative PBRT filename must exist inside the local output
folder before upload. For example:

```text
"string filename" "textures/slantedbar.png"
```

requires:

```text
<piRootPath>/local/<scene-name>/textures/slantedbar.png
```

The file being present in the Git checkout is not enough unless `piWrite`
stages it into the output folder.

## Database-Backed Resources

Database-backed resources are used when a recipe intentionally points at files
already present under the shared PBRT resource tree and `thisR.useDB == true`.

Typical records in the `PBRTResources` collection contain:

- `type`: for example `scene`, `asset`, `texture`, `skymap`, `lens`;
- `name`: searchable display name;
- `filepath`: directory in `/acorn/data/iset/PBRTResources`;
- `mainfile`: representative file, such as a PBRT file or texture image;
- `category`, `source`, `tags`, `description`, `format`, and `sizeInMB`.

When using database-backed resources, ISET3D write helpers may preserve or
write absolute resource paths rather than copying files into the local render
folder. This is useful for large shared resources, but it depends on two facts:

- the file exists on the shared resource mount;
- PBRT runs in a container that sees the same absolute `/acorn/...` path.

## MATLAB Preferences

Remote rendering preferences live under `ISETDocker`. Important fields include:

- `remoteHost`, commonly `orange.stanford.edu`;
- `remoteUser`;
- `renderContext`, commonly `remote-orange`;
- `workDir`, commonly `/home/<remoteUser>/ISETRemoteRender`;
- `PBRTResources`, commonly `/acorn/data/iset/PBRTResources`;
- `dockerImage`, `device`, and `deviceID`.

Database preferences live under `db`. The current `isetdb` property names are:

- `dbServer`, the stable Mongo endpoint, for example `acorn:49153`;
- `dbName`, usually `iset`;
- `dbImage`, usually `mongodb`;
- `dbUsername`;
- `dbPassword`.

Avoid saving a temporary SSH tunnel address, such as `localhost:49154`, as the
persistent `dbServer` preference. Use the real service endpoint in preferences
and pass the tunnel endpoint only for the MATLAB command that needs it.

Older preferences used:

- `server`;
- `port`;
- `username`;
- `password`.

`isetdb` now accepts those older names as a compatibility fallback. To write the
current names explicitly, run:

```matlab
isetdb.modernizeDbUserPrefs
```

This maps legacy `server` and `port` into `dbServer`, maps legacy credentials
into `dbUsername` and `dbPassword`, writes `dbName` and `dbImage`, and removes
the legacy keys by default.

## Texture Resources

The local ISET3D texture library is:

```text
data/materials/textures
```

The shared remote texture resource folder is:

```text
/acorn/data/iset/PBRTResources/texture
```

Use:

```matlab
piTextureResourcesUpload('dry run', true)
```

to review the local image files that would be published. Use:

```matlab
piTextureResourcesUpload('dry run', false)
```

to sync files and create missing `PBRTResources` texture metadata records.

The helper performs two separable steps:

- SFTP syncs local texture image files to the acorn resource folder through the
  configured remote host.
- `isetdb` creates Mongo metadata records for missing texture `mainfile`
  values.

The current texture image files have been synced to:

```text
/acorn/data/iset/PBRTResources/texture
```

The current texture metadata records were created through a tunneled Mongo
connection on 2026-07-10. Re-running the upload helper should normally report
those records as existing unless the shared resource set has changed.

## Mongo Connectivity

From this client machine, the hostname `acorn` did not resolve directly.
However, from orange:

```text
acorn:49153
```

was reachable. The recommended preference value is therefore the real endpoint:

```matlab
setpref('db', 'dbServer', 'acorn:49153')
setpref('db', 'dbName', 'iset')
setpref('db', 'dbUsername', '<mongo-user>')
```

Do not store the password in scripts or documentation. Enter it interactively
when needed, or store it in a local MATLAB preference only on a trusted machine.

When the client machine cannot resolve `acorn`, open an SSH tunnel through the
remote render host in a separate Terminal window:

```text
ssh -N -o ExitOnForwardFailure=yes -L 49154:acorn:49153 <remoteUser>@orange.stanford.edu
```

Keep that Terminal window open while MATLAB is using Mongo. Stop the tunnel
with `Ctrl-C` after the database work is finished.

With the tunnel open, point `isetdb` or the texture uploader at the temporary
local endpoint:

```text
localhost:49154
```

For example:

```matlab
pw = input('Mongo password: ', 's');

piTextureResourcesUpload('dry run', false, ...
    'sync files', false, ...
    'db server', 'localhost:49154', ...
    'db name', getpref('db', 'dbName'), ...
    'db username', getpref('db', 'dbUsername'), ...
    'db password', pw);

clear pw
```

This override should be command-local. The saved `dbServer` preference should
remain `acorn:49153` so that the preference describes the actual Mongo service,
not the port chosen for one client-side tunnel.

A better long-term solution would be a small helper that reads the real
`dbServer` preference, tests whether it is directly reachable, and either
returns that endpoint or reports the exact SSH tunnel command to run. That would
keep the connection policy in one place and reduce the chance of saving
machine-specific tunnel addresses in preferences.

## Failure Modes

Common failures and what they mean:

- PBRT reports `textures/<file>: file not found`.
  The remote render reached the scene file, but the texture was not present
  relative to the uploaded scene folder or as an accessible absolute resource.

- `isetdb` falls back to `localhost:27017`.
  MATLAB preferences are missing current `db.*` names and no compatible legacy
  values were found.

- `Failed to resolve 'acorn'`.
  The client machine cannot resolve the storage or database hostname directly.
  Reach it through orange with the SSH tunnel above, or use another Stanford
  network context where `acorn` resolves.

- `Address already in use` when starting the SSH tunnel.
  Another process is already listening on local port `49154`. Either close the
  earlier tunnel or choose a different local port and pass the matching
  `localhost:<port>` endpoint to the MATLAB command.

- `Command listCollections requires authentication`.
  The Mongo service was reached, but credentials were missing or wrong.

## Practical Checklist

For ordinary remote renders:

1. Run `piWrite(thisR)`.
2. Run `piRenderValidate(thisR)`.
3. Confirm referenced texture files exist under the local output folder.
4. Render with Docker after local validation passes.

For DB-backed resources:

1. Confirm the file exists under `/acorn/data/iset/PBRTResources`.
2. Confirm the corresponding `PBRTResources` metadata record exists.
3. Confirm `thisR.useDB == true`.
4. Confirm the PBRT container mounts `ISETDocker.PBRTResources`.

For publishing textures:

1. Run `piTextureResourcesUpload('dry run', true)`.
2. Sync files with `piTextureResourcesUpload('dry run', false, 'create db records', false)`.
3. If `acorn:49153` is not directly reachable, open the SSH tunnel and use
   `localhost:49154` as a command-local `db server` override.
4. Confirm Mongo credentials and endpoint.
5. Create missing DB records with `piTextureResourcesUpload('dry run', false, 'sync files', false)`.
