function output = piReadEXR_python(filename, varargin)
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
% python test
% python installation: https://docs.conda.io/en/latest/miniconda.html
% check version in command window:
%          pe = pyenv;
% run this in mac terminal: 
%          brew install openexr 
%          pip install git+https://github.com/jamesbowman/openexrpython.git
%          pip install pyexr
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
        output = single(py.pyexr.read(filename,'Radiance'));        

        
    case "zdepth"
        output = single(py.pyexr.read(filename,'Pz')); 
        
    case "3dcoordinates"
        output(:,:,1) = single(py.pyexr.read(filename,'Px'));
        output(:,:,2) = single(py.pyexr.read(filename,'Py'));
        output(:,:,3) = single(py.pyexr.read(filename,'Pz'));
        
    case "material"
        output=single(py.pyexr.read(filename,'MaterialId'));
        
    case "normal"
        % to add
    case "albedo"
        % to add; only support rgb for now, spectral albdeo needs to add;
    case "instance"
        % to add
    otherwise
        error('Datatype not supported. \n%s', 'Supported datatypes are: "radiance", "zdepth", "3dcoordinates", "material", "normal";')
end


end