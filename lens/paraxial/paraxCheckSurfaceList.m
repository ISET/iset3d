

function [surfslist]=paraxCheckSurfaceList(surfsIN,n_ob,n_im)

% Several elements of an Optical System are related to its neighbourhood.
% For instance the diaphragm hasn't the field about the refractive index (N) needs for computation of ABCD
% The thick and thin lenses shown an optical power related to the medium
% before and after the lens.
%This function check the current elements congruence, fixing if not
%present, as well as filling the missing field
%
%       function [surfslist]=paraxCheckSurfaceList(surfsIN,n_ob,n_im)
%
%INPUT
%surfs: structure with different fields for multi-surface {.list: list of the surface;  .order: surface order along the optical axis}
%n_ob: refractive index of the object space(column vector for dispersion)
%n_im: refractive index of the image space (column vector for dispersion)
%
%OUTPUT
% surfs: struncture with fixed and filled surfaces
%
% MP Vistasoft 2014

for si=1:length(surfsIN.order)
  
    
    switch surfsIN.list{surfsIN.order(si)}.type
       case {'refractive','flat'}
           surfslist{surfsIN.order(si)}=surfsIN.list{surfsIN.order(si)};
        case {'mirror'}            
           surfslist{surfsIN.order(si)}=surfsIN.list{surfsIN.order(si)};
        case {'thin'}
            surfslist{surfsIN.order(si)}=surfsIN.list{surfsIN.order(si)};
        case {'thick'}
            surfslist{surfsIN.order(si)}=surfsIN.list{surfsIN.order(si)};
        case {'GRIN','GRINlens'} 
            surfslist{surfsIN.order(si)}=surfsIN.list{surfsIN.order(si)};
        case {'diaphragm'}
            if si==1 % Just assume air if the first one is a diaphragm
                Npre=n_ob;   %
                Vd_pre = 0;  % Abbe number is 0
                % [A,Vd_pre]=RefractiveIndexDispersion(586.7*1e-6,'mm','air0');
            else
                Npre=surfslist{surfsIN.order(si-1)}.N;
                Vd_pre=surfslist{surfsIN.order(si-1)}.abbeNumber;
            end
            surfslist{surfsIN.order(si)}=surfsIN.list{surfsIN.order(si)};
            surfslist{surfsIN.order(si)}.N=Npre; % add missing field
            surfslist{surfsIN.order(si)}.abbeNumber=Vd_pre; % add missing field
    end
    
end