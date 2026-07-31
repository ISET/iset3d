---
name: iset3d-testing-workflow
description: Use when running or choosing ISET3D tests after a code change — iset3dUnitTest core vs full, the area runners like utilitiesUnitTest or assetUnitTest, iset3dTutorialTest and iset3dExampleTest with selection or start, the _remote and FullOnly filename conventions, the % SkipFile marker, ieTestReport, or diagnosing a failing or interrupted run.
---

# Testing ISET3D

This is for developers who have changed ISET3D and want to check that they have
not broken existing behavior. Most users never run these.

ISETCam must be on the MATLAB path. The runners will add a sibling
`../isetcam` automatically if the shared engine is missing, but a properly set
up session is better. A clean MATLAB session is recommended for tutorial and
example tests, because those runners call `ieInit` between scripts and close
figures.

## The Three Repository Runners

| Runner | Purpose |
| --- | --- |
| `iset3dUnitTest` | Function-based unit tests in `_tests_` directories |
| `iset3dTutorialTest` | `t_*.m` tutorial scripts as smoke tests |
| `iset3dExampleTest` | `s_*.m` example scripts as smoke tests |

`iset3dUnitTest` is the ISET3D master runner; `ieUnitTest` is ISETCam's. Report
results with ISETCam's `ieTestReport` rather than writing a summary printer.

## Practical Order Of Work

Start with the smallest relevant test and widen only as needed:

1. Run the local runner in the `_tests_` directory nearest your change.
2. Run any directly related tutorial or example with `'selection'`.
3. Run `iset3dUnitTest` before sharing or merging a substantial change.
4. Run a full tutorial or example suite when the change touches shared setup,
   data, graphics, or a broadly used API.

## Unit Tests

```matlab
results = iset3dUnitTest;          % 'core' — the default
results = iset3dUnitTest('full');  % everything
```

`iset3dUnitTest` recursively discovers every `_tests_` directory under
`iset3dRootPath` and builds one master suite.

**Mode selection is by filename.** `'core'` (aliases `fast`, `quantitative`)
excludes any test whose name contains:

- `_remote` — needs Docker/network/GPU rendering
- `FullOnly` — otherwise unsuitable for the fast suite

`'full'` (alias `all`) keeps everything. Any other mode errors.

This is why **any test that calls a Docker-dependent render path must have
`_remote` in its filename**, e.g. `test_macbethGolden_remote.m`. Without it the
fast suite will try to render and fail on machines with no renderer configured.

### Area runners

Each `_tests_` directory has a local runner built with `TestSuite.fromFolder`,
`TestRunner.withTextOutput`, and `ieTestReport`. Use the one nearest your
change:

```matlab
results = utilitiesUnitTest;    % utilities/_tests_
results = assetUnitTest;        % utilities/asset/_tests_
results = dockerUnitTest;       % docker/_tests_
results = humanUnitTest;        % human/_tests_  (sceneEye)
results = paraxialUnitTest;     % lens/paraxial/_tests_
results = lensUnitTest;         % lens/tests/lensC/_tests_
results = rayUnitTest;
results = surfaceUnitTest;
results = filmUnitTest;
results = psfCameraUnitTest;
results = bbmUtilityUnitTest;
results = lensUtilityUnitTest;
```

Local runners run the `core` suite by default and accept `full` to include
everything. They must close figures created during the run while preserving
figures that were open beforehand.

### Writing tests

- Colocate tests in `_tests_` directories next to the code they protect. Use
  ISETCam's `_tests_` directories as the reference when no ISET3D convention
  exists yet.
- Name files `test_<subject>.m` and start each with
  `tests = functiontests(localfunctions)`.
- Cover accessors, computations, dimensions and shapes, invariants, important
  validation errors, and golden-value fingerprints with **explicit named
  tolerances**.
- Keep core tests deterministic and non-interactive. Control the RNG when
  randomness is needed. Classify GUI, smoke, slow, or resource-heavy tests out
  of the core suite via the filename conventions above.
- Golden values have their own rules — see the `golden-value-testing` skill.

When converting legacy `isetvalidate` scripts into unit tests, place each test
with the ISET3D subsystem it protects rather than mirroring the old validation
directory layout. Do not duplicate a test ISETCam already maintains.

## Tutorial And Example Tests

```matlab
tutorialRun = iset3dTutorialTest;
exampleRun  = iset3dExampleTest;
```

These recursively discover plain-text `t_*.m` and `s_*.m` files and run each
with fresh ISET state, so no script may depend on variables or objects left by
an earlier one. `.mlx` files are never executed.

### One script, or partway through

```matlab
run = iset3dTutorialTest('selection','t_piIntro_chess');
run = iset3dExampleTest('selection','s_metricsSPD');
run = iset3dTutorialTest('start','t_piIntro_chess');
```

`selection` runs only the named file. `start` runs it and every file after it
in the deterministic path-sorted plan — useful after fixing a failure partway
through a long run. It starts a **new** run; it does not resume the old one.

The value may be a bare stem, a file name with `.m`, a path relative to the
tutorial/example directory, or a full path.

The wrappers accept **no arguments or exactly one name-value pair**; anything
else errors.

### Automatic render skipping

ISET3D supplies `iset3dRenderSkipReason` as the runners' `conditionalSkipFcn`.
It scans each script for `piWRS`, `piRender`, `eyeRender`, or `thisSE.render`,
and when the configured renderer is not ready it reports the file as `Skipped`
with a reason instead of failing with a long PBRT stack trace.

This means **you do not need `% SkipFile` on a tutorial merely because it
renders.** Docker-dependent scripts skip themselves cleanly on a machine with
no renderer.

The runners also silence `piRecipeDefault:NoLights`, since many teaching
scripts deliberately render lightless scenes.

### Manual skipping

Use `% SkipFile` on its own comment line when a script should be discovered but
never executed automatically:

```matlab
% SkipFile
```

Use it sparingly — for unavailable external data or toolboxes, deliberate user
interaction, unusually expensive computation, or a known failure documented
nearby. Remove the tag once the file is suitable for routine runs. The legacy
`% UTTBSkip` marker still works, but new and updated files should use
`% SkipFile`.

Scripts that generate or refresh repository data should be named `data_*.m`
instead; they are not smoke-test sources. See the
`authoring-tutorials-examples` skill.

## Reading Results

The runners return a canonical run struct with planned files, per-file status
(`Passed`, `Failed`, `Skipped`), errors, timing, and checkpoint paths, and they
print a summary automatically. To list files of interest:

```matlab
ieTestReport(run,'List','failed');
ieTestReport(run,'List',{'failed','skipped'});
ieTestReport(run,'List','all');
```

Each run creates a timestamped directory under `local/` containing:

- `checkpoint.mat` — the latest durable run state
- `progress.log` — chronological progress and skip reasons
- `planned-files.txt` — the exact execution order

If MATLAB exits before returning a run variable, report straight from disk:

```matlab
ieTestReport('/path/to/checkpoint.mat','List','all');
ieTestReport('/path/to/run/directory','List',{'failed','skipped'});
```

A checkpoint still in state `Running` is a run that did not finish. Its
unfinished count and last active file show where to start investigating.

`ieTestReport` also accepts a MATLAB `TestResult` array:

```matlab
ieTestReport(results,'utilitiesUnitTest');
```

## When A Test Fails

Re-run the smallest failing unit test, tutorial, or example in a clean MATLAB
session. Before reaching for `SkipFile`, check whether the failure depends on
external data, optional toolboxes, graphics, user interaction, or the renderer.
If it is the renderer, confirm with `piDockerDiagnose('render',false)` — the
`iset3d-docker-rendering` skill covers that path. Tests must be deterministic
and must not require state left by another test.

## Architecture

ISET3D's runners are thin configuration wrappers over ISETCam's shared
`ieRunTutorialExampleTests` engine, so all ISET repositories return the same
canonical run record. Do not copy engine helper functions into ISET3D.

The canonical run-record schema and the wrapper contract are documented in
ISETCam's `test-runner-architecture` skill
(`../isetcam/.github/skills/test-runner-architecture/SKILL.md`). Read that
before changing `ieRunTutorialExampleTests`, the checkpoint format, or
`ieTestReport`.

Long-form: [docs/testing.md](../../../docs/testing.md).
