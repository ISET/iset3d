---
name: publishing-tutorials-examples
description: Use when converting an ISET3D tutorial or example .m file into a self-contained HTML page for a wiki or web site — iePublish, s_publishTutorials, s_publishExamples, embedding figures or movies, publishing options, or linking published HTML from GitHub or a wiki.
---

# Publishing ISET3D Tutorials And Examples

The publishing utilities are supplied by **ISETCam**, not ISET3D. They must be
on the path (they are, if you followed the `matlab-environment-setup` skill).

They produce **self-contained HTML**: figures are embedded as base64 images, so
a published page is one file you can serve without a companion folder of PNGs.

## Publish One File

```matlab
htmlFile = iePublish('tutorials/introduction/t_piIntro_chess.m');
web(htmlFile,'-browser');
```

From a dependent repository, pass a full path once that repository is on the
MATLAB path:

```matlab
htmlFile = iePublish(fullfile(piRootPath,'tutorials','materials','t_materials.m'));
```

`iePublish` writes the HTML next to the source `.m` file, with the same base
name. The `.m` extension in the argument is optional, and the path may be full,
relative, or a bare name on the MATLAB path.

## Publish A Set

```matlab
s_publishTutorials
s_publishExamples
```

Both call `iePublish` with `imageFormat` set to `'inline'` — the setting that
embeds figures and makes the output suitable for a wiki link. `s_publishExamples`
publishes the directory subset listed in its `sDir` variable; edit that
variable to publish a different set.

Note the names: the two batch scripts are `s_publishTutorials` and
**`s_publishExamples`**. There is no `s_publishScripts`.

## Options

The defaults are chosen for wiki-linkable output:

```matlab
htmlFile = iePublish(sourceFile, ...
    'evalCode', true, ...
    'showCode', true, ...
    'imageFormat', 'inline', ...
    'maxHeight', 512, ...
    'maxWidth', 512);
```

- `evalCode` — set `false` for a quick code-only preview. Figures and command
  output are regenerated only when `true`.
- `showCode` — set `false` to show output without source.
- `maxHeight` / `maxWidth` — resize embedded figures to keep the HTML
  manageable.
- `catchError` — leave `true` so one script error does not end a batch run.
- `createThumbnail` — default `false`.
- `stylesheet` — pass a CSS file for custom styling.

Keep `imageFormat` at `'inline'` for wiki-linked pages. Other formats (such as
`'png'`) write external image files that must be copied and linked alongside
the HTML.

## Render Cost When Publishing

Publishing with `evalCode` true **runs the script**, which means it renders.
Before a batch publish:

- Confirm the renderer is configured (`piDockerDiagnose('render',false)`), or
  expect every rendering script to fail into the HTML.
- Check that the scripts use modest film resolution and rays per pixel. A
  publish run over `tutorials/` executes every render sequentially.
- Consider publishing a topic folder at a time rather than the whole tree.

## Embedded Movies

Small MP4 movies can be embedded. Write the movie next to the source file
during publishing, then add a prose marker comment naming it:

```matlab
movieFile = fullfile(fileparts(mfilename('fullpath')),'exampleMovie.mp4');
ieMovie(movieData,'vname',movieFile,'show',false,'FrameRate',8);
%%
% iePublishVideo: exampleMovie.mp4
```

In the default inline mode, `iePublish` replaces the marker with a
self-contained HTML `<video>` element and deletes the temporary MP4. Keep
embedded movies short and small so the page stays reasonable.

## GitHub And Wiki Links

The generated files are ordinary HTML and render correctly when *served* as
HTML — GitHub Pages or any static web server. A GitHub `blob` URL will show the
HTML source instead of rendering the page, so link to a served URL from wiki
pages.

## Workflow

1. Edit and run the tutorial or example interactively.
2. Close unrelated figures and confirm the script runs without manual input.
3. Publish with `iePublish`, `s_publishTutorials`, or `s_publishExamples`.
4. Open the generated HTML locally and inspect figures, output, and links.
5. Commit the source `.m` and the generated `.html` when the project tracks
   published HTML.
6. Link the served HTML from the relevant wiki page.

Re-run the publisher whenever the source changes. Embedded figures make the
HTML self-contained but can make it large — use the size options when a script
creates big displays.

## Related

- `authoring-tutorials-examples` — writing the script in the first place.
- `iset3d-docker-rendering` — making sure renders succeed during a publish run.
