

function [n,varargout]=paraxFindN4SubSyst(OptSyst,index,l,space_type)
%  Check refractive index for image/object space in the case of sub-system
%
%       function [n,varargout]=paraxFindN4SubSyst(OptSyst,index,l,space_type)
%
%INPUT:
%OptSyst: structure of the optical system
%index: element of the optical system at the edge of the subsystem
%l: distanza to search desidered refractive index
%space_type: looking for image space or object space
%
%OUTPUT:
% n: refractive index of the searched space (i.e. object or image)
%varargout {1}= l_out
%
% MP Vistasoft 2014

switch space_type
    
    case {'object','ob','obj','n_ob','n_obj'}
        if (index-l)>0
            subsurf=OptSyst.surfs.list{OptSyst.surfs.order(index-l)};
            switch subsurf.type
                case {'refractive','flat',''}
                    n_ob=subsurf.N;
                case {'mirror','diaphragm',''}
                    [n_ob]=paraxFindN4SubSyst(OptSyst,index-1,l,space_type);
                    
                case {'thin','GRIN',''}
                    n_ob=subsurf.N(:,2);
                case {'thick','',''}
                    n_ob=subsurf.N(:,3);
            end
        else
            n_ob=OptSyst.n_ob;
        end
        n=n_ob;
        
    case {'image','im','ima','n_im'}
        if (index)<length(OptSyst.surfs.list)
            subsurf=OptSyst.surfs.list{OptSyst.surfs.order(index)};
            switch subsurf.type
                case {'refractive','flat',''}
                    n_im=subsurf.N;
                case {'mirror','diaphragm',''}
                    [n_im]=paraxFindN4SubSyst(OptSyst,index+1,l,space_type);                    
                case {'thin','GRIN',''}
                    n_im=subsurf.N(:,2);
                case {'thick','',''}
                    n_im=subsurf.N(:,3);
            end
        else
            n_im=OptSyst.n_im;
        end
        n=n_im;
        
end

% if nargout>1
%     varargout{1}=l_out;
% end