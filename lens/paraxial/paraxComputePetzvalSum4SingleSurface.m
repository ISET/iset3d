% Petzval contribute for a single surface or elements

%More details are given in "Lens Foudnamental Design, at pag 299"

function [sumPetzval]=paraxComputePetzvalSum4SingleSurface(surf,Npre,varargin)



%INPUT
%surf: surface structure with type and relevant field, such as structure with different fields {.type; .N ;}
%N_pre: refractive index of the medium pre-surface (column vector for
%dispersion)
%varargin:  {1} Npost: refractive index post elements (needed for
%multi-surface element, e.g. thin lens, thick lens,grin...)
%OUTPUT
% sumPetzval: contribute of the single surface to Petzval Sum



% Check Disperion
if not(size(Npre,1)==size(surf.N,1))
    error('Refractive indices dimension DO NOT MATCH for dispersion effect!!')
end

% Check number of input
if nargin>3
    Npost=varargin{1};
end



%% Compute contribution

switch  surf.type
    case {'refractive'}
         sumPetzval=(surf.N-Npre)./(surf.R.*surf.N.*Npre); %(n1-n0)/(r1*n1*n0)
    case {'mirror'}
         sumPetzval=(2)./(surf.R.*Npre); %since n1=-n0; (-2no)/(-2no^2*r1)
    case {'thin'}
        sumPetzval=surf.optPower./(Npre.*Npost); % optPower/(n0 n2); 
    case {'thick'}
        sumPetzval1=(surf.N(:,2)-Npre)./(surf.R(1).*surf.N(:,2).*Npre); % contribution first surface
        sumPetzval2=(Npost-surf.N(:,2))./(surf.R(2).*surf.N(:,2).*Npost); % optPower/(n0 n2); since n1
        sumPetzval=sumPetzval1+sumPetzval2; %sum contribution of the two surface
    case {'GRIN','GRINlens'} 
        sumPetzval=0; % NO SOURCE AVAILABLE 
        warning ('GRIN lens is present! PETZVAL SUM NOT RELIABLE!!!')
    case {'diaphragm','flat'}
        sumPetzval=zeros(size(Npre,1),1);  
    otherwise
        error('Not valid element type!!')
end