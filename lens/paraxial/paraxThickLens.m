%% Function: Evaluate Optical Parameters of a Thick Lens


function [optPower,varargout]=paraxThickLens(R1,R2,th,n,n_ob,n_im,wavelength)

%INPUT
%R1: Radius of curvature of first surface
%R2: Radius of curvatire of second surface
%th: thickness
%n: refractive index of the lens medium (scalar or column vector)
%n_ob: refractive index of the object space (scalar or column vector)
%n_im: refractive index of the image space (scalar or column vector)

%NOTE: unit of reference is given by radius

%OUTPUT
%optPower: Optical power [1/unit]
%varargout{1}: focal length in image space [unit] 
%varargout{2}: focal length in object space [unit] 
%varargout{3}: back focal length in image space [unit] 
%varargout{4}: forward focal length in object space [unit] 

%% CHECK of PREREQUISITEs

%Wavelength is a column vector
if length(wavelength)>1 && size(wavelength,2)>1
    wavelength=wavelength';            
end

% Refractive index of the lens medium
if size(n,1)==size(wavelength,1)
            n=n;
else
    if (size(wavelength,1)>1) && (size(n,1)==1) && (size(n,2)==1) %case of no dispersive material
        n=repmat(n,size(wavelength,1),1);
    else
        warning('Refractive index and sampling wavelength do not match!!')
        optPower=[];
        varargout{1}=[];varargout{2}=[];
        return
    end
end
% Refractive index of the object space
if size(n_ob,1)==size(wavelength,1)
            n_ob=n_ob;
else
    if (size(wavelength,1)>1) && (size(n_ob,1)==1) && (size(n_ob,2)==1) %case of no dispersive material
        n_ob=repmat(n_ob,size(wavelength,1),1);
    else
        warning('Refractive index of the object space and sampling wavelength do not match!!')
        optPower=[];
        varargout{1}=[];varargout{2}=[];
        return
    end
end
% Refractive index of the image space
if size(n_im,1)==size(wavelength,1)
            n_im=n_im;
else
    if (size(wavelength,1)>1) && (size(n_im,1)==1) && (size(n_im,2)==1) %case of no dispersive material
        n_im=repmat(n_im,size(wavelength,1),1);
    else
        warning('Refractive index of the image space and sampling wavelength do not match!!')
        optPower=[];
        varargout{1}=[];varargout{2}=[];
        return
    end
end


%% COMPUTE optical parameter of THICK LENS
T1=(n-n_ob)./R1;
T2=(n-n_im)./R2;
T3=th./n.*T1.*T2;

optPower=T1-T2+T3; %[1/unit]
%in image space
varargout{1}=n_im./optPower; %focal length
varargout{3}=varargout{1}.*(1-th./n.*(T1)); %back focal length
%focal length in object space
varargout{2}=-n_ob./optPower;
varargout{4}=varargout{2}.*(1+th./n.*(T2)); %forward focal length
