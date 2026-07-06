function fullFileName = fileWrite(obj, fullFileName, varargin)
% Writes PBRT lens file, either as text of JSON
%
% Syntax:
%   fullFileName = lens.fileWrite(fullFileName, varargin)
%
% Description:
%  The PBRT file has focal length information added to the header. This
%  function converts the PBRT matrix of data into the format that Scene3d
%  uses for a multi-element lens.
%
%  The PBRT lens file looks like this:
%
% # Name: 2ElLens
% # Description: foobar
% # units are mm
% # Focal length
% 50.000
%
% # Each row is a surface.
% # They are ordered from the image to the sensor.
% # Zero is the position of the first lens surface.
% # Positive is towards the sensor (right).
% # Negative is towards the scene (left).
% #  radius	    axpos		N		    aperture
% 67.000000	    1.500000	1.650000	25.000000
% 0.000000	    1.500000	1.650000	25.000000
% -67.000000	0.000000	1.000000	25.000000
%
% The bottom row is the rightmost surface; its z-axis position (axpos) is
% always 0. The radius of curvature is the (directional) distance to the
% center of sphere. Because it is negative, the center is 67 mm towards the
% scene. Thus, the surface is curved like a backwards 'C'. The index of
% refraction is to the right of the surface; for the first surface it will
% generally be air (1), assuming that there is air between the lens and
% sensor.  Of course, for the human eye, that is not the case.
%
% The 2nd row has an axpos of 1.5 mm, which means it is shifted 1.5mm
% towards the scene. Its radius is 0, which means it's an aperture. The
% material between this position and the previous surface is glass (N =
% 1.65).
%
% The first row axpos is 1.5 mm from the previous surface. It has a center
% to the right, so the shape is a 'C'.  The material is still glass.
%
% The lens class stores parameters in a different format. We don't use
% offsets; instead, we store the sphere centers (sCenters) and radii (units
% of mm).  The fileRead and fileWrite code convert between these
% representations.  In fileWrite the conversion is managed by the
% lensMatrix routine.
%
% AL/BW VISTASOFT, Copyright 2014
%
% See also:
%   lensMatrix, lensHeader

% Examples:
%{
  % Read and write a lens all in millimeters
  l = lensC;
  l.fileWrite('deleteme.dat','description','foobar','units','mm');
%}
%{
  % Read a lens in millimeters.  Write it in meters
  l = lensC;
  l.fileWrite('deleteme.dat','description','foobar','units','m');
%}
%{
  l = lensC;
  l.fileWrite('deleteme.json','description','foobar','units','mm');
  edit('deleteme.json');
  l.fileRead('deleteme.json');
  l.draw;
%}

%%
p = inputParser;

p.addRequired('fullFileName',@ischar);
p.addParameter('description',obj.type,@ischar);
p.addParameter('units','mm',@(x)(ismember(x,{'um','mm','m'})));

% Full files should have a first character that is '/' on Macs.   Ask Dave
% what to check on a Windows machine.
if ismac || isunix
    assert(fullFileName(1) == '/');
else
    warning('Cannot check for full path on Windows yet\n%s\n',fullFileName);
end

p.parse(fullFileName,varargin{:});

obj.fullFileName = fullFileName;

unitScale   = p.Results.units;
description = sprintf('# Description: %s\n',p.Results.description);
description = addText(description,sprintf('# units are %s',unitScale));

switch unitScale
    case 'um'
        % Values are in microns, so multiply by 1000 to bring to millimeters
        unitScale = 1e3;
    case 'mm'
        unitScale = 1;
    case 'm'
        % Values are in meters, so divide by 1000 to bring to millimeters
        unitScale = 1e-3;
    otherwise
        error('Unknown spatial scale');
end

[~,~,e] = fileparts(fullFileName);
if strcmp(e,'.json'),    fileFormat = 'json';
elseif strcmp(e,'.txt'), fileFormat = 'txt';
elseif strcmp(e,'.dat'), fileFormat = 'txt';
end

%% Tell the person if we are over-writing a lens file
if ~exist(fullFileName,'file')
else,  fprintf('Overwriting %s\n',fullFileName)
end

switch fileFormat
    case 'txt'
        
        % fullFileName = fullfile(dataPath, 'rayTrace', 'dgauss.50mm.dat');
        fid = fopen(fullFileName,'w');

        %% Write the header
        hdr = lensHeader(obj,description,unitScale);
        fprintf(fid,'%s',hdr);
        
        %% Write the data matrix
        d  = lensMatrix(obj);
        
        % Columns 1 2 and 4 are corrected for spatial scale
        d(:,1) = d(:,1)*unitScale;
        d(:,2) = d(:,2)*unitScale;
        d(:,4) = d(:,4)*unitScale;
        
        % Column 3 is
        for ii=1:size(d,1)
            fprintf(fid,'%f\t%f\t%f\t%f\n', d(ii,1), d(ii, 2), d(ii,3), d(ii,4));
        end
        
        fclose(fid);
        
    case 'json'
        % Making the JSON output from the isetlens lensC object  
        
        dataMatrix  = lensMatrix(obj);
        sAsphericCoeff = obj.get('aspheric coeff');
        sConicConstant = obj.get('conic constant');
        dataMatrix  = round(dataMatrix*1e5)/1e5;
        nSurfaces = size(dataMatrix,1);
        jsonLens.name = obj.name;
        jsonLens.description = obj.description;
        jsonLens.type = obj.type;
        
        for ii=1:nSurfaces
            jsonLens.surfaces(ii).radius    = dataMatrix(ii,1);
            jsonLens.surfaces(ii).thickness = dataMatrix(ii,2);
            jsonLens.surfaces(ii).ior       = dataMatrix(ii,3);
            jsonLens.surfaces(ii).semi_aperture = dataMatrix(ii,4)/2;
            if ~isempty(sAsphericCoeff{ii})
                jsonLens.surfaces(ii).aspheric_coefficients = sAsphericCoeff{ii};
            end
            if sConicConstant(ii) ~= 0
                jsonLens.surfaces(ii).conic_constant = sConicConstant(ii);
            end
        end
        
        % If it has microlens data, add it and store it
        if ~isempty(obj.microlens)
            jsonLens.microlens = obj.microlens;
        end
        
        opts.indent = ' ';
        jsonwrite(fullFileName,jsonLens,opts)
        
    otherwise
        error('Unknown file format %s\n');
        
end

end

%% The header
function hdr = lensHeader(obj, description, unitScale)

hdr = sprintf('# Name: %s\n',obj.name);

str = sprintf('%s\n',description);
hdr = addText(hdr,str);

str = sprintf('# Focal length \n');
hdr = addText(hdr,str);

str = sprintf('%.3f\n\n',obj.focalLength*unitScale);
hdr = addText(hdr,str);

str = sprintf('# Each row is a surface.\n');
hdr = addText(hdr,str);

str = sprintf('# They are ordered from the image to the sensor.\n');
hdr = addText(hdr,str);

str = sprintf('# Zero is the position of the first lens surface.\n');
hdr = addText(hdr,str);

str = sprintf('# Positive is towards the sensor (right).\n# Negative is towards the scene (left).\n');
hdr = addText(hdr,str);

str = sprintf('# radius \t axpos \t N \t aperture\n');
hdr = addText(hdr, str);

end

%%
