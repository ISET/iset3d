# ISET3D Golden Value Testing Plan

This document outlines the numerical checking strategy ("golden values") used
to protect key computations and structures in `iset3d` against regressions.

It is a **plan and target list**. The rules that apply whenever you write a
golden test — tolerance choice, storage, naming, guarding, and baseline
updates — live in the `golden-value-testing` skill
(`.github/skills/golden-value-testing/SKILL.md`).

## 1. Core Routine Targets (Local / Fast)

These do not require a renderer and belong in the `core` suite.

### Asset Transformations & World Coordinates

- **Target**: Coordinate propagation through the asset tree.
- **Golden values**: Expected 3D position and orientation vectors after nested
  translations, rotations, and scaling.
- **Verification**: Node world-coordinate derivations, e.g.
  `thisR.get('asset',<ID>,'world position')`, match analytical expectations to
  at least four decimal places.
- **Status**: partly covered by
  `utilities/asset/_tests_/test_worldCoordinates.m`.

### Camera & LookAt Matrices

- **Target**: Camera transformation matrices generated from `from`, `to`, and
  `up` vectors.
- **Golden values**: Homogeneous transformation matrices for standard camera
  viewing angles.
- **Verification**: lookAt matrix elements match stable pre-computed matrices.

### Eye Model & Lens Geometry (sceneEye)

- **Target**: Schematic eye dimensions, refractive indices, and lens profiles at
  specific accommodation states.
- **Golden values**:
  - Navarro lens parameters (radii, thicknesses, refractive indices) at 0 D and
    4 D accommodation.
  - Arizona lens parameters at 0 D and 4 D accommodation.
- **Verification**: `thisSE.set('accommodation',4)` updates lens curvatures and
  refractive indices to match the clinical golden curves.

## 2. Remote Rendering Targets (Docker-dependent)

These require a configured renderer and **must** be named `*_remote.m` so
`iset3dUnitTest('core')` excludes them.

### Scene Luminance & Chromaticity

- **Target**: Mean luminance and chromaticity coordinates.
- **Golden values**: Lux levels and CIE xy coordinates for preset scenes such
  as `SimpleScene` and `Cornell_Box`.
- **Verification**:

  ```matlab
  testCase.verifyEqual(sceneGet(scene,'mean luminance'), expectedLuminance, ...
      'RelTol', 0.01);
  ```

- **Status**: `utilities/_tests_/test_macbethGolden_remote.m` covers the
  Macbeth chart case and is the reference implementation for this pattern.

### Depth Map Calibration

- **Target**: Depth map distance values at specific pixel coordinates.
- **Golden values**: Depth in meters for preset test points in `SimpleScene`
  and `bunny`.
- **Verification**: within 1% of the established baseline.

## 3. Implementation Strategy

Summarized here; see the `golden-value-testing` skill for the full rules.

- **Tolerances**: always pass an explicit `'AbsTol'` or `'RelTol'` to
  `verifyEqual` / `verifyLessThan`, so machine-specific float variation does not
  cause failures. Rendering goldens use 1–5% relative; deterministic
  computations use `1e-6` absolute or tighter.
- **Storage**: scalars and small vectors inline in the `test_*.m` source, where
  they are reviewable in a diff; large reference arrays in a MAT file in the
  same `_tests_` directory.
- **Classification**: `_remote` in the filename for anything that renders.
- **Baseline updates**: confirm the new value is correct rather than merely
  different, then document the reason in the commit message.

## See Also

- `.github/skills/golden-value-testing/SKILL.md`
- `.github/skills/iset3d-testing-workflow/SKILL.md`
- [testing.md](testing.md)
