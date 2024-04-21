function output = piReadEXR(filename, varargin)
%% Read multispectral data from a .exr file (Openexr format)
%
%   [imageData, imageSize, lens] = piReadEXR(filename)
%
% Required Input
%   filename - existing .exr file
%
% Optional parameter/val
%   dataType - specify the type of data for the output
%   NSpectrumSamples - number of spectrum samples
%
% Returns
%  
% Read .exr image data from the fiven filename.
%
%
% Zhenyi, 2020
% 
% 
% Get exr channel information
%{
      data = exrinfo(filename);
      fprintf( '%s \n', data.channels{:} ); fprintf('\n')
%}   

%% 
parser = inputParser();
varargin = ieParamFormat(varargin);

parser.addRequired('filename', @ischar);
parser.addParameter('datatype', 'radiance', @ischar);

parser.parse(filename, varargin{:});
filename = parser.Results.filename;
dataType = parser.Results.datatype;

%%

switch dataType
    case "radiance"
        output = piEXR2Mat(filename, 'Radiance');
    case "zdepth"
        output = piEXR2Mat(filename, 'P.Z');
    case "alldepth"
          allDepthMap = piEXR2Mat(filename, ['P.X', 'P.Y', 'P.Z']);
          output = sqrt(allDepthMap.^2);
    case "depth"
        % We only want to sum the depths that we have, so we need to 
        % look for errors when we retrieve each one
        try
            XDepthMap = piEXR2Mat(filename, 'P.X');
        catch
            XDepthMap = 0;
        end
        try
            YDepthMap = piEXR2Mat(filename, 'P.Y');
        catch
            YDepthMap = 0;
        end
        try
            ZDepthMap = piEXR2Mat(filename, 'P.Z');
        catch
            ZDepthMap = 0;
        end
        output = sqrt(XDepthMap.^2+YDepthMap.^2+ZDepthMap.^2);
    case "3dcoordinates"
        try
            output(:,:,1) = piEXR2Mat(filename, 'P.X');
            output(:,:,2) = piEXR2Mat(filename, 'P.Y');
        catch
            warning('Missing a Px or Py depth channel');
        end
        try
            output(:,:,3) = piEXR2Mat(filename, 'P.Z');
        catch
            output(:,:,3) = piEXR2Mat(filename, 'Pz');
        end
    case "material" % single channel
        output = piEXR2Mat(filename, 'MaterialId');
    case "normal"
        output(:,:,1) = piEXR2Mat(filename, 'N.X');
        output(:,:,2) = piEXR2Mat(filename, 'N.Y');
        output(:,:,3) = piEXR2Mat(filename, 'N.Z');
    case "albedo"
        % albedo contains three "sub-channels" that are B, G, R in order
        output(:,:,1) = piEXR2Mat(filename, 'Albedo.R');
        output(:,:,2) = piEXR2Mat(filename, 'Albedo.G');
        output(:,:,3) = piEXR2Mat(filename, 'Albedo.B');
    case "instanceId" % single channel
        output = piEXR2Mat(filename, 'InstanceId');
    otherwise
        error('Datatype not supported. \n%s', 'Supported datatypes are: "radiance", "zdepth", "3dcoordinates", "material", "normal", "albedo"');
end


end
