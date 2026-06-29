%% Prepare PNG and montage of PNGs for SDR upload
%
% The scene mat-files were rendrered using s_sdrRenderScenes
%

subdir = {'bitterli','pbrtv4','iset3d'};
for ss = 1:3
    thisDir = subdir{ss};
    delete(sprintf('%s_*.png',thisDir));
    chdir(fullfile(piRootPath,'local','prerender',thisDir));
    files = dir('*.mat');

    for ff=1:numel(files)

        load(files(ff).name,'scene');
        if ff == 1, sceneWindow(scene);
            scene = sceneSet(scene,'gamma',0.5);
        end

        [~,fname,~] = fileparts(files(ff).name);

        rgb = sceneGet(scene,'srgb');
        try
            rgb = imadjust(rgb,[prctile(rgb(:),1),prctile(rgb(:),99)]);
        catch
        end

        fname = sprintf('%s.png',fname);
        imwrite(rgb,fname);
    end

    ieMontages('file prefix',thisDir);
end

%%
