# ISETLens Merge Assessment

Date: 2026-07-03

## Conclusion

Merging `../isetlens` into `iset3d` is a good idea, but it should be done as a
planned integration rather than a simple directory copy.

The strongest reason to merge is that `iset3d` already behaves as if
`isetlens` is part of the ecosystem.  Several tutorials, examples, camera
utilities, and recipe getters have optional branches for `lensC`, `rayC`,
`filmC`, `psfCameraC`, or `lensFocus`.  Some tutorials are currently skipped
only because `isetlens` is optional and absent from the default path.  Folding
the lens code into `iset3d` would make the optics teaching path more coherent
and reduce setup friction for users.

Degree of difficulty: **moderate**.

The code volume is not large for a MATLAB migration: about 171 `.m` files.  The
main difficulty is not size; it is integration hygiene.  `isetlens` is an older
repository with class-folder APIs, examples/tutorials, wiki material, and a few
legacy scripts.  It should be curated into `iset3d` rather than imported whole
and exposed all at once.

## Why It Is Worth Doing

- `iset3d` already contains optional `isetlens` hooks in real code paths.
- Lens work is central to ISET3d rendering, camera models, microlens workflows,
  PSF examples, and sceneEye education.
- `isetlens` has educational assets that fit the current tutorial/example
  cleanup direction: geometric ray tracing, paraxial optics, PSF formation,
  diffraction, autofocus, and lens scaling.
- Users would no longer need to discover and path-manage a separate repository
  before running lens-related tutorials.
- A merged codebase would make testing and documentation more honest: lens
  functionality would either pass in the normal suite or be explicitly skipped.

## Risks

- A direct import would add old examples/tutorials that may not meet the current
  tutorial standard.
- `isetlens` has little visible test infrastructure in `validate/`; regression
  coverage would need to be built around the core APIs.
- Some scripts call ISETCam/ISETBio/ISET3d functions directly, so dependency
  boundaries should be made explicit.
- The `isetlens` checkout is large mostly because of `.git`; do not copy that
  directory into `iset3d`.
- Do not import `local/`, `.DS_Store`, spreadsheet scratch files, or wiki
  history as executable code.
- There are generic method-name overlaps such as `list.m` and `plot.m`, but
  these are class-folder methods and are not a serious collision by themselves.

## Recommended Import Shape

Prefer a curated subtree inside `iset3d`, for example:

```text
lens/
  @lensC/
  @rayC/
  @filmC/
  @surfaceC/
  @psfCameraC/
  paraxial/
  utility/
  tutorials/
  examples/
```

Then update root/path helpers so users do not need `ilensRootPath` as a separate
repository root.  Keep a compatibility wrapper for a while:

```matlab
ilensRootPath
```

could return the new `iset3d/lens` root or warn with migration guidance.

## Pre-Merge Requirement: Test `isetlens` First

Before integrating `isetlens` into `iset3d`, create a real validation layer in
the `isetlens` repository itself.  That repository does not currently have an
`isetvalidate`-style test entry point, and it should.  We do not need to clean
up all old `isetlens` tutorials and examples before merging, but the critical
runtime functions should have unit tests and golden-value checks.

Minimum pre-merge testing goals:

- Add an `isetlensValidate` or equivalent runner.
- Add unit tests for the core classes:
  - `lensC`
  - `rayC`
  - `filmC`
  - `surfaceC`
  - `psfCameraC`
- Add tests for critical utility functions used by ISET3d:
  - lens loading and writing
  - `lensFocus`
  - ray tracing through a known lens
  - paraxial/cardinal point calculations
  - PSF/film recording for a simple point source
- Add golden values for stable numerical outputs, such as:
  - focal length or focus distance for a known JSON lens
  - cardinal points for a simple lens
  - ray intersection coordinates for a small deterministic ray bundle
  - PSF centroid or size for a simple point source and film geometry
  - round-trip lens read/write invariants

These tests should run without Docker and should not depend on remote rendering.
They should establish confidence in the lens/math layer before the code is
folded into the larger ISET3d test and tutorial ecosystem.

## Suggested Phased Plan

1. Add validation and golden tests in `isetlens`.

   Create an `isetlensValidate` entry point and targeted unit tests for the
   critical runtime APIs.  Do this before moving code into `iset3d`.

2. Inventory `iset3d` dependencies on `isetlens`.

   Start from the existing references to `lensC`, `rayC`, `filmC`,
   `psfCameraC`, `lensFocus`, and `isetlens` in `tutorials/`, `examples/`,
   `utilities/`, and `@recipe/`.

3. Import only the runtime core first.

   Bring in class folders and utility functions needed by current `iset3d`
   code.  Leave old tutorials/examples/wiki out of the first executable import.

4. Add path/root compatibility.

   Update any code that assumes `ilensRootPath`, and add a compatibility
   wrapper if needed.

5. Add focused ISET3d integration tests.

   After the core import, add ISET3d-side tests such as:

   - `lensC` can load a standard JSON lens from `piDirGet('lens')`.
   - `lensFocus` or equivalent focus calculation works for a known lens.
   - `rayC` can trace a small ray bundle through a simple lens.
   - `piMicrolensInsert` works without requiring an external repo.
   - A currently skipped lens tutorial can run or fail for a real reason.

6. Curate educational scripts.

   Move the best `isetlens/tutorials/t_*.m` scripts into `iset3d/tutorials/`
   only after shortening them to the tutorial standard.  Move broader workflows
   to `examples/`.

7. Record the source commit.

   History preservation is not required.  Copy the curated files and document
   the source `isetlens` commit used for the import.

8. Remove optional-path warnings.

   Once the core lens code is in-tree, replace messages like "Add isetlens to
   your path" with normal in-repo behavior.

## What Not To Do

- Do not copy the whole `../isetlens` directory wholesale.
- Do not import `.git`, `local/`, `.DS_Store`, or old scratch artifacts.
- Do not automatically promote all `isetlens/tutorials` into current tutorials.
- Do not make this merge at the same time as fixing `sceneEye`; both affect
  optics, and mixing them would make regressions harder to read.

## Recommendation

Proceed, but in two stages:

1. **Core merge:** import and test the runtime lens classes/utilities needed by
   existing `iset3d` code.
2. **Education merge:** curate the best `isetlens` tutorials/examples after the
   core is stable.

This is worth doing because it aligns the repository with how users already
encounter the software: ISET3d rendering, camera optics, microlenses, PSFs, and
sceneEye all need lens concepts nearby.  The difficulty is manageable if the
merge is curated and test-led.
