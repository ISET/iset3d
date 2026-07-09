% Analysys of the Optical system components to evaluate
% the Petzval sum and its related parameters
%More details are given in "Lens Foudnamental Design, at pag 299"

function [Petzval]=paraxComputePetzvalSum(surfs,n_ob,n_im,f_im,wave)



%INPUT
%surfs: structure with different fields for multi-surface {.list: list of the surface;  .order: surface order along the optical axis}
%n_ob: refractive index of the object space(column vector for dispersion)
%n_im: refractive index of the image space (column vector for dispersion)
%f_im: focal length of the system in the image space (column vector for dispersion)
%wave: sampling wavelength for the refractive index
%OUTPUT
% Petzval: strunture with different film

%NOTE: the unit for distance and wavelength is the same of the Optical
%System

for si=1:length(surfs.order)
    %Boarded case for Refracrive Index before elements
    if si==1 %
        Npre=n_ob;
    else
        Npre=surfs.list{surfs.order(si-1)}.N;
    end
    %Boarded case for Refracrive Index before elements
    if si+1<length(surfs.order)
        Npost=surfs.list{surfs.order(si+1)}.N;
    else
        Npost=n_im;        
    end
    %Compute single surface contribution
    [sumP(:,si)]=paraxComputePetzvalSum4SingleSurface(surfs.list{surfs.order(si)},Npre);
    type_surf{si}=(surfs.list{surfs.order(si)}.type);
end


% OUTPUT
Petzval.surf.type=type_surf; %Contribution for single elements type
Petzval.surf.contr=sumP;
Petzval.sum=sum(sumP,2);            % Petzval summ for entire optical system
Petzval.radius=-1./(n_im.*Petzval.sum); %radius of Petzaval Curvature
Petzval.focalRation=Petzval.radius./f_im; %radius of Petzaval Curvature