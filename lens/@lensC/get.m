function res = get(obj,pName,varargin)
% Get various derived lensC properties 
%
% Syntax:
%   lensC.get(parameter,varargin)
%
% Parameters:
%    'name'
%    'wave'
%      ...
%
%    'microlens aperture'
%    'microlens radius'
%    'microlens ior'
%    'microlens thickness'
%    'microlens dimensions'
%
% See also
%

pName = ieParamFormat(pName);
switch pName
    % Lens general parameters
    case 'name'
        % Shorter name, without the path.
        res = obj.name;
    case 'fullfilename'
        % Full path
        res = obj.fullFileName;
    case 'wave'
        res = obj.wave;
    case 'nwave'
        res = length(obj.wave);
    case 'type'
        res = obj.type;
        
        % Surface parameters
    case {'nsurfaces','numels'}
        % Should be nsurfaces
        res = length(obj.surfaceArray);
    case {'lensdiameter','diameter','lensheight','lenswidth'}
        % obj.get('diameter',spatialUnit)
        % Total height (diameter) of the front surface element (mm)
        res = obj.surfaceArray(1).apertureD;
        if ~isempty(varargin)
            res = res*ieUnitScaleFactor(varargin{1})*1e-3; 
        end
            
    case {'lensthickness','totaloffset'}
        % This is the size (in mm) from the front surface to
        % the back surface.  The last surface is at 0, so the
        % position of the first surface is the total size.
        sArray = obj.surfaceArray;
        res    = -1*sArray(1).get('zpos');
    case 'offsets'
        % Offsets format (like PBRT files) from center/zPos
        % data
        res = obj.offsetCompute();
    case 'surfacearray'
        % lens.get('surface array',[which surface])
        if isempty(varargin), res = obj.surfaceArray;
        else,                 res = obj.surfaceArray(varargin{1});
        end
    case {'indexofrefraction','narray'}
        % n is often used as the symbol for index of refraction
        % Perhaps we should allow 'ior' here, as well
        nSurf = obj.get('nsurfaces');
        sWave = obj.surfaceArray(1).wave;
        res = zeros(length(sWave),nSurf);
        for ii=1:nSurf
            res(:,ii) = obj.surfaceArray(ii).n(:)';
        end
    case {'asphericcoeff'}
        nSurf = obj.get('nsurfaces');
        res = cell(1, nSurf);
        for ii=1:nSurf
            res{ii} = obj.surfaceArray(ii).asphericCoeff;
        end
    case {'conicconstant'}
        nSurf = obj.get('nsurfaces');
        res = zeros(1, nSurf);
        for ii=1:nSurf
            res(ii) = obj.surfaceArray(ii).conicConstant;
        end
        
    case {'refractivesurfaces'}
        % logicalList = lens.get('refractive surfaces');
        % Returns
        %  1 at the positions of refractive surfaces, and
        %  0 at diaphgrams
        nSurf = obj.get('nsurfaces');
        res = ones(nSurf,1);
        for ii=1:nSurf
            if strcmp(obj.surfaceArray(ii).subtype,'diaphragm')
                res(ii) = 0;
            end
        end
        res = logical(res);
    case {'nrefractivesurfaces'}
        % nMatrix = lens.get('n refractive surfaces')
        %
        % The refractive indices for each wavelength of each
        % refractive surface.  The returned matrix has size
        % nWave x nSurface
        lst = find(obj.get('refractive surfaces'));
        nSurfaces = length(lst);
        nWave = obj.get('nwave');
        res = zeros(nWave,nSurfaces);
        for ii = 1:length(lst)
            res(:,ii) = obj.surfaceArray(lst(ii)).n(:);
        end
    case 'sradius'
        % spherical radius of curvature of this surface.
        % lens.get('sradius',whichSurface)
        if isempty(varargin), this = 1;
        else, this = varargin{1};
        end
        res = obj.surfaceArray(this).sRadius;
    case 'sdiameter'
        % lens.get('s diameter',nS);
        % Aperture diameter of this surface.
        % lens.get('sradius',whichSurface)
        if isempty(varargin), this = 1;
        else, this = varargin{1};
        end
        res = obj.surfaceArray(this).apertureD;
    case {'diaphragm','diaphragmindex','apertureindex'}
        % lens.get('aperture index')  mm, I think
        % Returns the surface number corresponding to the limiting aperture
        % (diaphragm)
        s = obj.surfaceArray;
        for ii=1:length(s)
            if strcmp(s(ii).subtype,'diaphragm')
                res = ii;
                return;
            end
        end
    case 'aperturesample'
        % Number of samples of the aperture?   Not sure.
        res =  obj.apertureSample ;
    case {'middleaperturediameter','aperturediameter','middleapertured','aperturemiddled','diaphragmdiameter'}
        % There is normally a middle aperture, called a diaphragm. This is
        % the diameter of the diaphragm.
        %
        % units are mm
        idx = obj.get('aperture index');
        res = obj.surfaceArray(idx).apertureD;
        
        % System properties
    case {'focallength'}
        % Film distance for a point at infinity.  
        % Units are millimeters.
        % lens.get('focal length')
        % lens.get('focal length',600)
        thisWave = 550;
        if ~isempty(varargin), thisWave = varargin{1}; end
        
        % A billion millimeters seems far enough for a focal length
        % We could run a billion and 10 billion and check for no
        % difference.
        % res = lensFocus(obj,10^9,'wavelength',wave);
        wave = obj.get('wave');
        res = obj.get('bbm', 'effective focal length');
        res = interp1(wave(:), res(:), thisWave);
    case {'infocusdistance'}
        % Distances are in millimeters
        %
        % distance = 50; wave = 550;
        % lens.get('infocus distance',distance,wave)
        % 
        % Find the film distance to focus an object at a particular
        % distance and wavelength.  Defaults to returning focal length at
        % 550 nm if there are no varargin entries.
        %
        % The returned 
        objectDistance = 10^9; 
        wave = 550;
        if length(varargin) > 1
            wave = varargin{2}; objectDistance = varargin{1};
        elseif length(varargin) == 1
            objectDistance = varargin{1};
        end
        res = lensFocus(obj,objectDistance,'wavelength',wave);
    case {'fov', 'fieldofview'}
        % lens.get('fov', filmSzInmm);
        focalLength = obj.get('focal length');
        if isempty(varargin)
            warning('Using default film size with 1 mm.')
            filmSz = 1;
        else
            filmSz = varargin{1};
        end
        res = 2 * atand(filmSz/2/focalLength);
    case {'blackboxmodel';'blackbox';'bbm'}
        % The BLACK BOX MODEL (bbm).
        % lens.get('bbm',param)
        param = varargin{1};  % Which field of the black box to get
        res = obj.bbmGetValue(param);
        
    case {'lightfieldtransformation';'lightfieldtransf';'lightfield'}
        % The light field parameters (ABCD) of the BLACK BOX MODEL
        % lens.get('light field transformation','2d');
        if nargin >2
            param = varargin{1};  %witch field of the black box to get
            param = ieParamFormat(param);
            switch param
                case {'2d'}
                    res = obj.bbmGetValue('abcd');
                case {'4d'}
                    abcd = obj.bbmGetValue('abcd');
                    nW = size(abcd,3);
                    dummy = eye(4);
                    abcd_out = zeros(2,2,nW);
                    for li=1:nW
                        abcd_out(:,:,li)=dummy;
                        abcd_out(1:2,1:2,li)=abcd(:,:,li);
                    end
                    res = abcd_out;
                otherwise
                    error('Unknown parameter: %s',param);
            end
        else
            res = obj.bbmGetValue('abcd');
        end
    case {'opticalsystem','optsyst','opticalsyst'}
        % The optical system structure generated by Michael Pieroni's
        % script.
        % lens.get('optical system',n_ob,n_im);
        % lens.get('optical system');   % In this case n_ob and n_im are 1
        if nargin >2
            n_ob=varargin{1};    n_im=varargin{2};
            OptSyst=obj.bbmComputeOptSyst(n_ob,n_im);
        else
            OptSyst=obj.bbmComputeOptSyst();
        end
        res = OptSyst;
        
        % Could be pulled out into microlensGet and the 'microlens' name
        % could be detected at the top of the file, like oiGet and 'optics'
        % stuff.
        %
        % Also, could allow user to specify just one of the surfaces for,
        % say, the aperture or radius or ...
    case {'microlensarray'}
        % Microlens array dimensions (nrow, ncol)
        % Or maybe ncol,nrow (xdim,ydim)
        res = obj.microlensarray;
        
    case {'microlensaperture'}
        % Apertures of the all the microlens surfaces
        nSurfaces = numel(obj.microlens.surfaces);
        res = zeros(1,nSurfaces);
        for ii=1:nSurfaces
            res(ii) = obj.microlens.surfaces(ii).semi_aperture;
        end
        res = res*2;
        
    case {'microlensradius'}
        % Radius of curvature of all the microlens surfaces
        nSurfaces = numel(obj.microlens.surfaces);
        res = zeros(nSurfaces,1);
        for ii=1:nSurfaces
            res(ii) = obj.microlens.surfaces(ii).radius;
        end
        
    case {'microlensior'}
        % Index of refraction of the microlens surfaces
        % Each number refers to the next medium after this surface
        nSurfaces = numel(obj.microlens.surfaces);
        res = zeros(nSurfaces,1);
        for ii=1:nSurfaces
            res(ii) = obj.microlens.surfaces(ii).ior;
        end
        
    case {'microlensnsurfaces'}
        % Number of surfaces in the microlens
        % Could calculate the number of refractive surfaces, say with a
        % logical index, as above.
        res = numel(obj.microlens.surfaces);
       
    case {'microlensthickness'}
        % Thickness of the microlens surfaces
        nSurfaces = numel(obj.microlens.surfaces);
        res = zeros(nSurfaces,1);
        for ii=1:nSurfaces
            res(ii) = obj.microlens.surfaces(ii).thickness;
        end
       
    otherwise
        error('Unknown parameter %s\n',pName);
end

end