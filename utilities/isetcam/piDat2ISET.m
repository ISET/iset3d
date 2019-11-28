function ieObject = piDat2ISET(inputFile,varargin)
% Read a dat-file rendered by PBRT, and return an ieObject or a metadataMap
%
%    ieObject = piDat2ISET(inputFile,varargin)
%
% Brief description:
%    We take a dat-file from pbrt as input. We return an optical image.
%
% Inputs
%   inputFile -  Multi-spectral dat-file generated by pbrt.
%
% Optional key/value pairs
%   label            -  Specify the type of data: radiance, mesh, depth.
%                       Default is radiance
%   recipe           -  The recipe used to create the file
%   mean luminance   -  Set the mean illuminance
%   mean luminance per mm2 - Set the mean illuminance per square pupil mm
%   scaleIlluminance -  if true, we scale the mean illuminance by the pupil
%                       diameter.
%
% Output
%   ieObject: if label is radiance: optical image;
%             else, a metadatMap
%
% Zhenyi/BW SCIEN Stanford, 2018
%
% See also
%   piReadDAT, oiCreate, oiSet

%% Examples
%{
 opticalImage = piDat2ISET('radiance.dat','label','radiance','recipe',thisR);
 meshImage    = piDat2ISET('mesh.dat','label','mesh');
 depthImage   = piDat2ISET('depth.dat','label','depth');
%}

%%
p = inputParser;
varargin =ieParamFormat(varargin);
p.addRequired('inputFile',@(x)(exist(x,'file')));
p.addParameter('label','radiance',@(x)ischar(x));

p.addParameter('recipe',[],@(x)(isequal(class(x),'recipe')));
p.addParameter('meanluminance',100,@isnumeric);
p.addParameter('meanilluminancepermm2',5,@isnumeric);
p.addParameter('scaleilluminance',true,@islogical);

p.parse(inputFile,varargin{:});
label       = p.Results.label;
thisR       = p.Results.recipe;
meanLuminance         = p.Results.meanluminance;
meanIlluminancepermm2 = p.Results.meanilluminancepermm2;
scaleIlluminance      = p.Results.scaleilluminance;

%% Depending on label, assign the output data properly to ieObject

wave = 400:10:700; % Hard coded in pbrt
nWave = length(wave);
if(strcmp(label,'radiance'))
    
    % The PBRT output is in energy units.  Scenes and OIs data are
    % represented in photons
    energy = piReadDAT(inputFile, 'maxPlanes', nWave);
    photons = Energy2Quanta(wave,energy);
    
    % The scaling factor comes from the display primary units. In
    % PBRT the display primaries are normalized to 1, the scaling
    % factor to convert back to real units is then reapplied here.
    %
    % OLD:  photons = Energy2Quanta(wave,energy)*0.003664;
    %
elseif(strcmp(label,'depth') || strcmp(label,'mesh')||strcmp(label,'material') )
    tmp = piReadDAT(inputFile, 'maxPlanes', nWave);
    metadataMap = tmp(:,:,1); clear tmp;
    ieObject = metadataMap;
    return;
elseif(strcmp(label,'coordinates'))
    tmp = piReadDAT(inputFile, 'maxPlanes', nWave);
    coordMap = tmp(:,:,1:3); clear tmp;
    ieObject = coordMap;
    return;
end

%% Read the data and set some of the ieObject parameters

% Only do the following if the recipe exists, otherwise just return the
% data
if(isempty(thisR))
    warning('Recipe not given. Returning photons directly.')
    ieObject = photons;
    return;
end

% Create a name for the ISET object
pbrtFile   = thisR.outputFile;
[~,name,~] = fileparts(pbrtFile);
ieObjName = sprintf('%s-%s',name,datestr(now,'mmm-dd,HH:MM'));

% If radiance, return a scene or optical image
opticsType = thisR.get('optics type');
switch opticsType
    case 'lens'
        % If we used a lens, the ieObject is an optical image (irradiance).
        
        % We specify the mean illuminance of the OI mean illuminance
        % with respect to a 1 mm^2 aperture. That way, if we change
        % the aperture, but nothing else, the illuminance level will
        % scale correctly.

        % Try to find the optics parameters from the lensfile in the
        % PBRT recipe.  The function looks for metadata, if it cannot
        % find that slot it tries to decode the file name.  The file
        % name part should go away before too long because we can just
        % create the metadata once from the file name.
        [focalLength, fNumber] = piRecipeFindOpticsParams(thisR);
        
        % Start building the oi
        ieObject = piOICreate(photons);
        
        % Set the parameters the best we can from the lens file.
        if ~isempty(focalLength)
            ieObject = oiSet(ieObject,'optics focal length',focalLength); 
        end
        if ~isempty(fNumber)
            ieObject = oiSet(ieObject,'optics fnumber',fNumber); 
        end
        
        % Calculate and set the oi 'fov' using the film diagonal size
        % and the lens information.  First get width of the film size.
        % This could be a function inside of get.
        filmDiag = thisR.get('film diagonal')*10^-3;  % In meters
        res      = thisR.get('film resolution');
        x        = res(1); y = res(2);
        d        = sqrt(x^2 + y^2);        % Number of samples along the diagonal
        filmwidth   = (filmDiag / d) * x;  % Diagonal size by d gives us mm per step
        
        % Next calculate the fov
        focalLength = oiGet(ieObject,'optics focal length');
        fov         = 2 * atan2d(filmwidth / 2, focalLength);
        ieObject    = oiSet(ieObject,'fov',fov);
        
        ieObject = oiSet(ieObject,'name',ieObjName);

        ieObject = oiSet(ieObject,'optics model','iset3d');
        if ~isempty(thisR)
            lensfile = thisR.get('lens file');
            ieObject = oiSet(ieObject,'optics name',lensfile);
        else
            warning('Render recipe is not specified.');
        end
        
        % We set meanIlluminance per square millimeter of the lens
        % aperture.
        if(scaleIlluminance)
            aperture = oiGet(ieObject,'optics aperture diameter');
            lensArea = pi*(aperture*1e3/2)^2;
            meanIlluminance = meanIlluminancepermm2*lensArea;
            
            ieObject        = oiAdjustIlluminance(ieObject,meanIlluminance);
            ieObject.data.illuminance = oiCalculateIlluminance(ieObject);
        end
        
    case {'pinhole','environment'}
        % A scene radiance, not an oi
        ieObject = piSceneCreate(photons,'meanLuminance',meanLuminance);
        ieObject = sceneSet(ieObject,'name',ieObjName);
        if ~isempty(thisR)
            % PBRT may have assigned a field of view
            ieObject = sceneSet(ieObject,'fov',thisR.get('fov'));
        end
        
    otherwise
        error('Unknown optics type %s\n',opticsType);       
end

%% Adjust the illuminant

% Usually there is a light inside of the spds directory.  In some
% cases, however, there is no light (e.g. the teapot scene).  So we
% check and add the light if it is there.
lightSourcePath = fullfile(fileparts(thisR.outputFile), 'spds', 'lights', '*.mat');
fileInfo = dir(lightSourcePath);
if ~isempty(fileInfo)
    if numel(fileInfo.name) ~= 1
        warning('Multiple light sources.  Not assigning a light to the scene. We will calculate the illuminant image and assign it - some day.'); 
    else
        illuEnergy = ieReadSpectra(fullfile(fileInfo.folder, fileInfo.name),wave);
        ieObject = sceneSet(ieObject, 'illuminant Energy', illuEnergy);
    end
end

end


