function set(obj,pName,val,varargin)
%% lensC:  Set gateway
%  
% Synopsis
%  lensC.set(pName,val,varargin);
%
% Inputs
%  pName - property name
%  val   - property value
%
% See also
%   lensC.get

%% Squeeze out spaces and force to lower case
pName = ieParamFormat(pName);

%% Onward
switch pName
    case 'name'
        % lens.set('name','thisName');
        obj.name = val;
    case 'wave'
        % lens.set('wave',val);
        % The wavelength var is annoying. This could go away
        % some day.  But for now, the wavelength set is
        % ridiculous because there are so many copies of wave.
        % We should set it here rather than addressing every
        % surface element.
        obj.wave = val;
        nSurfaces = obj.get('n surfaces');
        for ii=1:nSurfaces
            obj.surfaceArray(ii).set('wave', val);
        end
    case 'surfacearray'
        % lens.set('surface array',surfaceArrayClass);
        obj.surfaceArray = val;
    case 'microlenssize'
        % Used for microlens.  Set the size, as measured by the front
        % aperture, to a particular size in mm.
        obj.adjustSize(val);
    case {'middleaperturediameter','aperturediameter'}
        % Set the middle aperture to diameter val (mm)
        idx = obj.get('aperture index');
        obj.surfaceArray(idx).apertureD = val;
    case 'aperturesample'
        obj.apertureSample = val;
    case 'surfacearrayindex'
        index=varargin{1};
        % lens.set('surface array',val);
        obj.surfaceArray(index) = val;
    case 'apertureindex'
        % lens.set('aperture index',val);
        % Indicates which of the surfaces is the aperture.
        index=val;
        obj.apertureIndex(index); % Set the surface (specify by varargin) as aperture
    case 'nall'
        % Set the index of refraction to all the surfaces
        nSurfaces = obj.get('n surfaces');
        for ii=1:nSurfaces
            obj.surfaceArray(ii).n = val;
        end
    case 'nrefractivesurfaces'
        % lens.set('n refractive surfaces',nMatrix)
        %
        % The nMatrix should be nWave x nSurfaces where
        % nSurfaces are only the refractive surfaces.  This
        % sets the index of refraction to all those surfaces
        
        % Indices of the refractive surfaces
        lst = find(obj.get('refractive surfaces'));
        
        % For every column in val, put it in the next
        % refractive index of the lst.
        kk = 0;   % Initiate the counter
        for ii = 1:length(lst)
            kk = kk + 1;
            obj.surfaceArray(lst(ii)).n(:) = val(:,kk);
        end
        
    case {'effectivefocallength';'efl';'focalradius';'imagefocalpoint';...
            'objectfocalpoint';'imageprincipalpoint';'objectprincipalpoint';...
            'imagenodalpoint';'objectnodalpoint';'abcd';'abcdmatrix'}
        % Build the field to append
        obj.bbmSetField(pName,val);
    case {'figurehandle','fhdl'}
        obj.fHdl = val;
        
    case {'blackboxmodel';'blackbox';'bbm'}
        % Get the parameters from the optical system structure
        % to build an  equivalent Black Box Model of the lens.
        % The OptSyst structure has to be built with the
        % function 'paraxCreateOptSyst' Get 'new' origin for
        % optical axis
        OptSyst=val;
        %                     z0 = OptSyst.cardPoints.lastVertex;
        z0=paraxGet(OptSyst,'lastVertex');
        % Variable to append
        %                     efl=OptSyst.cardPoints.fi; %focal lenght of the system
        efl=paraxGet(OptSyst,'efl');
        obj.bbmSetField('effectivefocallength',efl);
        %                     pRad = OptSyst.Petzval.radius; % radius of curvature of focal plane
        pRad = paraxGet(OptSyst,'focalradius'); % radius of curvature of focal plane
        obj.bbmSetField('focalradius',pRad);
        %                     Fi=OptSyst.cardPoints.dFi;     %Focal point in the image space
        Fi= paraxGet(OptSyst,'imagefocalpoint')-z0;     %Focal point in the image space
        obj.bbmSetField('imagefocalpoint',Fi);
        %                     Hi=OptSyst.cardPoints.dHi; % Principal point in the image space
        Hi= paraxGet(OptSyst,'imageprincipalpoint')-z0; % Principal point in the image space
        obj.bbmSetField('imageprincipalpoint',Hi);
        %                     Ni=OptSyst.cardPoints.dNi;     % Nodal point in the image space
        Ni=paraxGet(OptSyst,'imagenodalpoint')-z0;    % Nodal point in the image space
        obj.bbmSetField('imagenodalpoint',Ni);
        %                     Fo=OptSyst.cardPoints.dFo-z0; %Focal point in the object space
        Fo=paraxGet(OptSyst,'objectfocalpoint')-z0; %Focal point in the object space
        obj.bbmSetField('objectfocalpoint',Fo);
        %                     Ho=OptSyst.cardPoints.dHo-z0; % Principal point in the object space
        Ho=paraxGet(OptSyst,'objectprincipalpoint')-z0; % Principal point in the object space
        obj.bbmSetField('objectprincipalpoint',Ho);
        %                     No=OptSyst.cardPoints.dNo-z0; % Nodal point in the object space
        No=paraxGet(OptSyst,'objectnodalpoint')-z0; % Nodal point in the object space
        obj.bbmSetField('objectnodalpoint',No);
        M = paraxGet(OptSyst,'abcd'); % The 4 coefficients of the ABCD matrix of the overall system
        obj.bbmSetField('abcd',M);
        
    otherwise
        error('Unknown parameter %s\n',pName);
end

end