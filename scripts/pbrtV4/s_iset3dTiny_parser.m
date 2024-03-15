% parser test

% thisR = piRead('/Users/zhenyi/git_repo/dev/iset3d-tiny/data/scenes/web/cornell_box/cornell_box.pbrt');
% lightName = 'new_spot_light_L';
% spotLight = piLightCreate(lightName,...
% 'type','spot',...
% 'spd','equalEnergy',...
% 'specscale', 1, ...
% 'coneangle', 15,...
% 'conedeltaangle', 10, ...
% 'cameracoordinate', true);
% thisR.set('light', spotLight, 'add');
% thisR.set('film resolution', [134, 134]);
% scene = piWRS(thisR);
% 
% thisR_pw = piRead('/Users/zhenyi/git_repo/dev/iset3d-tiny/local/cornell_box/cornell_box.pbrt');
% thisR_pw.set('film resolution', [134, 134]);
% 
% scene_pw = piWRS(thisR_pw);
%% Fix these
% Too many assets to parse, might not be a good scene for us to parse with
% iset3d.
% thisR = piRead('/Users/zhenyi/git_repo/pbrt-v4-scenes/landscape/view-0.pbrt');
% Illegal memory access
% thisR = piRead('/Users/zhenyi/git_repo/pbrt-v4-scenes/villa/villa-daylight.pbrt');
% thisR = piRead('/Users/zhenyi/git_repo/pbrt-v4-scenes/watercolor/camera-1.pbrt');
% thisR = piRead('/Users/zhenyi/git_repo/pbrt-v4-scenes/sanmiguel/sanmiguel-entry.pbrt');
% thisR = piRead('/Users/zhenyi/git_repo/pbrt-v4-scenes/zero-day/frame25.pbrt');

%%
sceneList = {'/Users/zhenyi/git_repo/pbrt-v4-scenes/contemporary-bathroom/contemporary-bathroom.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/bmw-m6/bmw-m6.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/barcelona-pavilion/pavilion-day.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/pbrt-book/book.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/bunny-fur/bunny-fur.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/crown/crown.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/ganesha/ganesha.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/lte-orb/lte-orb-silver.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/sportscar/sportscar-area-lights.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/bistro/bistro_boulangerie.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/bistro/bistro_cafe.pbrt',...
    '/Users/zhenyi/git_repo/pbrt-v4-scenes/bistro/bistro_vespa.pbrt'};
for ii = 1:numel(sceneList)
    try
        thisR = piRead(sceneList{ii});
        scene = piWRS(thisR,'speed',1.01);
        ip = piRadiance2RGB(scene);ipWindow(ip);
        msg{ii} = sprintf('Passed: %s.\n',sceneList{ii});
    catch
        msg{ii} = sprintf('Failed: %s.\n',sceneList{ii});
    end
end
disp(msg);
%%
% piWrite(thisR);
% [scene] = piRender(thisR, 'docker', isetdocker);
% sceneWindow(scene);
%%
% scene = piAIdenoise(scene);
% sceneWindow(scene);