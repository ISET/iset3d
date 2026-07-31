---
name: golden-value-testing
description: Use when adding or updating an ISET3D numerical regression test with stored reference values — choosing RelTol or AbsTol for rendering versus deterministic computations, storing scalars inline versus arrays in a MAT file, the test_<subject>Golden_remote.m naming convention, guarding a render-dependent test, or updating a baseline after an intentional change.
---

# Golden Value Testing

Golden value tests protect numerical outputs against regressions by comparing
computed results to pre-established reference values. They are the difference
between "the code still runs" and "the code still computes the right answer."

The remaining target list and phasing live in
[docs/golden-value-testing.md](../../../docs/golden-value-testing.md). This
skill holds the rules that apply whenever you write one.

## Tolerances

**Always pass an explicit named tolerance to `verifyEqual`.** A bare
`verifyEqual` on floating point is a test that will fail on someone else's
machine.

| Kind of computation | Tolerance |
| --- | --- |
| Rendering-based (Monte Carlo noise) | `'RelTol'` between 0.01 and 0.05 (1–5%) |
| Deterministic (geometry, transforms, paraxial optics) | `'AbsTol', 1e-6` or tighter |
| Integer counts, dimensions, shapes | exact — no tolerance |

```matlab
testCase.verifyEqual(sceneGet(scene,'mean luminance'), 100, ...
    'RelTol', 0.02, 'Mean luminance drifted from the golden value.');

testCase.verifyEqual(worldPosition, [0.5 0 -1.2], ...
    'AbsTol', 1e-6, 'Asset world position no longer matches analysis.');

testCase.verifyEqual(rows, 180, 'Film row count changed.');
```

Rendering tolerance depends on rays per pixel: a golden rendered at 32 rays
needs a looser tolerance than one at 512. If a test is flaky, **raise the
sample count before loosening the tolerance** — a 10% tolerance stops catching
regressions.

Always include the message argument. A golden failure six months from now is
much easier to triage when the assertion says what it was protecting.

## Storage

- **Scalars and small vectors:** store directly in the test source. They are
  reviewable in a diff, which is the whole point.
- **Large reference arrays (images, spectra):** save to a MAT file in the same
  `_tests_` directory and load it in test setup. Note that `.mat` is marked
  binary in `.gitattributes`, so these do not diff — keep them as small as the
  test allows and describe what changed in the commit message.

## Naming And Classification

A golden test that requires rendering **must** have `_remote` in its filename:

```text
test_<subject>Golden_remote.m       % rendering-based
test_<subject>.m                    % deterministic; belongs in the core suite
```

`iset3dUnitTest('core')` excludes anything matching `_remote` or `FullOnly`, so
this naming is what keeps the fast suite runnable on a machine with no Docker,
no GPU, and no VPN. Getting it wrong makes the core suite fail for everyone
else. See the `iset3d-testing-workflow` skill.

## Guarding A Render-Dependent Test

Even in the `full` suite, a rendering test should fail *informatively* when the
environment is not ready. Use `assumeFail` so the result is a skip, not an
error:

```matlab
ieInit;
if ~piDockerExists
    try
        piDockerConfig;
    catch ME
        testCase.assumeFail( ...
            sprintf('Docker not available, skipping: %s', ME.message));
        return;
    end
end
```

Document the environmental prerequisites in the file header —
VPN, Docker context, `ISETDocker` preferences — as
[`test_macbethGolden_remote.m`](../../../utilities/_tests_/test_macbethGolden_remote.m)
does.

## What Makes A Good Golden

Pick quantities that are **stable, physically meaningful, and would actually
change if the code broke**:

- Scene/OI: mean luminance, CIE xy chromaticity, illuminant photon levels,
  spatial dimensions, wavelength sample count, field of view.
- Geometry: world position and orientation after nested translate/rotate/scale;
  lookAt matrix elements for standard viewing angles.
- Optics: film distance for a given focus distance, cardinal points, paraxial
  matrices.
- Eye models: Navarro and Arizona lens radii, thicknesses, and refractive
  indices at 0 D and 4 D accommodation.
- Depth: depth values at named pixel coordinates in a fixed scene.

Avoid goldens on quantities dominated by Monte Carlo noise at low sample
counts, or on anything that depends on figure rendering or window state.

## Determinism

- Control the RNG when randomness is involved.
- Pin every parameter the value depends on — film resolution, rays per pixel,
  bounces, render type, camera position. A golden that inherits a default is a
  golden that silently changes when the default does.
- Never depend on state left by another test.

## Updating A Baseline

When an intentional change shifts a golden value:

1. Confirm the new value is *correct*, not merely different. A shifted golden
   is the test doing its job; work out why before overwriting it.
2. Update the reference in the test.
3. **Document the reason in the commit message** — what changed in the code,
   and why the new number is right.

Do not widen a tolerance to make a real regression pass.

## Related

- `iset3d-testing-workflow` — running the suites and the `_remote`/`FullOnly`
  conventions.
- `iset3d-docker-rendering` — confirming the renderer is ready before blaming
  the numbers.
