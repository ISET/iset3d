# ISET3D AI Instructions

Shared startup guidance for Copilot, Claude, Codex, Gemini, and other AI coding
assistants working in this repository.

This file is a **router**. It carries repository-wide context and coding rules;
the operational depth lives in `.github/skills/`. Read the skill that matches
the task before making changes.

## Repository Context

- MATLAB is the primary runtime.
- The main repository is `iset3d`. **ISETCam (`../isetcam`) is a required
  dependency** and is always expected to be on the MATLAB path when ISET3D is
  used or tested.
- ISET3D code and tests may use ISETCam utilities directly, including `ieInit`,
  `ieTestReport`, `ieWebGet`, and `iePublish`. **Do not duplicate a utility
  ISETCam already supplies.**
- **Many independently maintained repositories depend on ISET3D.** Before
  removing or changing public APIs, paths, data locations, setup behavior, or
  integration hooks, search for likely external usage and prefer staged
  deprecation when an immediate change could disrupt collaborators. Allow time
  for dependent repositories to migrate unless coordinated cleanup is
  explicitly requested.
- Rendering happens in PBRT inside Docker. MATLAB writes scene files, invokes
  the container, and reads the result back. **Local rendering is the default
  and the priority**; remote rendering on Stanford hosts is an option, not a
  requirement.

## Skills

Read the matching `SKILL.md` under `.github/skills/` before working in that
area.

**Where they live.** The canonical files are in `.github/skills/<name>/SKILL.md`,
which is where Copilot, Codex, and Gemini look. Claude Code discovers skills only
in `.claude/skills/`, so the whole directory is symlinked:

```text
.claude/skills -> ../.github/skills
```

One symlink per repository, not one per skill. **Adding a skill therefore needs
no bookkeeping** — create `.github/skills/<name>/SKILL.md` with `name` and
`description` frontmatter and it appears on both sides automatically. The same
one-line arrangement is used in ISETCam, ISETBio, SDM, and OralEye.

Link the directory, never the individual skills. A directory of per-skill
symlinks enumerates as symlinks rather than directories, which any tool
filtering on "is a directory" will skip.

Write the `description` as a trigger list — the situations and function names
that should make an agent open the file — not as a summary. That text is the
only thing a tool sees before deciding to read the skill.

On Windows, `git config core.symlinks true` (plus Developer Mode) is needed for
`.claude/skills` to check out as a real symlink. Without it, it arrives as a
small text file and Claude Code will not see the skills; the canonical
`.github/skills/` tree is unaffected and remains readable.

### Core workflow

| Skill | Read it when |
| --- | --- |
| `iset3d-recipe-workflow` | Creating, loading, inspecting, or editing a recipe; `piWRS`/`piWrite`/`piRender`; looking up a `thisR.get`/`set` parameter name; render quality settings; deciding whether a render returns a `scene` or an `oi`. |
| `iset3d-docker-rendering` | Setting up rendering on a new machine; `ISETDocker` preferences; local CPU or GPU config; a render that fails before PBRT produces output; `piDockerConfig`, `piDockerDiagnose`, stale `PBRTContainer`. |
| `iset3d-scene-sources` | Finding or downloading a scene; in-repo vs. SDR vs. database scenes; `ieWebGet`, `piSDRSceneNames`, `piDirGet`; building a synthetic target. |
| `iset3d-testing-workflow` | Running or choosing tests; `iset3dUnitTest` core vs. full; area runners; `iset3dTutorialTest`/`iset3dExampleTest`; the `_remote` and `FullOnly` conventions; `% SkipFile`; `ieTestReport`. |

### Editing scene content

| Skill | Read it when |
| --- | --- |
| `iset3d-lights-and-skymaps` | Adding, deleting, or editing lights; light types; spectra (named illuminant, blackbody K, RGB); `specscale`; `cameracoordinate`; area lights; setting and rotating a skymap. |
| `iset3d-materials-and-textures` | Creating, editing, or assigning materials; `piMaterialPresets`; procedural vs. image-map textures; a PBRT "file not found" error naming a texture. |
| `iset3d-assets-and-transforms` | Navigating or editing the asset tree; `piAssetSearch`; translate/rotate/scale; world vs. local coordinates; object instances; asset motion. |

### Optics

| Skill | Read it when |
| --- | --- |
| `iset3d-camera-and-optics` | Camera setup; `piCameraCreate`; camera subtypes; attaching a lens file; focus distance and accommodation; film size and resolution; camera motion; microlens and film shape. |
| `iset3d-sceneEye` | Human-eye rendering; the navarro, arizona, and legrand models; accommodation; retinal geometry; why `sceneEye` renders on the CPU. |
| `iset3d-lens-toolbox` | The imported ISETLENS code — `lensC`, `rayC`, `surfaceC`, `filmC`, `psfCameraC`; `lensFocus`; paraxial matrix optics; black box model; MTF via `piCalculateSlantedEdgeMTF`. |

### Infrastructure and process

| Skill | Read it when |
| --- | --- |
| `iset3d-remote-resources-database` | Remote rendering; rsync scene staging; the `/acorn` `PBRTResources` tree; `thisR.useDB`; `isetdb` Mongo metadata; `piTextureResourcesUpload`; SSH tunnels. |
| `matlab-environment-setup` | Setting up or troubleshooting a MATLAB session; repository paths; `which ieInit` failing; the VS Code MATLAB extension; `-batch` from a shell. |
| `authoring-tutorials-examples` | Adding or placing a file in `tutorials/` or `examples/`; naming a `t_*.m`, `s_*.m`, or `data_*.m`; `% SkipFile`; `underDevelopment/`. |
| `golden-value-testing` | Adding or updating a numerical regression test; tolerance choice; golden storage; `test_<subject>Golden_remote.m`; updating a baseline. |
| `publishing-tutorials-examples` | Converting a tutorial or example to self-contained HTML; `iePublish`, `s_publishTutorials`, `s_publishExamples`. |

## Agents

`.github/agents/` holds read-only review and diagnosis agents:

- `matlab-script-review.agent.md` — review tutorials and examples for
  runnability, comment quality, overlap, and coverage against nearby `_tests_`
  directories.
- `render-failure-triage.agent.md` — walk a failing render through the whole
  chain (Docker → write → staging → upload → PBRT) and report where it broke.

## ISETCam Pipeline

Prefer existing object-specific functions before writing new utilities.

1. Scene: `scene*` functions, accessed with `sceneGet` and `sceneSet`.
2. Optical image: `oi*` functions, accessed with `oiGet` and `oiSet`.
3. Sensor: `sensor*` functions, accessed with `sensorGet` and `sensorSet`.
4. Image processing: `ip*` functions, accessed with `ipGet` and `ipSet`.
5. Display: `display*` functions, accessed with `displayGet` and `displaySet`.

Common constructors and compute functions: `sceneCreate`, `oiCreate`,
`oiCompute`, `sensorCreate`, `sensorCompute`, `ipCreate`, `ipCompute`,
`displayCreate`.

For diagnostics, prefer existing plotting functions — `scenePlot`, `oiPlot`,
`sensorPlot`, `ipPlot`, `displayPlot`, `piMaterialPlot` — over ad hoc plotting.

## Search Guidance

- Use `rg` for text search and `fd` for filename/path search in a terminal.
- Before adding behavior, search for nearby examples with the relevant object
  prefix (`piAsset*`, `piLight*`, `piMaterial*`, `piTexture*`, `piCamera*`).
- **Do not guess a `thisR.get`/`set` parameter name.** Grep the case lists:
  `rg "^    case" @recipe/recipeGet.m`. Names are normalized by `ieParamFormat`,
  and most cases carry several aliases.
- For color transforms and color science, search ISETCam's `color/` before
  writing new code.
- For scene patterns and chart behavior, check `utilities/scenes/` and the
  existing `piCreate*` builders.

## Coding Style

- Keep edits minimal and consistent with existing MATLAB style.
- Reuse established constructors, getters, setters, plotting helpers, and
  object naming conventions.
- Prefer vectorized MATLAB where it improves clarity or performance.
- Update function header comments when behavior changes, especially `Syntax`,
  `Inputs`, `Returns`, and `See also`.
- Do not add dependencies unless necessary and consistent with the repository.
- Distance units are meters in recipes and **millimeters** in the lens toolbox.
  Rotations are degrees, ordered `[x y z]`.

## Validation

- Validate modified files with MATLAB diagnostics or focused test commands when
  practical.
- Place tests in colocated `_tests_` directories. Use ISETCam's `_tests_`
  directories as the reference when an ISET3D convention is not established.
- Write function-based tests named `test_<subject>.m`, starting with
  `tests = functiontests(localfunctions)`.
- **Any test that calls a Docker-dependent render path must include `_remote`
  in its filename.** `iset3dUnitTest('core')` excludes `_remote` and `FullOnly`
  so the fast suite runs without network or Docker.
- Run the full suite with `iset3dUnitTest` and report with `ieTestReport`.
  `iset3dUnitTest` is the ISET3D master runner; `ieUnitTest` is ISETCam's.
- Keep core tests deterministic and non-interactive; control the RNG when
  randomness is required.
- Local and repository-wide runners must close figures created during testing
  while preserving figures open beforehand.
- MATLAB is available through the VS Code extension, and at
  `/Applications/MATLAB_R2025b.app/bin/matlab` with `-batch` for
  non-interactive checks. If launching from a sandboxed shell fails silently or
  exits with status 1, retry unsandboxed — MATLAB may need to write preferences
  outside the repository.

See the `iset3d-testing-workflow` and `golden-value-testing` skills for detail.

## Documentation

Long-form prose for humans lives in `docs/`:

- [iset3d-introduction.md](../docs/iset3d-introduction.md) — first tutorial path
  and core workflow.
- [setting-up-iset3d.md](../docs/setting-up-iset3d.md) — local rendering setup.
- [remote-rendering.md](../docs/remote-rendering.md) and
  [rendering-database.md](../docs/rendering-database.md) — remote hosts, shared
  resources, and the database.
- [testing.md](../docs/testing.md) — test runners.
- [sceneEye-gpu.md](../docs/sceneEye-gpu.md) — why human-eye optics is CPU-only.
- [golden-value-testing.md](../docs/golden-value-testing.md) — the golden value
  target list and plan.

Skills distill these into operational guidance and link back. When a fact
changes, update the skill and the doc together.

## When Uncertain

Choose the simplest implementation that matches existing `pi*` and ISETCam
`scene*`/`oi*`/`sensor*`/`ip*`/`display*` patterns. Ask the user only when the
choice would materially affect behavior, API shape, or test expectations.
