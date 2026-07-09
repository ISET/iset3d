# ISETLens Runtime Import

This subtree contains the curated runtime import from the former sibling
`../isetlens` repository.

Source repository: `/Users/wandell/Documents/MATLAB/isetlens`

Source commit: `4f1eac8`

Imported first-pass scope:

- class folders: `@lensC`, `@rayC`, `@filmC`, `@surfaceC`, `@psfCameraC`
- runtime utilities: `utility/`, including `utility/lens/lensFocus.m`
- paraxial optics code: `paraxial/`
- colocated unit tests for the imported runtime code

The imported lens tests live under `lens/**/_tests_` and are discovered
by `iset3dUnitTest` as part of the ordinary ISET3D core suite. There is no
separate public ISETLens unit-test runner in this merged layout.

A first curated education batch has been added under `tutorials/lens/` and
`examples/lens/`. The human-eye materials from ISETLens, including Gullstrand
workflows, are intentionally deferred to a separate sceneEye/eye-model pass
alongside the existing Navarro and Arizona eye model tutorials and tests.
