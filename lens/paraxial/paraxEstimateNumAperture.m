% Estimate The numerical Aperture of the Imaging System for a specified
% Point Source



function [NA]=paraxEstimateNumAperture(ImagSyst,Obj,varargin)

%INPUT
%ImagSyst: image system struct
%Obj:      point source object structure  {.z: position along optical axis; .y:height eccentricity}
%vararging  to specify other apporach to compute the numerical aperture


%OUTPUT
%NA: numerical aperture (wavelength dependent)


if nargin>2
    method=varargin{1};
else
    method='default';
end
% Get relevant parameters
wave=ImagSyst.wave; nW=size(wave,1);
unit=ImagSyst.unit;
n_im=ImagSyst.n_im;

switch method
    case {'default'}
        profile1='point';
        [source1]=paraxCreateObject(Obj.z,Obj.y,profile1,unit);
        [ImagSyst]=paraxAddObject2ImagSyst(ImagSyst,source1);
        %Get useful parameter
        ExPDiam(:,1)=ImagSyst.object{end}.Radiance.ExP.diam(:,1)-ImagSyst.object{end}.Radiance.ExP.diam(:,2);
        eff_distance(:,1)=ImagSyst.object{end}.ConjGauss.z_im(:,1)-mean(ImagSyst.object{end}.Radiance.ExP.z_pos(:,:),2);
        %Compute Numerical Aperture
        for li=1:nW
            [NA(li,:)]=paraxNumAperture(ExPDiam(li,1),eff_distance(li,1),n_im(li,1));
        end
        
    otherwise
        error (['Not valid ',method', 'as method to compute the Numerical Aperture'])
end


