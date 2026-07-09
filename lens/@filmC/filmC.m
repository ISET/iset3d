classdef filmC <  matlab.mixin.Copyable
    % Create a filmC
    %
    % Was clonableHandleObject
    %
    % Initiated by property/val pairs
    %
    %  film = filmC('position',val,'size',val,'wave',val,'resolution',val);
    %
    % Spatial units throughout are mm
    %
    % The film properties are
    %
    %   position   - film position in lens coordinate frame
    %   size       - film size in millimeters (height, width)
    %   wave       - wavelengths
    %   resolution - Number of spatial samples (pixels) in the film plane
    %
    % Example:
    % wave = 500; sz = [10,10]; pos = [0 0 20]; res = [150 150 1];
    % smallFilm = filmC('position', pos, 'size', sz, 'wave', wave, 'resolution', res);
    %
    % AL Vistasoft Copyright 2014
    
    properties
        position = [ 0 0 100];     % x,y,z in mm
        size = [48 48];            % in mm (Too big).
        wave = 400:50:700;         % nanometers (nm)
        resolution = [200 200];    % row/col size
        image;                     % We store image data here
    end
    
    methods
        
        %default constructor
        function obj = filmC(varargin)
            
            %TODO: error checking.  make sure all dimensions are good
            % Use the inputParser for error checking.  For the moment we
            % are checking in parameterAssign
            
            %loop through all parameters and assign them
            for ii=1:2:length(varargin)
                p = ieParamFormat(varargin{ii});
                
                val = varargin{ii+1};
                obj = obj.parameterAssign(p, val);
                
            end
                        
            % AL assigned resolution to (nX,nY,nW)
            % Not sure this is a good idea.  Leave wave off, I think. (BW)
            % obj.resolution(3) = length(obj.wave);
            %
            % Image is spectral: [row, col, wave]
            obj.image = zeros([obj.resolution,length(obj.wave)]);
        end
        
        % This should become set!
        function obj = parameterAssign(obj, p, val)
            %helper function for default constructor, assigns values (val)
            %to parameters (p) of class
            switch p
                case 'position'
                    if length(val) ~= 3, error('film position error'); end
                    obj.position = val;
                case 'size'
                    if length(val) ~= 2, error('film size error'); end
                    obj.size = val;
                case 'wave'
                    obj.wave = val;
                case 'resolution'
                    if length(val) ~= 2, error('film resolution error'); end
                    obj.resolution = val;
                otherwise
                    error('Unknown parameter %s\n',val);
            end
        end
  
    end
    
end