# Welcome to ISET3d (tiny)!

The tools in ISET3d extend ISETcam to provide a physically-accurate simulation (ray traced) rendering of 3D scenes.  The code returns a scene spectral radiance, or if you specify a lens, an optical image spectral irradiance, for a 3D scene.  The ray tracing is based on PBRT (Physically Based Ray Tracing).

The tools in this repository calculate the spectral irradiance of realistic three-dimensional scenes. The tools work with a special version of **PBRT (V4)**. The implementation is available in a set of Docker containers that run either on a CPU or one of a set of GPUs.

To use ISET3d you must have Docker and Matlab installed. This repository also depends on ISETCam (or ISETBio), and some people in our lab also require isetcloud. More on that in the wiki.

The general approach is the following

*  Begin with a set of PBRT files that define the scene. 
*  Read theses files to create an ISET3d **recipe**. 
    * The recipe is a Matlab class that specifies spatial resolution, number of rays, viewing distance, type of optics (pinhole, lens or light field microlens array)
    * The recipe also specifies information about the lens (which can contain multiple elements, spherical and certain aspherical shapes) and microlens array on the film surface
 * Edit the recipe
 * Write a new set of modified PBRT files and render them into an ISETCam scene or optical image (oi).

To see some examples, have a look at the tutorial directory. If you want to read more, please look through the [wiki pages](https://github.com/ISET/iset3d/wiki)

Note: This repository was formerly ISET3d-v4, pbrt2iset, and before that we relied on RenderToolbox4.

ISET3d was originally developed in Brian Wandell's [Vistalab group](https://vistalab.stanford.edu/) at [Stanford University](stanford.edu), along with co-contributors from other research institutions and industry.
