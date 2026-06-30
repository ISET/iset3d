# ISET3D Golden Value Testing Plan

This document outlines the numerical checking strategy ("golden values") to protect key computations and structures in the `iset3d` repository against regressions.

## 1. Core Routine Targets (Local / Fast)

Before testing rendering outputs, we will introduce numerical golden checks on the structural, geometric, and optical parameters computed by core utilities.

### Asset Transformations & World Coordinates
*   **Target**: Coordinate propagation through the asset tree.
*   **Golden Values**: Expected 3D position and orientation vectors after nested translations, rotations, and scaling.
*   **Verification**: Check that node world-coordinate derivations (e.g., using `thisR.get('asset', <ID>, 'world position')`) match analytical expectations to at least 4 decimal places.

### Camera & LookAt Matrices
*   **Target**: Camera transformation matrices generated from `from`, `to`, and `up` vectors.
*   **Golden Values**: Homogeneous transformation matrices calculated for standard camera viewing angles.
*   **Verification**: Verify lookAt matrix elements match stable pre-computed matrices.

### Eye Model & Lens Geometry (sceneEye)
*   **Target**: Schematic eye dimensions, refractive indices, and lens profiles at specific accommodation states.
*   **Golden Values**: 
    *   Navarro lens parameters (radii, thicknesses, refractive indices) for $0\,\text{D}$ and $4\,\text{D}$ accommodation.
    *   Arizona lens parameters for $0\,\text{D}$ and $4\,\text{D}$ accommodation.
*   **Verification**: Verify that changing accommodation (e.g., `thisSE.set('accommodation', 4)`) updates the lens curvatures and refractive indices to match exact clinical golden curves.

---

## 2. Remote Rendering Targets (Stanford VPN / Docker-dependent)

Once connected to the Stanford VPN, we will introduce golden value checks on the rendered optical images (OI) and scenes.

### Scene Luminance & Chromaticity
*   **Target**: Mean luminance and chromaticity coordinate values.
*   **Golden Values**: Exact lux levels and CIE xy coordinates for rendering preset scenes (e.g., `SimpleScene`, `Cornell_Box`).
*   **Verification**:
    ```matlab
    testCase.verifyEqual(sceneGet(scene, 'mean luminance'), expectedLuminance, 'RelTol', 0.01);
    ```

### Depth Map Calibration
*   **Target**: Depth map distance values at specific pixel coordinates.
*   **Golden Values**: Exact depth (meters) for preset test points in `SimpleScene` and `bunny`.
*   **Verification**: Confirm depth values are within $1\%$ tolerance of established baseline measurements.

---

## 3. Implementation Strategy in Unit Tests

*   **Tolerances**: All tests will utilize MATLAB's `verifyEqual` or `verifyLessThan` with explicit absolute (`AbsTol`) or relative (`RelTol`) tolerance arguments to avoid test failures caused by machine-specific float variations.
*   **Storage**: Golden values will be stored directly inside the relevant `test_*.m` code structures (for lightweight arrays/scalars) or inside structured MAT-files within the package `_tests_` directories.
