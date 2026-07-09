classdef psfCameraC <  handle
    % Create a point spread camera object
    %
    % This camera is designed to calculate the point spread function given
    % lens and film information.  The point can be at many different
    % positions, so we can calculate a Volume of data, as well.
    %
    % The camera can be used in two modes.  We  either  calculate simple
    % PSFs or we calculate the plenoptic PSF, which means the light
    % field of rays at the input, middle, and exit apertures.
    %
    % Spatial units throughout are mm
    %
    % The data (image) in the film object is cleared by default when the
    % psfCamera is created.  But if you would like to add multiple points,
    % you can set the clearfilm flag to false, and the image in the film
    % will not be cleared.
    %
    % Examples:
    %  lens = lensC; film = filmC; ps = [0 -5 -101.5];
    %  psfCamera = psfCameraC('lens',lens,'film',film,'pointsource',ps);
    %
    % NOT WORKING. CHECK WHY.
    %  psArray = [0 -5 -101.5; 0 -0 -100.5];
    %  psfCamera = psfCamera('lens',lens,'film',film,'pointsource',psArray);
    %
    % AL Vistasoft Copyright 2014
    
    properties
        name = 'default camera';
        
        lens = [];        % lensC
        film = [];        % filmC
        pointSource = []; % point source.  Should become an object
        
        rays;       % Rays, at different points during the computation
        
        BBoxModel;  % Black box model related to Michael Pieroni functions
        fftPSF;     % Not sure this is, but connected to MP, I think.
    end
    
    methods (Access = public)
        
        %default constructor
        function obj = psfCameraC(varargin)
            % psfCameraC('lens',lens,'film',film,'pointsource',point);
            p = inputParser;
            p.CaseSensitive = false;
            
            varargin = ieParamFormat(varargin);
            p.addParameter('lens',[],@(x)(isa(x,'lensC')));
            p.addParameter('film',[],@(x)(isa(x,'filmC')));
            p.addParameter('clearfilm',true,@islogical);
            p.addParameter('blackboxmodel',[],@isstruct);
            p.addParameter('pointsource',[],@iscell);
            p.addParameter('fftpsf',[],@(x)(isa(x,'lensC')));   % This was set to lens.
            
            p.parse(varargin{:});
            obj.lens = p.Results.lens;
            obj.film = p.Results.film;
            obj.pointSource = p.Results.pointsource;
            obj.BBoxModel = p.Results.blackboxmodel;
            % obj.lens = varargin{ii+1};
            obj.fftPSF = p.Results.fftpsf; % This was set to lens.
            
            % Always clear the film on a create
            if p.Results.clearfilm, obj.film.clear; end
        end
        
        function [val] = get(obj,param,varargin)
            % psfCamera.get('parameter name')
            % Start to set up the gets for this object
            val = [];
            param = ieParamFormat(param);
            switch param
                case {'wave','wavelength'}
                    val1 = obj.lens.wave(:);
                    val2 = obj.film.wave(:);
                    if isequal(val1,val2), val = val1; return;
                    else, warning('Lens and film wavelength differ.  Using lens.');
                    end
                    val = val1;
                    
                case 'spacing'
                    % Millimeters per sample
                    r = obj.film.resolution(1);
                    s = obj.film.size(1);
                    val = s/r;
                case 'imagecentroid'
                    % obj.get('image centroid')
                    % x,y positions (0,0) is center of the image centroid.
                    % Used for calculating centroid of the psf
                    
                    % Figure out center pos by calculating the centroid of illuminance image
                    flm = obj.film;
                    img = flm.image;  img = sum(img,3);
                    
                    % Force to unit area and flip up/down for a point spread
                    img = img./sum(img(:));
                    img = flipud(img);
                    % ieFigure; mesh(img);
                    
                    % Calculate the weighted centroid/center-of-mass
                    xSample = linspace(-flm.size(1)/2, flm.size(1)/2, flm.resolution(1));
                    ySample = linspace(-flm.size(2)/2, flm.size(2)/2, flm.resolution(2));
                    [filmDistanceX, filmDistanceY] = meshgrid(xSample,ySample);
                    
                    % distanceMatrix = sqrt(filmDistanceX.^2 + filmDistanceY.^2);
                    val.X = sum(sum(img .* filmDistanceX));
                    val.Y = sum(sum(img .* filmDistanceY));
                    
                    % THIS IS VERY CONFUSING.
                    % BW SHOULD COMMENT AND REORGANIZE
                    % BBM, Optical System and Imaging System are all here.
                    % What is that about?
                case {'blackboxmodel','blackbox','bbm'} 
                    % Equivalent BLACK BOX MODEL
                    % 
                    % Which field of the black box to get
                    if nargin>2
                        parameter = varargin{1};  
                    else
                        error('Specify also the field of the Black Box Model!')
                    end
                    
                    if nargin>3
                        val = obj.bbmGetValue(parameter,varargin{2});
                    else
                        val = obj.bbmGetValue(parameter);
                    end
                    
                    % val = obj.bbmGetValue(obj.BBoxModel,parameter);
                    
                case {'opticalsystem'; 'optsyst';'opticalsyst';'optical system structure'}
                    % It seems OK to get the BBM from the lens.  The
                    % psfCameraC could have its own BBM, but I am not sure
                    %
                    % So, this should probably be
                    %
                    %    psfCameraC.get('lens optical system')
                    %
                    % rather than psfCameraC.get('optical system')
                    % 
                    % Get the equivalent optical system structure generated
                    % by Michael's script
                    % You can specify refractive indices for object and
                    % image space using varargin {1} and {2}
                    if nargin >2
                        n_ob = varargin{1};    n_im = varargin{2};
                        OptSyst = obj.lens.bbmComputeOptSyst(n_ob,n_im);
                    else
                        OptSyst = obj.lens.bbmComputeOptSyst();
                    end
                    val = OptSyst;
                    
                case {'imagingsystem'; 'imgsyst';'imagingsyst';'imaging system structure'}
                    % Get the equivalent imaging system structure generated
                    % by Michael's script
                    % You can specify refractive indices for object and
                    % image space using varargin {1} and {2}
                    % Get inputs
                    
                    pSource=obj.pointSource;
                    %COMPUTE OPTICAL SYSTEM
                    if nargin >2
                        n_ob = varargin{1};    n_im = varargin{2};
                        OptSyst = obj.lens.get('optical system',n_ob,n_im);
                    else
                        OptSyst = obj.lens.get('optical system');
                    end
                    unit=paraxGet(OptSyst,'unit');
                    
                    % GET USEFUL PARAMETERs
                    lV   = paraxGet(OptSyst,'lastvertex'); % last vertex of the optical system
                    F.z  = obj.film.position(3)+lV;
                    F.res= obj.film.resolution(1:2);
                    F.pp = obj.film.size; %um x um
                    
                    %CREATE an Imaging System
                    [ImagSyst]=paraxOpt2Imag(OptSyst,F,pSource,unit);
                    
                    % SET OUTPUT
                    val = ImagSyst;
                    
                case {'film'}
                    % get the film structure
                    val = obj.film;
                case {'filmposition'}
                    % Distance to the film
                    val = obj.film.position;
                case {'filmdistance'}
                    val = obj.film.position(3);
                case {'pointsource';'psource';'lightsource'}
                    % get the point source in the psfCamera
                    val = obj.pointSource;
                case {'lens'}
                    % get the lens the psfCamera
                    val = obj.lens;
                case {'fftpsf';'psffft'}
                    % get the fftPSF
                    val = obj.fftPSF;
                case {'fftpsfmodulus';'psffftvalue'}
                    % get the fftPSF modolus,
                    % Specifying the wavelength if you want a specific PSF
                    if nargin > 2
                        wave0 = varargin{1};
                        wave  = obj.get('wave');
                        indW0=find(wave==wave0);
                        if isempty(indW0)
                            val = obj.fftPSF.abs;
                            warning (['The specified wavelength does match with the available ones: ',num2str(wave) ,' nm'])
                        else
                            val = obj.fftPSF.abs(:,:,indW0);
                        end
                        return;
                    end
                    % All wavelengths?
                    val=obj.fftPSF.abs;
                case {'fftpsfcoordinate';'psffftcoord'}
                    % get the fftPSF coord,
                    % Specifying the wavelength if you want a specific PSF
                    if nargin>2
                        wave0 = varargin{1};
                        wave  = obj.get('wave');
                        indW0 = find(wave==wave0);
                        if isempty(indW0)
                            val.x=obj.fftPSF.x;
                            val.y=obj.fftPSF.y;
                            warning (['The specified wavelength does match with the available ones: ',num2str(wave) ,' nm'])
                        else
                            val.x=obj.fftPSF.x(:,:,indW0);
                            val.y=obj.fftPSF.y(:,:,indW0);
                        end
                    end
                    val.x=obj.fftPSF.x;
                    val.y=obj.fftPSF.y;
                otherwise
                    error('unknown parameter %s\n',param)
            end
            
        end
        
        %%
        function val = set(obj,param,val,varargin)
            % psfCamera.set('parameter name',value)
            % Start to set up the gets for this object
            
            % We should adjust this so that if the first word is lens or
            % film we call the lens.set or film.set routine.
            param = ieParamFormat(param);
            switch param
                case {'pointsource';'psource';'lightsource'}
                    % set the point source in the psfCamera
                    obj.pointSource= val;
                    
                case {'lens'}
                    % set the filmin the psfCamera
                    obj.lens= val;
                    
                case {'film'}
                    % set the film in the psfCamera
                    obj.film = val;
                case {'filmposition'}
                    obj.film.position = val;
                    
                case {'blackboxmodel';'blackbox';'bbm'}
                    % Get the parameters from the imaging system structure
                    % to build an  equivalent Black Box Model of the lens.
                    % The ImagSyst structure has to be built with the
                    % function 'paraxCreateImagSyst' Get 'new' origin for
                    % optical axis INPUT val= ImagSyst struct varargin {1}:
                    % polar coordinate of pointSource [ro, theta, z]
                    %
                    % MP Vistasoft 2014
                    
                    ImagSyst = val;
                    psPolar  = varargin{1};
                    z0       = paraxGet(ImagSyst,'lastvertex');
                    
                    % Variable to append
                    efl = paraxGet(ImagSyst,'effectivefocallength');  % focal lenght of the system
                    obj.bbmSetField('effectivefocallength',efl);
                    
                    pRad = paraxGet(ImagSyst,'effectivefocallength'); % radius of curvature of focal plane
                    obj.bbmSetField('focalradius',pRad);
                    
                    Fi=paraxGet(ImagSyst,'imagefocalpoint') - z0;     % Focal point in the image space
                    obj.bbmSetField('imagefocalpoint',Fi);
                    
                    Hi=paraxGet(ImagSyst,'imageprincipalpoint') - z0; % Principal point in the image space
                    obj.bbmSetField('imageprincipalpoint',Hi);
                    
                    Ni=paraxGet(ImagSyst,'imagenodalpoint')-z0;       % Nodal point in the image space
                    obj.bbmSetField('imagenodalpoint',Ni);
                    
                    Fo=paraxGet(ImagSyst,'objectfocalpoint')-z0;      % Focal point in the object space
                    obj.bbmSetField('objectfocalpoint',Fo);
                    
                    Ho=paraxGet(ImagSyst,'objectprincipalpoint')-z0;  % Principal point in the object space
                    obj.bbmSetField('objectprincipalpoint',Ho);
                    
                    No=paraxGet(ImagSyst,'objectnodalpoint')-z0;      % Nodal point in the object space
                    obj.bbmSetField('objectnodalpoint',No);
                    
                    % abcd Matrix (Paraxial)
                    % The 4 coefficients of the ABCD matrix of the overall
                    % system
                    M = ImagSyst.matrix.abcd;
                    obj.bbmSetField('abcd',M);
                    
                    % IMAGE FORMATION
                    % Effective F number
                    Fnum=ImagSyst.object{end}.Radiance.Fnumber.eff; %effective F number
                    obj.bbmSetField('fnumber',Fnum);
                    
                    % Numerical Aperture
                    NA=ImagSyst.n_im.*sin(atan(ImagSyst.object{end}.Radiance.ExP.diam(:,1)./(ImagSyst.object{end}.ConjGauss.z_im-mean(ImagSyst.object{end}.Radiance.ExP.z_pos,2))));
                    obj.bbmSetField('numericalaperture',NA);
                    
                    %Field of View
                    FoV=ImagSyst.object{end}.Radiance.FoV;
                    obj.bbmSetField('fieldofview',FoV);
                    
                    % Lateral magnification
                    magn_lateral=ImagSyst.object{end}.ConjGauss.m_lat; %
                    obj.bbmSetField('lateralmagnification',magn_lateral);
                    
                    % Exit Pupil
                    ExitPupil.zpos=mean(ImagSyst.object{end}.Radiance.ExP.z_pos,2)-z0;
                    ExitPupil.diam=ImagSyst.object{end}.Radiance.ExP.diam(:,1)-ImagSyst.object{end}.Radiance.ExP.diam(:,2);
                    obj.bbmSetField('exitpupil',ExitPupil);
                    
                    % Entrance Pupil
                    EntrancePupil.zpos=mean(ImagSyst.object{end}.Radiance.EnP.z_pos,2)-z0;
                    EntrancePupil.diam=ImagSyst.object{end}.Radiance.EnP.diam(:,1)-ImagSyst.object{end}.Radiance.EnP.diam(:,2);
                    obj.bbmSetField('entrancepupil',EntrancePupil);
                    
                    % Gaussian Image Point
                    iP_zpos=ImagSyst.object{end}.ConjGauss.z_im-z0; %image point z position
                    iP_h=psPolar(1).*magn_lateral;% image point distance from the optical axis
                    [iP(:,1),iP(:,2),iP(:,3)]=coordPolar2Cart3D(iP_h,psPolar(2),iP_zpos);
                    obj.bbmSetField('gaussianimagepoint',iP);
                    
                    % Aberration
                    % Primary Aberration
                    paCoeff=ImagSyst.object{end}.Wavefront.PeakCoeff;
                    obj.bbmSetField('primaryaberration',paCoeff);
                    
                    % Defocus
                    [obj_x,obj_y,obj_z]=coordPolar2Cart3D(psPolar(1),psPolar(2),psPolar(3));
                    Obj.z=obj_z+paraxGet(ImagSyst,'lastVertex');
                    Obj.y=sqrt(obj_x.^2 + obj_y.^2); % eccentricity (height)
                    [defCoeff] = paEstimateDefocus(ImagSyst,Obj,'best');
                    obj.bbmSetField('defocus',defCoeff);
                    
                    % REFRACTIVE INDEX
                    % object space
                    n_ob=ImagSyst.n_ob;
                    obj.bbmSetField('n_ob',n_ob);
                    % image space
                    n_im=ImagSyst.n_im;
                    obj.bbmSetField('n_im',n_im);
                    
                case {'fftpsf';'psffft'}
                    % get the fftPSF
                    obj.fftPSF=val;
                case {'fftpsfmodulus';'psffftvalue'}
                    % get the fftPSF modolus,
                    % Specifying the wavelength if you want a specific PSF
                    if nargin>3
                        wave0=varargin{1};
                        wave=obj.get('wave');
                        indW0=find(wave==wave0);
                        if isempty(indW0)
                            obj.fftPSF.abs=val;
                            warning (['The specified wavelength does match with the available ones: ',num2str(wave) ,' nm'])
                        else
                            obj.fftPSF.abs(:,:,indW0)=val;
                        end
                    end
                    obj.fftPSF.abs=val;
                case {'fftpsfcoordinate';'psffftcoord'}
                    % get the fftPSF coord,
                    % Specifying the wavelength if you want a specific PSF
                    if nargin>3
                        wave0=varargin{1};
                        wave=obj.get('wave');
                        indW0=find(wave==wave0);
                        if isempty(indW0)
                            obj.fftPSF.x=val.x;
                            obj.fftPSF.y=val.y;
                            warning (['The specified wavelength does match with the available ones: ',num2str(wave) ,' nm'])
                        else
                            obj.fftPSF.x(:,:,indW0)=val.x;
                            obj.fftPSF.y(:,:,indW0)=val.y;
                        end
                    end
                    obj.fftPSF.x=val.x;
                    obj.fftPSF.y=val.y;
                    
                otherwise
                    error('unknown parameter %s\n',param)
            end
            
        end
        
    end
    
end
