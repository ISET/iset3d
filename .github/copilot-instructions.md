# ISET3D AI Instructions

Use this file as the shared startup guidance for Copilot, Claude, Codex,
Gemini, and other AI coding assistants working in this repository.

## Repository Context

- MATLAB is the primary runtime.
- The main repository is `iset3d`. ISETCam (`../isetcam`) is a required
  dependency and is always expected to be on the MATLAB path when ISET3D is
  used or tested.
- ISET3D code and tests may directly use ISETCam utilities, including
  `ieTestReport`. Do not duplicate utilities already supplied by ISETCam.
- Many independently maintained repositories depend on ISET3D. Before removing
- or changing public APIs, paths, data locations, setup behavior, or integration
  hooks, search for likely external usage and prefer staged deprecation when an
  immediate change could disrupt collaborators. Allow time for dependent
  repositories to migrate unless coordinated cleanup is explicitly requested.
- For VS Code MATLAB setup, see `.vscode/matlab-setup.md`.
- For MATLAB Command Window path setup, use `.github/matlab-paths.md`.

## Tutorials and Examples

ISET3D keeps `tutorials/` and `scripts/` as separate teaching surfaces for
different goals and audiences.

- **Tutorials (`tutorials/`)**

  - Audience: learners (including new students) who can program and are
    learning image systems engineering and the ISET3D/PBRT rendering pipeline.
  - Purpose: short, heavily commented introductions to key objects and APIs.
  - Expected content:
    - object creation and setup
    - `*Get`/`*Set` usage for key properties
    - basic visualization (`*Window`, `*Plot`)
    - one simple quantitative computation/checkpoint
  - Expected behavior: runs relatively quickly and is easy to read linearly.
- **Scripts (`scripts/`)**

  - Audience: users looking for realistic analysis patterns to adapt.
  - Purpose: applied workflows and more advanced computations using ISET3D.
  - Expected content:
    - end-to-end numerical analyses or visualization workflows
    - realistic parameter choices and tradeoff exploration
    - code that users may copy/adapt as a starting point for their own work
  - Expected behavior: can be longer and more detailed than tutorials.

When adding or editing files, preserve this distinction. If content is mainly
onboarding and API orientation, place it in `tutorials/`. If content is mainly
applied workflow, analysis, or deeper exploration, place it in `examples/`.

### Data-Generation Scripts

Some scripts exist to generate or refresh repository data files rather than to
serve as tutorials or examples. Name these scripts `data_*.m`. This naming
distinguishes them from automated tutorial (`t_*.m`) and example (`s_*.m`)
smoke-test sources and makes their side-effecting purpose explicit.

You can convert these tutorials and scripts into HTML documentation by running
the `s_publishTutorials` and `s_publishScripts` utilities (provided by ISETCam)
from the MATLAB command window. To publish a single file, use the underlying
utility `iePublish('filename.m')` which applies the correct HTML
formatting and embedded figure styles needed for the tutorials site.

For student contributors, prioritize clarity, reproducibility, and instructional
value: use clear comments, stable outputs, and explicit links to related wiki
pages, tests, and nearby tutorials/examples.

### Skipping Automated Tutorial and Example Runs

The `iset3dTutorialTest` and `iset3dScriptTest` runners execute `t_*` and
`s_*` files by default. To exclude a source file from these automated smoke
runs, add this exact comment anywhere in the file:

```matlab
% SkipFile
```

Use this opt-out sparingly for files that require unavailable external data or
toolboxes, deliberate user interaction, unusually expensive computation, or a
known failure that is explicitly documented nearby. The runners report these
files as `Skipped`. Remove the tag when the file becomes suitable for routine
automated execution.

The legacy `% UTTBSkip` marker remains supported for compatibility, but new
and updated files should use `% SkipFile`.

ISET3D's wrappers use the shared ISETCam test engine. See
`../isetcam/docs/tutorial-example-test-architecture.md` for the canonical run
schema and the wrapper contract for additional repositories.

## ISETCam Pipeline

Prefer existing object-specific functions before writing new utilities.

1. Scene: `scene*` functions, accessed with `sceneGet` and `sceneSet`.
2. Optical image: `oi*` functions, accessed with `oiGet` and `oiSet`.
3. Sensor: `sensor*` functions, accessed with `sensorGet` and `sensorSet`.
4. Image processing: `ip*` functions, accessed with `ipGet` and `ipSet`.
5. Display: `display*` functions, accessed with `displayGet` and `displaySet`.

Common constructors and compute functions include `sceneCreate`,
`oiCreate`, `oiCompute`, `sensorCreate`, `sensorCompute`, `ipCreate`,
`ipCompute`, and `displayCreate`.

For object diagnostics, prefer existing plotting functions such as
`scenePlot`, `oiPlot`, `sensorPlot`, `ipPlot`, and `displayPlot` over ad hoc
plotting.

## Search Guidance

- Use `rg` for text search and `fd` for filename/path search when using a
  terminal.
- Before adding behavior, search for nearby examples with the relevant object
  prefix.
- For color transforms and color science utilities, search `color/` before
  implementing new code.
- For new scene patterns or chart behavior, check existing examples in
  `scene/` and especially related pattern/chart code.

## Coding Style

- Keep edits minimal and consistent with existing MATLAB style.
- Reuse established constructors, getters, setters, plotting helpers, and
  object naming conventions.
- Prefer vectorized MATLAB where it improves clarity or performance.
- Update function header comments when behavior changes, especially `Syntax`,
  `Inputs`, `Returns`, and `See also`.
- Do not add dependencies unless they are necessary and consistent with the
  repository.

## Validation

- Validate modified files with MATLAB diagnostics or focused test commands when
  practical.
- Place tests for major objects and computational areas in colocated `_tests_`
  directories. Use ISETCam's `_tests_` directories as the reference
  implementation when an ISET3D convention is not yet established.
- Write function-based MATLAB tests in files named `test_<subject>.m`, starting
  each file with `tests = functiontests(localfunctions)`.
- Prefer focused, descriptively named test functions that cover accessors,
  computations, dimensions and shapes, invariants, important validation
  errors, and stable golden-value fingerprints with explicit named tolerances.
- Keep core tests deterministic and non-interactive. Control random-number
  generation when randomness is required, and classify GUI, smoke, slow, or
  resource-heavy tests outside the core suite.
- Give each `_tests_` directory a local `<area>UnitTest.m` runner built with
  `TestSuite.fromFolder`, `TestRunner.withTextOutput`, and `ieTestReport`.
  Local runners should run the `core` suite by default and accept `full` to
  include all tests.
- Local and repository-wide runners must close figures created during testing
  while preserving figures that were open before the test run.
- Run the full ISET3D unit-test suite with `iset3dUnitTest` and render or
  summarize its output with ISETCam's `ieTestReport`. `iset3dUnitTest` is
  the ISET3D master runner; `ieUnitTest` is the ISETCam master runner.
- For details on the shared script-testing engine and runner contract, see
  [tutorial-example-test-architecture.md](file:///Users/wandell/Documents/MATLAB/isetcam/docs/tutorial-example-test-architecture.md).
- When converting legacy `isetvalidate` scripts into built-in unit tests,
  place each test with the ISET3D subsystem or behavior it protects rather
  than copying the legacy validation directory layout. Do not duplicate a
  test already maintained by ISETCam merely because the validation script
  historically lived under an ISET3D validation directory.
- MATLAB is available through the VS Code MATLAB extension.
- A local MATLAB executable is available at
  `/Applications/MATLAB_R2025b.app/bin/matlab` and can be used with `-batch`
  for non-interactive checks.
- If launching MATLAB from a sandboxed shell fails silently or exits with
  status 1, retry unsandboxed or escalated because MATLAB may need to write
  preferences or cache files outside the repository.

## Remote Rendering (Docker / PBRT)

ISET3D renders scenes by calling PBRT inside Docker containers that run on
remote GPU servers (currently `orange.stanford.edu`). Tests and scripts
that invoke `piWRS`, `piRender`, or any rendering pipeline have several
environmental prerequisites:

- **Stanford VPN**: When working off-campus, an active Stanford VPN
  connection is required to reach the remote rendering servers. Tests
  labelled `_remote` in their filename assume this access.
- **Docker context**: MATLAB must have a Docker context configured for the
  remote host. Run `piDockerConfig` to set this up or verify it. The
  configuration is stored in MATLAB preferences under the `docker` group
  (`getpref('docker')`). These preferences include the render context name,
  the Docker image, and the GPU assignment.
- **MATLAB preferences**: Docker-related preferences (`ISETDocker`,
  `docker`) are machine-specific and persist across sessions. When
  switching between machines, campus vs. VPN, or GPU assignments, the
  preferences may need to be reset. Use `rmpref('docker')` to clear stale
  configuration and then re-run `piDockerConfig`.
- **Test classification**: Any test file that calls Docker-dependent
  rendering must include `_remote` in its filename (e.g.,
  `test_macbethGolden_remote.m`). The `iset3dUnitTest('core')` runner
  automatically excludes `_remote` tests so that the fast/local suite
  runs without network or Docker dependencies. Use `iset3dUnitTest('full')`
  to include them.

## Golden Value Testing

Golden value tests protect numerical outputs against regressions by
comparing computed results to pre-established reference values.

- **Tolerances**: Always use explicit named tolerances (`'RelTol'` or
  `'AbsTol'`) with `verifyEqual`. Rendering-based goldens should use
  relative tolerances of 1–5% to accommodate Monte Carlo noise. Purely
  deterministic computations (geometry, optics) can use tighter tolerances
  (e.g., `'AbsTol', 1e-6`).
- **Storage**: Store scalar and small-vector golden values directly in the
  test source code. For large reference arrays (images, spectra), save to a
  MAT file in the same `_tests_` directory and load it in the test setup.
- **Naming**: Golden value test files that require rendering should follow
  the `test_<subject>Golden_remote.m` naming convention.
- **Baseline updates**: When an intentional code change shifts golden
  values, update the reference values in the test and document the reason
  in the commit message.
- See `.github/agents/GOLDEN.md` for the overall plan and target list.

## When Uncertain

Choose the simplest implementation that matches existing `scene*`, `oi*`,
`sensor*`, `ip*`, and `display*` patterns. Ask the user only when the choice
would materially affect behavior, API shape, or test expectations.
