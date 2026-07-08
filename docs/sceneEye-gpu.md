# sceneEye GPU Rendering Plan

This note summarizes the current state of `sceneEye` rendering in ISET3D and
the likely path toward GPU support for human-eye optics. It is intended as a
planning handoff for future maintainers and AI agents.

The PBRT renderer source used by the Docker images is maintained at
[ISET/pbrt-v4](https://github.com/ISET/pbrt-v4). Local development often keeps
that repository next to ISET3D as `../pbrt-v4`.

## Current ISET3D Behavior

`sceneEye` renders with the PBRT `humaneye` camera for physiological optics.
That camera is currently CPU-only in practice. ISET3D therefore forces
non-pinhole `sceneEye` renders to use the CPU PBRT Docker image.

The relevant ISET3D entry points are:

- `human/@sceneEye/render.m`
- `human/@sceneEye/piWRS.m`

Both methods preserve the configured/default renderer for pinhole preview
renders. For true human-eye optics renders, they create or adapt an
`isetdocker` object with:

- `device = 'cpu'`
- `deviceID = ''`
- `dockerImage = 'digitalprodev/pbrt-v4-cpu'` when the requested image is empty
  or GPU-specific

This behavior is intentional. The human-eye camera in PBRT is not ready for
the wavefront GPU rendering path.

## PBRT Source Locations

The human-eye camera is implemented in:

- `src/pbrt/cameras.h`
- `src/pbrt/cameras.cpp`

The relevant class is `HumanEyeCamera`. PBRT creates it for camera names
`humaneye` and `realisticEye`.

The GPU wavefront renderer generates camera rays in:

- `src/pbrt/wavefront/camera.cpp`

That code calls `camera.GenerateRay(cameraSample, lambda)` inside a
`PBRT_CPU_GPU_LAMBDA`. Therefore every function reached from the selected
camera's `GenerateRay()` must be valid in GPU device code.

## Why HumanEyeCamera Is CPU-Only Today

`HumanEyeCamera::GenerateRay()` is declared with `PBRT_CPU_GPU`, and some helper
methods are also shaped for CPU/GPU use. However, the active human-eye optical
path calls several helpers that are not GPU-compatible.

The main blockers are:

1. `IntersectLensElAspheric()` uses GSL Brent root solving.

   The human-eye lens surfaces are biconic/aspheric. The current implementation
   solves the ray-surface intersection numerically using GSL:

   - `gsl_root_fsolver_type`
   - `gsl_root_fsolver`
   - `gsl_root_fsolver_brent`
   - `gsl_root_fsolver_alloc`
   - `gsl_root_fsolver_iterate`
   - `gsl_root_test_interval`

   These are host-side library calls and cannot execute in CUDA/OptiX device
   code.

2. `diffractHURB()` uses GSL random sampling.

   Diffraction is modeled with:

   - `gsl_rng`
   - `gsl_rng_alloc`
   - `gsl_ran_bivariate_gaussian`

   This is also host-only and not safe for the GPU ray-generation kernel.

3. Several human-eye helper declarations have commented-out `PBRT_CPU_GPU`
   annotations.

   In `HumanEyeCamera`, these helpers are currently not true GPU functions:

   - `IntersectLensElAspheric`
   - `applySnellsLaw`
   - `lookUpIOR`
   - `diffractHURB`
   - `BiconicZ`

   The commented annotations suggest that a GPU port was anticipated but not
   completed.

4. Host-side diagnostics appear in code reachable from the optical path.

   Calls such as `Error()`, `Warning()`, `printf`, and `std::cout` should be
   removed from device-reachable code or guarded so that they are not compiled
   into GPU kernels.

5. The wavelength handling should be reviewed before validating GPU parity.

   `HumanEyeCamera::GenerateRay()` sets `ray.wavelength = lambda[0]` and then
   resets `lambda` with `SampledWavelengths::SampleUniform(0.5)`. That may be
   intentional legacy behavior, but it should be audited before comparing CPU
   and GPU images.

6. A separate CPU correctness issue should be audited.

   `HumanEyeCamera::Create()` computes local values such as `frontThickness` and
   `effectiveFocalLength`, while `GenerateRay()` later uses the corresponding
   object members. Future work should verify that these members are initialized
   correctly before using CPU/GPU agreement as a validation target.

## Useful Comparison: RealisticCamera and OmniCamera

PBRT's `RealisticCamera` is a useful model for GPU-compatible lens tracing. Its
ray tracing helpers are marked `PBRT_CPU_GPU`, and its element intersections use
closed-form spherical geometry rather than host-side numerical solvers.

`OmniCamera` is also informative because it contains aspheric intersection code
that still uses GSL. In the active tracing path, the aspheric branch is disabled
with a comment noting that aspherical elements are not working for GPU. This is
the same family of problem as the human-eye model.

## Implementation Plan

The recommended path is staged. Do not begin by trying to port the entire model
including diffraction.

1. Establish a CPU baseline.

   Create small PBRT scenes using the `humaneye` camera with known eye models
   and deterministic render settings. Save baseline camera-ray or image-level
   outputs with diffraction disabled first.

2. Port biconic/aspheric intersection without GSL.

   Replace the GSL Brent solver with a GPU-compatible fixed-iteration solver.
   A bracketed bisection or Brent-like method implemented directly in PBRT math
   is the safest first target. It must avoid dynamic allocation and host-only
   library calls.

   The solver should:

   - evaluate the biconic sag function in `PBRT_CPU_GPU` code
   - use deterministic iteration counts or bounded convergence
   - return miss/failure cleanly when the ray does not bracket a valid surface
   - compute normals without host-only dependencies

3. Make the human-eye optical helpers truly CPU/GPU.

   Add and verify `PBRT_CPU_GPU` support for:

   - `IntersectLensElAspheric`
   - `applySnellsLaw`
   - `lookUpIOR`
   - `BiconicZ`

   Keep diffraction disabled during this phase.

4. Audit spectral IOR lookup.

   `Spectrum::operator()` is already CPU/GPU-dispatched in PBRT, and
   `iorSpectra` is stored as `pstd::vector<Spectrum>`. That looks promising, but
   the concrete spectrum types used by the eye models should be confirmed to
   live in GPU-visible allocation and avoid CPU-only calls.

5. Remove or guard host-only diagnostics in device-reachable paths.

   Device code should not rely on `Error()`, `Warning()`, `printf`, `std::cout`,
   or GSL. Failure cases should return empty camera rays or zero contribution,
   matching PBRT camera conventions.

6. Build and test a GPU PBRT image with `humaneye`.

   Compile the GPU renderer with the ported `HumanEyeCamera`. Test first with:

   - diffraction disabled
   - simple lens/eye model
   - low resolution
   - fixed samples per pixel
   - simple scene geometry

   Compare CPU and GPU generated rays or rendered images with explicit
   tolerances. Expect small numerical differences from solver behavior.

7. Add diffraction later.

   Replace the GSL bivariate Gaussian sampling in `diffractHURB()` with a
   PBRT-compatible GPU random source. This may require either deriving random
   values from existing camera samples or extending the camera sampling path to
   provide additional dimensions. This should be a separate milestone because it
   changes stochastic behavior and image noise.

8. Only then relax ISET3D's CPU override.

   ISET3D should continue forcing CPU for `sceneEye` human-eye optics until the
   PBRT Docker image advertises and verifies GPU-capable `humaneye` rendering.
   When GPU support exists, add an explicit feature check or version/image check
   before allowing `sceneEye` to use GPU rendering.

## Suggested Acceptance Criteria

Before ISET3D uses GPU rendering for `sceneEye` human-eye optics, require:

- PBRT GPU build succeeds with `HumanEyeCamera` enabled.
- A minimal `humaneye` scene renders on GPU without falling back to CPU.
- CPU and GPU ray-generation tests agree within defined tolerances for several
  retinal positions, pupil samples, wavelengths, and accommodation states.
- Image-level CPU/GPU comparisons pass for at least one simple scene and one MTF
  or slanted-bar style scene.
- Diffraction behavior is either validated on GPU or explicitly unsupported and
  disabled with a clear diagnostic.
- ISET3D has a focused test that verifies `sceneEye` selects CPU unless the
  installed PBRT/Docker image is known to support GPU human-eye rendering.

## Practical Recommendation

For current ISET3D work, keep the CPU override for non-pinhole `sceneEye`
renders. Treat GPU human-eye rendering as a PBRT implementation project first,
then expose it through ISET3D only after the PBRT Docker image has a tested
GPU-capable `HumanEyeCamera`.
