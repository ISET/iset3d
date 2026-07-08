# ISET3D TODO

## Tutorial Smoke-Test Cleanup

- Find the legitimate `flatSurface` / `flat surface` scene in the scene database or SDR and update the lighting tutorials to use that canonical asset.
  - Candidate tutorials currently skipped for this: `tutorials/lights/t_arealightArray.m`, `tutorials/lights/t_arealightSize.m`, `tutorials/lights/t_arealightSpread.m`, `tutorials/lights/t_lightCube.m`, `tutorials/lights/t_lightHeadlamp.m`, and `tutorials/lights/t_lightProjection.m`.
  - Once the scene lookup is stable, remove the related `% SkipFile` tags and rerun `iset3dTutorialTest`.
- Restore or relocate the local area-light PBRT scene used by `tutorials/lights/t_arealight.m`.
- Decide whether material preset texture assets should be included, downloaded on demand, or kept out of the smoke suite.
- Decide whether ISETBio-heavy tutorials, especially cone-mosaic workflows such as `tutorials/sceneEye/t_eyeCrop2Cones.m`, should move to ISETBio or remain as skipped bridge tutorials in iset3d.
- Revisit the skipped lens/microlens tutorials after the `lensC` merge settles and the spectral EXR conversion path for `t_lensMTF.m` is fixed.
- Revisit the participating-media tutorials after the remote render upload/path issue for generated PBRT files is understood.
