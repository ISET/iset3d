# ISET3D TODO

## Tutorial Smoke-Test Cleanup

- Review remaining examples in `underDevelopment` folders and decide which
  should be refreshed, moved to ISETBio, renamed as data-generation scripts, or
  removed.  Current ISET3D tutorial `underDevelopment` sceneEye files have
  been moved out of this repo.
- Decide whether material preset texture assets should be included, downloaded on demand, or kept out of the smoke suite.
- Revisit the participating-media tutorials after the remote render upload/path issue for generated PBRT files is understood.
- In ISETBio, validate the moved `tutorials/sceneEye/` tutorials with ISET3D
  on the MATLAB path, then decide which should remain tutorials, become
  examples, or stay skipped.

## Rendering Database

- Add a small Mongo endpoint helper that reads the stable `dbServer` preference,
  detects when direct access fails, and reports the SSH tunnel command plus the
  command-local `localhost:<port>` override to use.
