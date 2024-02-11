function [combinedLensName, info]  = piMicrolensInsert(microLens,imagingLens,varargin)
% Combine a microlens with an imaging lens into a PBRT lens file (json)
%
% Syntax
%   [combinedLensName, info]  = piMicrolensInsert(microLens,imagingLens,varargin)
%
% Brief description:
%   Create a JSON file that combines the imaging and microlens array
%   information. The file will be used by PBRT for the omni camera
%   rendering, which handles microlenses.
%   
% Inputs:
%   microLens   - Microlens file name or a lensC of the lens
%   imagingLens - Imaging lens file name or a lensC of the lens
%
% Optional key/value pairs
%   output name   - File name of the output combined lens
%   nMicrolens    - 2-vector for row/col, if not sent in the default
%                   is the number of microlenses needed to cover the
%                   film, spaced by 1 uLens diameter
%   filmsize      - 2-vector for width/height (x,y) in mm.  If not
%                   sent in the default is make the size match
%                   nMicrolens, spaced by 1 uLens diameter.
%   offsets       - Create a microlens offset for each pixel (meters).
%                   Size is [prod(nMicrolens),2] (Default is all zeros)
%   offsetmethod  - Name a method to compute the offsets ('default'
%                   is use what is sent in.  'linear' creates an array.)
%   maxoffset     - Set the maximum microlens offset for the 'linear'
%                   method.
%
% Output
%   combinedLensName - Full path to the output file
%   info - Struct with information about the combined lens file.
%          Parameters include the struct saved in the JSON file
%          (combinedLens) and the filmSize, uLens and iLens.
%
% See also
%   piMicrolensWrite, lens2pbrt (internal)

% Examples:
%{
 chdir(fullfile(piRootPath,'local'));
 microLens   = lensC('file name','microlens.json');
 imagingLens = lensC('file name','dgauss.22deg.3.0mm.json');
 combinedLens = piMicrolensInsert(microLens.get('full filename'),imagingLens.get('full filename'));
 thisLens = jsonread(combinedLens);
%}

%% Programming TODO
%
% To set the distance between the microlens and the film, you can adjust a
% parameter in the OMNI camera.  The command is (ask Thomas)
%
%   thisR.set(....)
%

%% Parse inputs

varargin = ieParamFormat(varargin);

p = inputParser;

% Input can be the filename of the lens or the lens object
vFile = @(x)(isa(x,'lensC') || (ischar(x) && exist(x,'file')));
p.addRequired('imagingLens',vFile);
p.addRequired('microLens',vFile);

% Optional
p.addParameter('outputname','',@ischar);     % JSON file name
p.addParameter('nmicrolens',[],@isvector);   % number of x,y (col, row)
p.addParameter('filmsize',[],@isscalar);     % x,y (width, height) mm
p.addParameter('quiet',false,@islogical);    % Suppress print out

% For the linear method, the default max offset is one half of the
% microlens diameter.  But you can set the value (in mm) through the
% maxoffset parameter.
p.addParameter('maxoffset',[],@isscalar);    % x,y (width, height) mm

vMethods = {'default','linear'};
p.addParameter('offsetmethod','default',@(x)(ismember(x,vMethods)));

p.parse(imagingLens,microLens,varargin{:});

nMicrolens   = p.Results.nmicrolens;  % (x,y)
filmSize     = p.Results.filmsize;
offsetMethod = p.Results.offsetmethod;
maxOffset    = p.Results.maxoffset;

%%  Create the iLens and mLens (lensC) objects

% If a lensC was input, the  data in the lensC might have been modified
% from its original state. So we write out a copy of the JSON file in the
% current working directory and use this copy as input for the PBRT
% rendering. 
if isa(imagingLens,'lensC')
    thisName = fullfile(pwd,[imagingLens.get('name'),'.json']);
    imagingLensName = imagingLens.fileWrite(thisName);
else
    imagingLensName = imagingLens;
end
iLens = lensC('file name',imagingLensName);

if isa(microLens,'lensC')
    thisName = fullfile(pwd,[microLens.get('name'),'.json']);
    microLensName = microLens.fileWrite(thisName);     
else
    microLensName = microLens;
end
uLens = lensC('file name',microLensName);

% Create the file name for the combined file.
if isempty(p.Results.outputname)
    [~,imagingLensName,~] = fileparts(imagingLensName);
    [~,microLensName,e]   = fileparts(microLensName); 
    combinedLensName = fullfile(pwd,sprintf('%s+%s',imagingLensName,[microLensName,e]));
else
    combinedLensName = p.Results.outputname;
end

%% Set up dimension and film parameters

% We use the microlens diameter for various calculations below.
ulensDiameterMM = uLens.get('lens diameter','mm');

if isempty(filmSize) && isempty(nMicrolens)
    warning('No film size or nMicrolens.  Using 1.1 x 1.1 mm film size');
    filmSize = [1.1 1.1];
    % We know the film size, so calculate the nMicrolens
    nMicrolens(1) = floor(filmSize(1)/ulensDiameterMM);
    nMicrolens(2) = floor(filmSize(2)/ulensDiameterMM);
elseif isempty(nMicrolens)
    % We know the film size, so calculate the nMicrolens.  Must be an
    % integer.
    nMicrolens(1) = floor(filmSize(1)/ulensDiameterMM);
    nMicrolens(2) = floor(filmSize(2)/ulensDiameterMM);
elseif isempty(filmSize)
    % We know nMicrolens, so calculate filmSize.  
    filmSize(1) = nMicrolens(1)*ulensDiameterMM;  % mm
    filmSize(2) = nMicrolens(2)*ulensDiameterMM;
end

%% Build the offsets

% Default offsets is all zeroes
switch offsetMethod
    case 'default'
        offsets = zeros(prod(nMicrolens),2);
    case 'linear'
        % Scale the microlens positions by field height.  They move
        % progressively towards the center.  At the farthest corner
        % they are moved by one half the microlens diameter.
        
        ulensDiameterM = ulensDiameterMM*1e-3;
        % Find the X,Y positions of each microlens.  We use units of
        % meters here, converting from mm.
        xPos = (1:nMicrolens(1))*ulensDiameterM; xPos = xPos - mean(xPos);
        yPos = (1:nMicrolens(2))*ulensDiameterM; yPos = yPos - mean(yPos);
        [X,Y] = meshgrid(xPos,yPos);

        % Scale offsets so that the maximum allowed offset occurs
        % for the microlens furthest from the center (meters)
        if isempty(maxOffset)
            maxOffset = ulensDiameterM/2; % Default maximum offset
        else
            maxOffset = p.Results.maxoffset;
        end

        dist = sqrt(X.^2 + Y.^2);
        offset_dist = maxOffset * (dist ./ max(dist(:)));
        offset_dir = 1./dist(:).*[X(:) Y(:)];

        % The microlenses are displaced towards the center, so we must
        % multiply the direction by -1.
        offsets = -1*flip(offset_dir,2).*offset_dist(:);        
        
        %{
        ieNewGraphWin; plot(X(:) + offsets(:,1),Y(:)+offsets(:,2),'.')
        hold on; plot(X(:),Y(:),'b.')
        %}

    otherwise
        error('Unknown offset method %s\n',offsetMethod);
end


%% Print out parameter summary
if ~p.Results.quiet
    fprintf('\n------\nMicrolens insertion summary\n');
    fprintf('Microlens array (x,y) %d, %d\n',nMicrolens(1),nMicrolens(2));
    fprintf('Film width and height %0.2f, %0.2f mm\n',filmSize(1),filmSize(2));
    fprintf('------\n');
end

%% Create the struct and JSON file for PBRT from the lens information

combinedLens.description = iLens.description;
combinedLens.microlens = [];
combinedLens.name = [imagingLensName,' + ',microLensName];
combinedLens.surfaces = lens2pbrt(iLens);
combinedLens.type = iLens.type;

combinedLens.microlens.dimensions = nMicrolens(:);
combinedLens.microlens.offsets    = offsets;
combinedLens.microlens.surfaces   = lens2pbrt(uLens);

jsonwrite(combinedLensName,combinedLens);

% Offsets (info.microlens.offset) and nMicrolenses
% (info.microlens.dimension) are inthe combinedLens struct 
info.combinedLens = combinedLens;
info.filmSize = filmSize;
info.uLens = uLens;
info.iLens = iLens;
if exist('X','var')
    info.X = X;
    info.Y = Y;
end


end


%% lens2pbrt 

function surfaces = lens2pbrt(uLens)
% Convert a lensC into the structs needed to write the PBRT lens file
%
% surfaces is an array of structs that will be written to the lens json
% file.

if ~numel(unique(uLens.surfaceArray(1).n)) == 1
    warning('Index of refraction is not constant.  Fix this code to work with a spectral IOR!!!')
end

% For each surface in the surface array
surfaceArray = uLens.surfaceArray;
for ii=1:numel(surfaceArray)
    thisSurf = surfaceArray(ii);
    surfaces(ii).conic_constant = thisSurf.conicConstant;  %#ok<*AGROW> % Or {}.  To check

    % We should check that the IOR is the same for all the wavelengths
    % for this surface.  If it is not, warn.
    surfaces(ii).ior = thisSurf.n(1);
    surfaces(ii).radius = thisSurf.sRadius;
    surfaces(ii).semi_aperture = thisSurf.apertureD/2;

    % Distance between the surfaces
    offsetLists = uLens.get('offsets');
    % PBRT files need the distance between the surfaces.
    surfaces(ii).thickness = offsetLists(ii);
end

end
