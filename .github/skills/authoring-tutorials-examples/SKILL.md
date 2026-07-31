---
name: authoring-tutorials-examples
description: Use when adding, editing, or deciding where to place a file in the ISET3D tutorials/ or examples/ directories, when naming a new t_*.m, s_*.m, or data_*.m script, when deciding whether a script needs the % SkipFile marker, when placing something under underDevelopment/, or when asked about the difference between a tutorial and an example in ISET3D.
---

# Authoring ISET3D Tutorials And Examples

ISET3D keeps `tutorials/` and `examples/` as separate teaching surfaces for
different goals and audiences. Preserve the distinction when adding or editing
files.

## Tutorials (`tutorials/`, `t_*.m`)

- **Audience:** learners, including new students, who can program and are
  learning image systems engineering and the ISET3D/PBRT rendering pipeline.
- **Purpose:** short, heavily commented introductions to key objects and APIs.
- **Content:** object creation and setup; `*Get`/`*Set` usage for key
  properties; basic visualization (`*Window`, `*Plot`); one simple quantitative
  computation or checkpoint.
- **Behavior:** runs relatively quickly and reads linearly.

Topic folders: `introduction`, `assets`, `camera`, `lens`, `lights`,
`materials`, `scene`, `sceneEye`, `skymap`. The `introduction` folder is the
intended first path.

## Examples (`examples/`, `s_*.m`)

- **Audience:** users looking for realistic analysis patterns to adapt.
- **Purpose:** applied workflows and more advanced computations.
- **Content:** end-to-end numerical analyses or visualization workflows;
  realistic parameter choices and tradeoff exploration; code users can copy as
  a starting point.
- **Behavior:** may be longer and more detailed than a tutorial.

If the content is mainly onboarding and API orientation, it belongs in
`tutorials/`. If it is mainly applied workflow, analysis, or deeper
exploration, it belongs in `examples/`.

## Render Cost Is A First-Class Concern

This is what differs most from ISETCam authoring. Every rendering script pays
for a PBRT run, and on macOS that is CPU-only and often emulated.

- **Keep film resolution and rays per pixel small.** A tutorial that renders at
  `[160 160]` with 32 rays per pixel and 2 bounces teaches the same thing as
  one at `[640 640]` with 512 rays, and finishes fast enough to actually be run.
- Raise quality only where the *point* of the script is image quality.
- Prefer scenes that are cheap to obtain — synthetic builders and the small
  ISET3D scenes — over the large bitterli/pbrtv4 imports. See the
  `iset3d-scene-sources` skill.
- `piWRS(...,'speed',N)` reduces resolution, bounces, and rays for a quick
  geometry check without editing the recipe.

## Data-Generation Scripts (`data_*.m`)

Some scripts exist to generate or refresh repository data files rather than to
teach. Name these `data_*.m`. The name distinguishes them from the automated
tutorial (`t_*`) and example (`s_*`) smoke-test sources discovered by the
runners, and makes their side-effecting purpose explicit.

Existing examples: `data/assets/data_assetsRecipe.m`,
`data/scenes/cornellbox/data_cbBoxCreate.m`,
`examples/text/data_characterToAsset.m`.

## `underDevelopment/` Subfolders

Many example topic folders contain an `underDevelopment/` subfolder. Scripts
there are exploratory: they may not run, may depend on unavailable resources,
or may encode an approach that has not settled.

- Treat them as **notes, not first-copy templates**. Do not point a new user at
  one.
- When adding an exploratory script, put it in `underDevelopment/` rather than
  marking a top-level script `% SkipFile`.
- Promoting a script out of `underDevelopment/` means it should run cleanly in
  the automated suite.

## Excluding A File From Automated Runs

`iset3dTutorialTest` and `iset3dExampleTest` execute every `t_*` and `s_*` file
by default. To opt one out, add this exact comment on its own line:

```matlab
% SkipFile
```

**You do not need this merely because a script renders.** ISET3D supplies
`iset3dRenderSkipReason` as the runners' conditional-skip hook: it detects
`piWRS`, `piRender`, `eyeRender`, and `thisSE.render` and reports the file as
`Skipped` with a reason when no renderer is configured. Docker-dependent
scripts already skip themselves cleanly.

Reserve `% SkipFile` for scripts that need unavailable external data or
toolboxes, deliberate user interaction, unusually expensive computation, or
that have a known failure documented nearby. Remove the tag once the file is
suitable for routine automated execution.

The legacy `% UTTBSkip` marker is still recognized for compatibility, but no
file in the repository uses it any more — new and updated files should use
`% SkipFile`.

See the `iset3d-testing-workflow` skill for the full marker contract and the
runner behavior.

## Student Contributors

Prioritize clarity, reproducibility, and instructional value: clear comments,
stable outputs, and explicit links to related wiki pages, tests, and nearby
tutorials or examples. A script that produces the same numbers on the next run
is worth more than one that produces prettier pictures.

## Reviewing Existing Scripts

To review scripts for runnability, comment quality, overlap, and coverage
against nearby `_tests_` directories, use the existing `matlab-script-review`
agent (`.github/agents/matlab-script-review.agent.md`) rather than re-deriving
that workflow.

## Publishing

To turn a tutorial or example into linkable HTML, see the
`publishing-tutorials-examples` skill.

## Adding A Skill (Not A Tutorial)

Skills are agent instructions, not teaching scripts, but the placement rule is
just as easy to get wrong. Canonical files go in
`.github/skills/<name>/SKILL.md`; Claude Code reads them through the directory
symlink `.claude/skills -> ../.github/skills`. Nothing else is needed — a new
skill appears on both sides automatically. See the Skills section of
`.github/copilot-instructions.md`.

## Related

- `iset3d-testing-workflow` — running what you wrote.
- `iset3d-scene-sources` — choosing a cheap, reproducible scene.
- `iset3d-recipe-workflow` — the API a tutorial should demonstrate.
