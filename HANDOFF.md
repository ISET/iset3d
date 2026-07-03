# ISET3D Tutorial and Example Handoff

Date: 2026-07-03

This handoff records the current tutorial-pruning state and the next useful
work items for another machine or another AI session.

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

The tutorial surface has been pruned conservatively.

Current quick counts after the most recent moves:

- `tutorials/t_*.m`: 68
- `examples/s_*.m`: 86

The last completed tutorial smoke run was before the most recent move from
`tutorials/` to `examples/`, so its planned-script count is now stale. That run
completed here:

- `local/2026-07-03_080941_iset3dTutorialTest/progress.log`
- `local/2026-07-03_080941_iset3dTutorialTest/checkpoint.mat`

Its runner summary was:

- Total planned: 81
- Passed: 29
- Failed: 32
- Skipped: 20
- Completed: 81
- Unfinished: 0

Run a fresh `iset3dTutorialTest` before planning detailed fixes.

## Completed Tutorial Pruning

The following high-confidence duplicate, obsolete, or scratch tutorial files
were deleted:

```text
tutorials/camera/t_cameraMotionMMP.m
tutorials/lens/t_piMicrolens.m
tutorials/lights/t_arealightAdditivity.m
tutorials/lights/t_arealightRotate.m
tutorials/lights/t_arealightView.m
tutorials/lights/t_piLightType.m
tutorials/materials/t_materials_properties.m
tutorials/sceneEye/t_eyeScratch.m
tutorials/sceneEye/t_rayTracingIntroduction.m
tutorials/sceneEye/t_eyePupilDiameter.m
tutorials/sceneEye/t_mmPerDeg.m
tutorials/sceneEye/t_eyeSceneExamples.m
```

All `t_*.m` scripts under these `underDevelopment` directories were retained
and marked with `% SkipFile`:

```text
tutorials/sceneEye/analysis/underDevelopment/
tutorials/sceneEye/cloud/underDevelopment/
```

The relevant files are:

```text
tutorials/sceneEye/analysis/underDevelopment/t_PSFoverDefocus.m
tutorials/sceneEye/analysis/underDevelopment/t_PSFoverEcc.m
tutorials/sceneEye/analysis/underDevelopment/t_accommodationMTF_cloud.m
tutorials/sceneEye/analysis/underDevelopment/t_accommodationMTF_fineTune_cloud.m
tutorials/sceneEye/analysis/underDevelopment/t_comparePSF.m
tutorials/sceneEye/analysis/underDevelopment/t_defocus_cloud.m
tutorials/sceneEye/analysis/underDevelopment/t_eccentricity.m
tutorials/sceneEye/cloud/underDevelopment/t_LCA_cloud.m
tutorials/sceneEye/cloud/underDevelopment/t_accommodation_cloud.m
tutorials/sceneEye/cloud/underDevelopment/t_chessSet_cloud.m
tutorials/sceneEye/cloud/underDevelopment/t_eyeDoF_cloud.m
tutorials/sceneEye/cloud/underDevelopment/t_eyePupilDiameter_cloud.m
tutorials/sceneEye/cloud/underDevelopment/t_schematicEyeModels_cloud.m
tutorials/sceneEye/cloud/underDevelopment/t_vergenceAccomm_cloud.m
```

## Completed Tutorial-to-Example Moves

These files were moved from `tutorials/` to `examples/` and renamed from
`t_*.m` to `s_*.m` because they are applied workflows rather than short
tutorials:

```text
tutorials/sceneEye/t_renderAllScenes.m      -> examples/scenes/s_renderAllScenes.m
tutorials/sceneEye/t_planarImage.m          -> examples/scenes/s_planarImage.m
tutorials/sceneEye/t_eyeCrop2Cones.m        -> examples/metrics/s_eyeCrop2Cones.m
tutorials/sceneEye/t_slantedBarMTF.m        -> examples/metrics/s_slantedBarMTF.m
tutorials/characters/t_textRender.m         -> examples/text/s_textRenderCharacters.m
tutorials/media/t_absorptionExample.m       -> examples/physics/s_absorptionExample.m
tutorials/media/t_scatteringExample.m       -> examples/physics/s_scatteringExample.m
tutorials/lights/t_lightProjection.m        -> examples/arealights/s_lightProjection.m
tutorials/lights/t_lightHeadlamp.m          -> examples/arealights/s_lightHeadlamp.m
```

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

## Next Step: Fix Remaining Tutorials

Run a fresh tutorial smoke pass:

```matlab
addpath(genpath(pwd));
run = iset3dTutorialTest;
ieTestReport(run,'List',{'failed','skipped'});
```

Then work through the failing `t_*.m` files. The goal is not only to make them
pass, but to simplify them:

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

