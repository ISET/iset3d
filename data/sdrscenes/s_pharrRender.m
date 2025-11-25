%% s_pharrRender
%
% I have a directory of the pbrt-v4-scenes-master scenes on my local
% drive, and also on the Google Cloud.  Prior to uploading these
% scenes to the SDR, I tried rendering them.
%
% 8/27/2024 - Many scenes rendered, but there were some issues.  villa
% failed (though I should be trying with cpu.  Actually, I did and it
% still failed).  A number of the frames failed.  The notes below
% indicate the few failures.
%
% Notes
%
% See also
%   s_bitterliRender, s_iset3dRender

%%
piDockerConfig;
ieDocker = isetdocker;
disp(ieDocker.renderContext)
ieDocker.reset;

% For villa we may need to change the rendering
%{
ieDocker.preset('orange-cpu'); ieDocker.reset;
ieDocker.preset('remote orange'); ieDocker.reset;
%}
%% These all ran this way on Aug 27, 2024.  From Google Drive.

% Use the master directory on the local disk (Toshiba).  The
% interactions with Google drive are slow and awkard.
% bDir = '/Users/wandell/Google Drive/My Drive/Data/PBRT-V4/pbrt-v4-scenes-master';

% Now I decided to use the local USB drive.
bDir = '/Volumes/TOSHIBA EXT/pbrt-v4-scenes-master';

% Get a list of all files and folders in the current directory
allItems = dir(bDir);

% Filter the list to keep only directories
dirFlags = [allItems(:).isdir] & ~strcmp({allItems(:).name}, '.') & ~strcmp({allItems(:).name}, '..');

% Extract the names of the directories
directoryList = allItems(dirFlags);

%%

% Check that you want to do all of these.  I have mostly been
% selecting individuals or small groups
%
for ii=21 %1:numel(directoryList)
    dirName = directoryList(ii).name;
    clear sceneName;

    if ~isequal(dirName(1),'.')  && ~contains(dirName,'webloc') && ~contains(dirName,'.md')
        fprintf('Directory:  %s\n',dirName);
        switch dirName
            case 'barcelona-pavilion'
                sceneName= {'pavilion-night.pbrt','pavilion-night.pbrt'};
            
            case 'bistro'
                sceneName = {'bistro_cafe.pbrt', ...
                    'bistro_boulangerie.pbrt', ...
                    'bistro_vespa.pbrt'};

            case 'bmw-m6'
                % Works with parse
                sceneName = 'bmw-m6.pbrt';

            case 'bunny-cloud' %4
                sceneName = 'bunny-cloud.pbrt';

            case 'bunny-fur' %5
                sceneName = 'bunny-fur.pbrt';

            case 'clouds' %6
                sceneName = 'clouds.pbrt';

            case 'contemporary-bathroom' %7
                sceneName = 'contemporary-bathroom.pbrt';

            case 'crown' %8
                % Works with parse
                sceneName = 'crown.pbrt';

            case 'dambreak' %9
                sceneName = {'dambreak0.pbrt','dambreak1.pbrt'};                

            case 'disney-cloud' %10
                sceneName = 'disney-cloud.pbrt';
                
            case 'explosion' %11
                sceneName = 'explosion.pbrt';
            case 'ganesha' %12
                sceneName = 'ganesha.pbrt';
            case 'hair' %13
                sceneName = 'hair-actual-bsdf.pbrt';
            case 'head'  %14
                sceneName = 'head.pbrt';
            case 'killeroos' %16
                sceneName = {'killeroo-coated-gold.pbrt', 'killeroo-gold.pbrt', 'killeroo-simple.pbrt'};

                % Does not render correctly
                % sceneName = 'killeroo-moving.pbrt';               
            case 'kitchen' %17
                sceneName = 'kitchen.pbrt';
            case 'landscape' %18
                sceneName = {'view-0.pbrt', 'view-1.pbrt', ...
                    'view-2.pbrt', 'view-4.pbrt'};
                % This view does not seem right.
                % sceneName = 'view-3.pbrt';

            case 'lte-orb' %20
                % Works with copy and parse
                sceneName = {'lte-orb-blue-agat-spec.pbrt', ...
                    'lte-orb-rough-glass.pbrt', ...
                    'lte-orb-silver.pbrt', ...
                    'lte-orb-simple-ball.pbrt'};

            case 'pbrt-book' %21
                % Parse passed
                sceneName = 'book.pbrt';

            case 'sanmiguel' %22
                sceneName = {'sanmiguel-balcony-plants.pbrt', ...
                    'sanmiguel-courtyard-second.pbrt', ...
                    'sanmiguel-courtyard.pbrt', ...
                    'sanmiguel-entry.pbrt', ...
                    'sanmiguel-in-tree.pbrt', ...
                    'sanmiguel-realistic-courtyard.pbrt', ...
                    'sanmiguel-upstairs-across.pbrt', ...
                    'sanmiguel-upstairs-corner.pbrt', ...
                    'sanmiguel-upstairs.pbrt'};

            case 'smoke-plume' %23
                sceneName = 'plume.pbrt';
                
            case 'sportscar' %24
                sceneName = {'sportscar-area-lights.pbrt',...
                    'sportscar-sky.pbrt'};

            case 'sssdragon' %25
                sceneName = {'dragon_10.pbrt', ...
                    'dragon_50.pbrt', 'dragon_250.pbrt'};
            
            case 'transparent-machines' %26

                % Most of these don't render correctly.
                % sceneName = 'frame542.pbrt';
                
                % This one seems OK.
                sceneName = 'frame675.pbrt';
                
                % sceneName = 'frame812.pbrt';
                
                % sceneName = 'frame888.pbrt';
                
                % sceneName = 'frame1266.pbrt';
                
            case 'villa' %27
                %{
                [1m[31mWarning[0m: GBufferFilm is not supported by the "bdpt" integrator. The channels other than R, G, B will be zero.
                Rendering: [                                                                                                                                                             ] Segmentation fault
                (core dumped)
                %}
                % Try with CPU.  Failed with GPU so far.
                % ieDocker.preset('orange-cpu'); ieDocker.reset;
                sceneName = {'villa-daylight.pbrt', 'villa-lights-on.pbrt'};

            case 'zero-day' % 28
                sceneName = {'frame25.pbrt', 'frame35.pbrt', ...
                    'frame52.pbrt', 'frame85.pbrt', 'frame120.pbrt',...
                    'frame180.pbrt', 'frame210.pbrt', 'frame300.pbrt', ...
                    'frame380.pbrt'};

            otherwise
                warning('Unknown directory %s.  Skipping.\n',dirName);
                break;
        end

        if iscell(sceneName)
            for jj=1:numel(sceneName)
                scene = renderInternal(bDir,dirName,sceneName{jj});
                try
                    sceneFile = fullfile(bDir,dirName,sceneName{jj});
                    thisR = piRead(sceneFile,'exporter','parse');
                    disp([sceneName, ' Parse passed.'])
                catch
                    disp([sceneName, ' Parse failed.'])
                end
            end
        else
            scene = renderInternal(bDir,dirName,sceneName);
            try
                sceneFile = fullfile(bDir,dirName,sceneName);
                thisR = piRead(sceneFile,'exporter','parse');
                disp([sceneName, ' Parse passed.'])
            catch
                disp([sceneName, ' Parse failed.'])
            end

        end
    end
end

%% ------------------
function scene = renderInternal(bDir,dirName,sceneName)

sceneFile = fullfile(bDir,dirName,sceneName);
thisR = piRead(sceneFile,'exporter','parse');
scene = piWRS(thisR,'gamma',0.5,'name',sceneName,'speed',4);

end

function thisR = parseInternal(bDir,dirName,sceneName)

sceneFile = fullfile(bDir,dirName,sceneName);

end