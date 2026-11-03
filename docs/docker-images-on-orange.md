# Keeping PBRT Docker Images On Orange And Acorn

**Status: proposal, 2026-11-03. None of this has been carried out.** No folder has
been created on `/acorn`, no image has moved, and the Docker Hub subscription is
unchanged.

This note describes how to stop paying for Docker Hub by keeping the ISET3D PBRT
images at Stanford and documenting them in this repository.

## The Proposal In Brief

- `/acorn/data/iset/docker-images/` holds the permanent copy of every image, as a
  compressed archive.
- `orange` keeps the images it renders with in its own Docker storage.
- Other lab machines load the image they need from the archive over SSH.
- A catalog in this repository records what each image is and how it was built.
- The paid subscription ends last, after the archives have been tested.

Two questions need answers before the subscription ends: what people without an
`orange` account will use, and what Docker does with the `vistalab` organization's
public repositories after a downgrade. See
[People Without An Orange Account](#people-without-an-orange-account) and
[step 5](#step-5-end-the-paid-plan).

## Why Change

**The cost pays for seats, not storage.** The `vistalab` organization costs about
$1000 a year. Docker charges per user ($15 per user per month for Team, billed
annually), and its [pricing page](https://www.docker.com/pricing/) lists unlimited
public repositories on the free plan. All 34 repositories visible under `vistalab`
are public, although a public listing cannot show private ones. So moving the images
does not save money by itself. Ending the subscription does, and moving the images
first is what makes that safe.

**The current arrangement is fragile, whatever it costs:**

- **Some defaults cannot be downloaded.** `preset.m` names `vistalab/pbrt-v4-gpu`,
  which means `:latest`, but Docker Hub only has `:intel-cuda12.4`. The local preset
  in `dockerpresets.json` names `vistalab/pbrt-v4-cpu`, which has no Docker Hub
  repository at all. Those images exist only on `orange`, with no second copy.
- **The default CPU image is on a colleague's personal account.**
  `digitalprodev/pbrt-v4-cpu` crashes on CPUs without AVX-512. A fixed image exists,
  but we cannot publish it under that name.
- **Names do not describe contents.** `vistalab/pbrt-v4-cpu-intel` on Docker Hub
  requires AVX-512, so it crashes on Intel CPUs without it. `vistalab/pbrt-v4-cpu:latest`
  was a different image on `orange` than on the Intel iMac.
- **Nothing records how an image was made.** The PBRT commit has to be read from
  inside each image, and the build flags are not recorded at all.

## Design

| Location | Holds | Why |
| --- | --- | --- |
| `/acorn/data/iset/docker-images/` | An archive of every image | Permanent copy. `/acorn` has 9.9 TB free. |
| `orange`, `/var/lib/docker` | Images it renders with | Docker runs images from here. `/var` has 416 GB free. |
| Each lab laptop or desktop | The image it needs | Loaded from the archive. |
| This repository | Dockerfiles and the catalog | What each image is and how to rebuild it. |

Docker cannot run images directly from `/acorn`, because its `overlay2` storage does
not support NFS. So `/acorn` holds archives, and `orange` keeps a working copy.

Each archive's path follows the image name, so there is nothing to look up:

```text
/acorn/data/iset/docker-images/
    vistalab/pbrt-v4-cpu/
        2026-11-portable.tar.gz          the image
        2026-11-portable.tar.gz.sha256   checksum of the archive
        2026-11-portable.tar.gz.id       Docker image ID, to check after loading
```

Rules:

1. **Code and presets name an exact tag, never `latest`.** Each ISET3D commit then
   says which image it expects, and a name means the same thing on every machine.
2. **An archived tag is never replaced.** A new build gets a new tag with its date
   and purpose, such as `2026-11-portable`.
3. **Archive and catalog an image before any code names it.**
4. **Keep the `vistalab/` names.** The presets and `build_cpu.sh` already use them.

Render code does not need to change. `isetdocker.startPBRT` calls `docker run`, which
uses the image on the machine when the tag is present. If the tag is missing, Docker
looks on Docker Hub, which is one reason to keep the `vistalab` name reserved.

**Why not run a private registry on `orange`?** It would keep `docker pull` working,
but every client would need TLS or an `insecure-registries` setting, and someone would
have to keep the service and its open port running. For a few dozen images and a
handful of users, archives over SSH use the access people already have. Reconsider if
the number of users grows.

## Archive And Restore

To archive an image, paste this function into `bash` on `orange`. It can become a
script in `docker/build/` if the plan is adopted.

```bash
archive_image () {
  local img=$1
  local root=${IMAGE_ARCHIVE:-/acorn/data/iset/docker-images}
  case "$img" in *:*) ;; *) echo "Give an exact tag: $img"; return 1 ;; esac
  local file="$root/${img%:*}/${img##*:}.tar.gz"
  if [ -e "$file" ]; then echo "Already archived: $file"; return 1; fi
  mkdir -p "$(dirname "$file")" || return 1
  if ( set -o pipefail; docker save "$img" | pigz -1 > "$file.part" ) && pigz -t "$file.part"; then
    mv "$file.part" "$file"
    ( cd "$(dirname "$file")" && sha256sum "$(basename "$file")" > "$file.sha256" )
    docker image inspect "$img" --format '{{.Id}}' > "$file.id"
    chmod a-w "$file" "$file.sha256" "$file.id"
    echo "Archived: $file"
  else
    rm -f "$file.part"; echo "FAILED: $img"; return 1
  fi
}

archive_image vistalab/pbrt-v4-cpu:2026-11-portable
```

To restore an image, run this on the machine that needs it. The VPN is required off
campus.

```bash
A=/acorn/data/iset/docker-images/vistalab/pbrt-v4-cpu
ssh <user>@orange.stanford.edu "cat $A/2026-11-portable.tar.gz" | docker load

# These two must print the same ID.
docker image inspect vistalab/pbrt-v4-cpu:2026-11-portable --format '{{.Id}}'
ssh <user>@orange.stanford.edu "cat $A/2026-11-portable.tar.gz.id"
```

If the tag already exists on that machine, `docker load` moves it to the new image.
The earlier image stays on disk but shows as `<none>`.

**What was tested on 2026-11-03.** These commands ran with the 244 MB image
`nvidia/cuda:12.4.1-base-ubuntu22.04`, using a temporary folder on `orange`'s local
disk. The checksum passed, a repeat was refused, a missing image left no files, and
the image restored on an Intel iMac with the same ID and tag. They have not yet run
against `/acorn` or with a full-size image.

**Size.** In a separate check that wrote no file, `vistalab/pbrt-v4-cpu:x86_64` went
from 3.0 GB to 1.7 GB in about two minutes with `gzip -1` at low priority. Docker Hub
reports 67.5 GB for the 53 tags under `vistalab`, 37.8 GB of it PBRT. With the images
that exist only on `orange` or the iMac, the total should stay under 100 GB, about 1%
of the free space on `/acorn`.

## Current Inventory

This table, from 2026-11-03, can seed the catalog. "Hub" means Docker Hub.

| Image | Image ID | PBRT commit | Requires | Exists on |
| --- | --- | --- | --- | --- |
| `vistalab/pbrt-v4-cpu:portable` | `9b5e866b8d54` | `973480b` 2025-10-09 | No AVX-512. Tested only on an i9-9900K. | Intel iMac only |
| `vistalab/pbrt-v4-cpu:x86_64` | `49299f3fd124` | `973480b` 2025-10-09 | AVX-512 | `orange` only |
| `vistalab/pbrt-v4-cpu:latest` | `6ad05a2c0cca` | `fe436b7` 2025-08-14 | AVX-512 | `orange` only |
| `digitalprodev/pbrt-v4-cpu:latest`, also `vistalab/pbrt-v4-cpu-intel:latest` | `28857506ce5f` | `b73fe96` 2023-12-10 | AVX-512 | `orange`, Hub |
| `digitalprodev/pbrt-v4-cpu:test` | `d5c01e67ec73` | `a4f6332` 2023-12-15 | No AVX-512 | Intel iMac, Hub |
| `vistalab/pbrt-v4-cpu-oops:latest` | `0b337d109232` | `88827e5`, about 2021 | Fails on lens cameras | `orange` only |
| `vistalab/pbrt-v4-gpu:latest`, also `:test` | `709d051d85ea` | `db02147` 2024-03-21 | NVIDIA GPU | `orange` only |
| `vistalab/pbrt-v4-gpu:intel-cuda12.4` | `64908a0fa295` | `db02147` 2024-03-21 | NVIDIA GPU | `orange`, Hub |

The two GPU images have the same PBRT commit but different IDs, and nothing records
what differs between them.

These exist only on Docker Hub, so `orange` must pull them before archiving:

- `vistalab/pbrt-v4-cpu-arm`, `pbrt-v4-gpu-orange`, `pbrt-v4-gpu-ampere`, and
  `pbrt-v4-gpu-nv-550.120`.
- `vistalab/pbrt-v3-spectral`, with 13 tags. Code still names `latest`,
  `basisfunction`, `raytransfer`, `raytransfer-spectral`, and `raytransfer-ellipse`.
- `vistalab/pbrt` and `vistalab/pbrt-v2-spectral`.
- 25 non-PBRT repositories, 29.7 GB in all and mostly neuroimaging tools such as
  `freesurfer`, `fsl-v5.0`, and `rtppreproc`. They are not ISET3D's, but ending the
  subscription could affect them.

Images on other accounts, such as `digitalprodev/pbrt-v4-gpu-ampere-ti` and
`camerasimulation/pbrt-v4-gpu-ampere-cnidl`, do not depend on the `vistalab`
subscription. Archive any that the lab still uses, because we do not control them.

## Migration Steps

### Step 1: Check The Account

This step changes nothing. Sign in to Docker Hub as an owner of `vistalab` and note
the plan, the number of seats, the renewal date, and any private repositories. Also
find out whether `/acorn` is backed up.

### Step 2: Build The Archive

On `orange`, archive what is already there:

```bash
for img in \
  vistalab/pbrt-v4-cpu:x86_64 \
  vistalab/pbrt-v4-cpu:latest \
  digitalprodev/pbrt-v4-cpu:latest \
  vistalab/pbrt-v4-cpu-oops:latest \
  vistalab/pbrt-v4-gpu:latest \
  vistalab/pbrt-v4-gpu:intel-cuda12.4
do
  archive_image "$img"
done
```

Then archive what is only on Docker Hub. This example shows three of them, and the
others in the inventory follow the same pattern:

```bash
for img in \
  digitalprodev/pbrt-v4-cpu:test \
  vistalab/pbrt-v4-gpu-orange:latest \
  vistalab/pbrt-v3-spectral:basisfunction
do
  docker pull "$img" && archive_image "$img" && docker rmi "$img"
done

# The ARM image needs its platform named.
docker pull --platform linux/arm64 vistalab/pbrt-v4-cpu-arm:latest
archive_image vistalab/pbrt-v4-cpu-arm:latest
docker rmi vistalab/pbrt-v4-cpu-arm:latest
```

Copy the portable image from the Intel iMac to `orange` under its permanent tag, then
archive it on `orange`:

```bash
# On the iMac
docker tag vistalab/pbrt-v4-cpu:portable vistalab/pbrt-v4-cpu:2026-11-portable
docker save vistalab/pbrt-v4-cpu:2026-11-portable | gzip -1 | ssh <user>@orange.stanford.edu docker load
```

Finally, check every archive on `orange`:

```bash
cd /acorn/data/iset/docker-images
find . -name '*.sha256' -execdir sha256sum -c {} \;
```

### Step 3: Test What Was Archived

- Restore the portable image on another machine and compare its ID. Run the
  `t_piIntro_chess` and `t_piIntro_lens` tutorials and `iset3dUnitTest('full')`.
- Render with the portable image on `orange`'s Xeon, where it has never run.
- Load one GPU archive on a second machine and compare its ID, to confirm that a large
  archive survives the round trip.

### Step 4: Change ISET3D

- **Define the default CPU image in one place.** It is hard-coded in
  `human/@sceneEye/piWRS.m`, `human/@sceneEye/render.m`, `utilities/piLabel.m`,
  `docker/@isetdocker/preset.m`, and `docker/@isetdocker/setUserPrefs.m`. Update
  `human/_tests_/test_sceneEyePiWRS.m` to match.
- **Use exact tags in `dockerpresets.json` and `preset.m`.** Replace
  `vistalab/pbrt-v4-cpu-intel`.
- **Choose CPU images by machine.** `orange` can keep the native build, because the
  portable image rendered about 20% slower on the iMac than `digitalprodev/pbrt-v4-cpu:test`,
  a build that has no AVX-512 either. Other machines use the portable image.
- **Report a missing image.** `piDockerDiagnose` should check that the image is present
  and print the restore command. Today this surfaces only as a failure at the first
  render.
- **Rewrite the install instructions** that say `docker pull`: `docs/setting-up-iset3d.md`,
  `docs/returning-to-iset3d.md`, the `iset3d-docker-rendering` skill, and the wiki pages
  `Local-rendering.md` and `Getting-Started.md`. In the other repositories searched, the
  only reference is a comment in `isetlens/examples/s_lensFocus.m`.
- **Leave old names working during the transition.** People's saved MATLAB preferences
  will still name `digitalprodev/pbrt-v4-cpu`, and it will keep working for those whose
  CPUs support it.

Renders from a new default image will not match earlier ones pixel for pixel. Compare
numbers only between renders from the same image, and review any golden values that
depend on the default.

### Step 5: End The Paid Plan

Do this last, after the archive has been tested, step 4 has been merged, and
collaborators have been told.

- **Downgrade, do not deactivate.**
  [Deactivation](https://docs.docker.com/docker-hub/deactivate-account/) is permanent.
  Docker [says](https://docs.docker.com/accounts/general-faqs/) Docker IDs cannot be
  reused but does not say the same for organization names. If someone else could
  register `vistalab`, a machine missing a tag could run that person's image.
- **Ask Docker first what happens to the public repositories.** Its documentation
  mentions downgrading to "a basic organization account", but the pages checked do not
  say whether public images stay available. The pricing page lists organizations only
  under Team and Business.
- **Convert or archive any private repositories.** Older Docker documentation requires
  this before a downgrade.
- **Time it near the renewal date.** Older Docker documentation says a mid-cycle
  downgrade is not refunded.

If public images would not survive a downgrade and people still need them, removing
unused seats may be a cheaper interim step. Check Docker's minimum seat count.

## People Without An Orange Account

The archive is available only to people who can reach `orange`. The `iset` group has
seven members. But `docs/setting-up-iset3d.md` and the wiki tell anyone to run `docker
pull`, and this repository treats local rendering as the priority. This is the one
place where the proposal takes something away from outside users, so it needs a
decision.

| Option | Cost | What the person does |
| --- | --- | --- |
| **Public copy of the CPU image on GitHub Container Registry**, as `ghcr.io/iset/pbrt-v4-cpu` | [Free for public images](https://docs.github.com/en/billing/concepts/product-billing/github-packages), with one month's notice of any change | `docker pull`, as now |
| **Build the image** with `docker/build/cpu/build_cpu.sh` | Free | Waits about 15 minutes (measured on an Intel iMac). The result uses current PBRT, so it may differ from the archived image. |
| **Give the person an `orange` account** | Free | Uses the VPN and restores from the archive. Suits close collaborators only. |
| **Rely on what remains on Docker Hub** | Free, if the images survive step 5 | Pulls the old image, which crashes without AVX-512 |

**Recommendation: publish the portable CPU image on GitHub Container Registry, and
document the build as the fallback.** `/acorn` stays the permanent copy, and the public
copy could be dropped at any time without losing anything. GPU images do not need a
public copy, since Macs cannot use them and outside GPU users can build their own.

## Better Documentation

Create `docs/pbrt-images.md` as the catalog, starting from the
[inventory](#current-inventory) above, with one entry per image:

- Image name and tag, and image ID.
- PBRT repository and commit, Dockerfile, and build flags.
- CPU or GPU requirement, including the NVIDIA driver for GPU images.
- Where it was tested, when, and with which tests.
- Which presets use it, and any known problems.

Two commands fill in most of this. Any `zmm` count above zero means the image needs
AVX-512. For this note, the first command ran on the `orange` images in the inventory,
and the second ran only on the portable image.

```bash
docker run --rm --entrypoint sh IMAGE -c 'cd /pbrt/pbrt-v4 && git log -1 --format="%h %cs"'
docker run --rm --entrypoint sh IMAGE -c 'objdump -d /pbrt/pbrt-v4/build/pbrt | grep -c zmm'
```

Build changes that would make the catalog easier to keep:

- **Pin the PBRT commit.** `Dockerfile_cpu` and `Dockerfile_gpu` clone the current head,
  so the same recipe gives different images over time. A `PBRT_COMMIT` build argument
  would fix that.
- **Label each image** with its commit and flags at build time, so `docker image
  inspect` can report them.
- **Retire old recipes once confirmed unused.** `docker/build/gpu/Dockerfile_ampere`
  and `Dockerfile_volta` clone a different repository, `scienstanford/pbrt-v4`.
  `docker/build/Dockerfile.ampere` and `Dockerfile.volta` also look superseded.
- **Add the new folder to `/acorn/data/iset/Notes.txt`**, with a pointer to the catalog.

When this plan is adopted, update the `iset3d-docker-rendering` and
`iset3d-session-startup` skills along with the docs.

## Open Questions

1. **Is `/acorn` backed up?** No snapshot folder was visible. If it is not backed up, the
   archive and `orange` are the only copies of some images, both at Stanford.
2. **Does anyone still use the non-PBRT `vistalab` images?** Several people have pushed
   to that organization over the years.
3. **What should people without an `orange` account use?** See
   [above](#people-without-an-orange-account).
4. **Are `mux`, `muxreconrt`, and `cni-dl` still in use?** The presets name them, and
   none answered on the SSH port from the iMac on 2026-11-03. If they are retired, the
   presets can go. If not, they need images too.
5. **Which GPU image is the default?** `preset.m` and `dockerpresets.json` disagree, and
   the two images have different IDs.

## Related

- [returning-to-iset3d.md](returning-to-iset3d.md): startup checks and preferences.
- [setting-up-iset3d.md](setting-up-iset3d.md): local rendering setup.
- [remote-rendering.md](remote-rendering.md): `orange`, `/acorn`, and file staging.
