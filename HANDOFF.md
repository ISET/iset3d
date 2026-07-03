# ISET3D Tutorial and Example Handoff

Date: 2026-07-03

This handoff records the current tutorial state and the next useful work items
for another machine or another AI session.

## Repository Guidance

Before editing in this repository, read:

- `AGENTS.md`
- `.github/copilot-instructions.md`

The important distinction for this work:

- `tutorials/` should contain short learner-facing API/onboarding scripts.
- `examples/` should contain applied workflows, deeper analyses, and scripts
  users may adapt for their own work.
- Automated tutorial files are named `t_*.m`.
- Automated example files are named `s_*.m`.
- Add `% SkipFile` to a script that should be retained but skipped by the
  tutorial/example smoke runners.

## Current State

The tutorial smoke suite is currently green after pruning, skipping unsuitable
scripts, and shortening the heaviest passing tutorials.

Latest completed tutorial smoke run:

- `local/2026-07-03_142417_iset3dTutorialTest/progress.log`
- Total planned: 74
- Passed: 33
- Failed: 0
- Skipped: 41
- Completed: 74
- Unfinished: 0

The major tutorial cleanup work already completed in this session includes:

- Fixing the runnable failures that were blocking the smoke suite.
- Adding `% SkipFile` markers to tutorials that are obsolete, interactive,
  under-development, or dependent on unavailable toolboxes/APIs.
- Shortening compute-heavy passing tutorials so most do a single low-cost
  render or no render when rendering is not the point.
- Adding `docker/piDockerWarmup.m` and
  `docker/_tests_/test_piDockerWarmup.m` for opt-in remote PBRT container
  warm-up from a user's `startup.m`.

Do not re-open completed tutorial-failure cleanup unless a fresh smoke run
shows a regression.

## User-Intentional Live Script Conversion

Some `.mlx` files were converted by the user to `.m` files because the project
is moving away from live scripts. Treat those changes as intentional user work.
Do not restore the `.mlx` files unless explicitly asked.

At the time of review, these remaining `.mlx` files existed:

```text
tutorials/assets/t_assets.mlx
tutorials/camera/t_cameraDPAF.mlx
tutorials/camera/t_cameraLightField.mlx
tutorials/introduction/t_piIntro.mlx
tutorials/lens/t_lensFisheye.mlx
tutorials/lens/t_lensesView.mlx
```

Only `tutorials/camera/t_cameraDPAF.mlx` was found to contain embedded media
when inspected as a zip archive; it included `media/image1.png`.

## Saving Images When Converting `.mlx` to `.m`

Plain MATLAB `.m` files cannot embed images the way `.mlx` live scripts can.
When converting a live script that contains explanatory images:

1. Keep the `.mlx` until the extracted images are safely stored in the repo.
2. Inspect the live script as a zip archive:

   ```sh
   unzip -l tutorials/camera/t_cameraDPAF.mlx
   ```

3. Extract embedded media into a stable sibling image directory, for example:

   ```text
   tutorials/camera/images/t_cameraDPAF/image1.png
   ```

4. In the converted `.m` tutorial, reference the image using MATLAB publish
   markup so `iePublish`/`publish` can include it in generated HTML:

   ```matlab
   %% Dual-pixel autofocus geometry
   %
   % <<images/t_cameraDPAF/image1.png>>
   %
   % The image above illustrates ...
   ```

5. Run the publishing path on that file and inspect the generated HTML:

   ```matlab
   iePublish('tutorials/camera/t_cameraDPAF.m')
   ```

The key point: "Save As MATLAB Code" may preserve executable code and comments,
but it should not be trusted to preserve embedded live-script images. Extract
the images explicitly and reference them from the `.m` file.

## Next Step: Fix `sceneEye`

The current `tutorials/sceneEye/t_eyeNavarro.m` change is intentionally only a
tutorial-level workaround.  It keeps the reliable first pinhole render and then
writes the Navarro accommodation lens files for A/B/C, but it does not fix the
underlying `sceneEye` optical rendering path.

The underlying problem remains: `sceneEye` optical renders with Navarro optics
do not work correctly through the current `isetdocker` path.  The previous
tutorial called:

```matlab
thisSE.piWRS('docker',isetdocker,'name','navarro-A');
```

for the later optical renders.  Those renders were not correct.  The comments
in the script already indicated that the human-eye case used to require
`dockerWrapper.humanEyeDocker` and that `isetdocker` still needs work for this
case.

For the next round, investigate and fix the `sceneEye` rendering code rather
than further masking the tutorial.  Useful files to inspect:

```text
human/@sceneEye/piWRS.m
human/@sceneEye/render.m
human/@sceneEye/write.m
human/@sceneEye/setOI.m
human/models/navarroWrite.m
human/accommodation/setNavarroAccommodation.m
utilities/piWrite.m
utilities/piRender.m
docker/@isetdocker/isetdocker.m
```

Likely issues to check:

- `sceneEye.piWRS` calls `piWrite(thisR)` directly and may bypass important
  `sceneEye.write` state handling.
- The current `isetdocker` path may not be equivalent to the old
  `dockerWrapper.humanEyeDocker` behavior for human-eye optical renders.
- The script had repeated names (`navarro-A`) for B/C cases; that script bug
  is fixed, but the renderer problem is not.
- Add a targeted regression test once the renderer path is fixed.

Start with a fresh tutorial smoke pass only if you need a baseline or after
changing shared render code:

```matlab
addpath(genpath(pwd));
run = iset3dTutorialTest;
ieTestReport(run,'List',{'failed','skipped'});
```

If that run shows regressions, keep the same tutorial standards:

- Keep tutorials short and readable.
- Prefer one clear object/API lesson per tutorial.
- Remove long parameter sweeps and expensive render loops.
- Use stable small scenes and low sample counts where possible.
- Prefer existing ISET3D/ISETCam helpers over local ad hoc utilities.
- If a file is valuable but inherently slow, interactive, machine-dependent,
  or remote-render dependent, add `% SkipFile` with a nearby comment explaining
  why.
- If a script is really an applied workflow, move it to `examples/` and rename
  it from `t_*.m` to `s_*.m`.

For remote-render failures, first check the machine-specific Docker/PBRT setup:

```matlab
piDockerDiagnose('render',false)
```

Use `piDockerDiagnose('render',true)` only when a tiny acceptance render is
needed.

## Later Step: Consider Merging `isetlens`

Consider whether the separate `isetlens` repository should be merged into this
repository.  The tutorials and optics workflows use lens functionality often,
and `isetlens` appears to contain educational material that would fit naturally
with ISET3d.

Questions for that design pass:

- How often do tutorials/examples require `isetlens` today?
- Which `isetlens` educational scripts should become ISET3d tutorials or
  examples?
- Should `isetlens` become a subfolder/module inside this repo, or should only
  selected functions and tutorials be migrated?
- What path/startup changes would be required for users and CI?
- Are there naming conflicts, duplicate utilities, or dependency cycles between
  ISET3d, ISETCam, and ISETLens?

## Later Step: Reduce and Fix Examples

After the tutorial set is clean and fast, repeat the process for examples:

1. Run `iset3dExampleTest`.
2. Report failures and skips with `ieTestReport`.
3. Delete true duplicates or obsolete scripts.
4. Move data-generation scripts to `data_*.m` names when appropriate.
5. Simplify example scripts where possible, but allow examples to remain more
   workflow-oriented than tutorials.

## Notes for the Next AI Session

- Do not revert user changes unless explicitly asked.
- The worktree may be dirty because files were intentionally deleted, moved,
  or converted.
- Use `rg`/`find` for fast inspection.
- Use `apply_patch` for manual file edits.
- MATLAB is available at:

  ```text
  /Applications/MATLAB_R2025b.app/bin/matlab
  ```

- A useful non-interactive tutorial run command is:

  ```sh
  /Applications/MATLAB_R2025b.app/bin/matlab -batch "addpath(genpath(pwd)); run = iset3dTutorialTest; ieTestReport(run,'List',{'failed','skipped'});"
  ```
