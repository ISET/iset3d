

function [M,varargout]=paraxComputeSurfaceMatrix(surf,n_ob,matrix_type,varagin)
%  Compute the paraxial matrix for the given surface
%
%  function [M,varargout]=paraxComputeSurfaceMatrix(surf,n_ob,matrix_type,varagin)
%
%INPUT
%surf: surface structure
%n_ob: the refractive index before the surface (relative object space)
%matrix_type: string describing which type of matrix has to be computer : %for 'reduced' or 'non-reduced'  parameters
%varargin : 

%NB: n_ob and n_im ar column vector sampled at N different wavelength (check it before use the function)

%OUTPUT
%M: (2x2xN): surface paraxial matrix for the N wavelength
%varargout {1} cardinal points
%.ni,.fi,.dFi,.dHi,.dNi,.no.fo,.dFo,.dHo,.dNo,  d_distance from the vertex and refractive index ni, no
%
% MP Vistasoft 2014
%% COMPUTE M Matrix for the given surface structure with reduced parameters


switch surf.type
    case {'refractive','refr'}        
        c_red=-(surf.N-n_ob)./surf.R; %c coeff
        Mred=ones(2,2,size(c_red,1));
        Mred(1,2,:)=zeros(1,1,size(c_red,1));
        Mred(2,1,:)=c_red; 
        n_im=surf.N; % (relative image space)
        
    case {'mirror','reflection', 'refl'}
       c_red=-2*(n_ob)./surf.R; %c coeff
       Mred=ones(2,2,size(c_red,1));
       Mred(1,2,:)=zeros(1,1,size(c_red,1));
       Mred(2,1,:)=c_red;       
       n_im=n_ob; % (relative image space)
       
    case {'plane','flat'}
       Mred=ones(2,2,size(n_ob,1));
       Mred(1,2,:)=zeros(1,1,size(n_ob,1));
       Mred(2,1,:)=zeros(1,1,size(n_ob,1));
       n_im=surf.N; % (relative image space)
      
    case {'thin','thinlens'}
       Mred=ones(2,2,size(n_ob,1));
       Mred(1,2,:)=zeros(1,1,size(n_ob,1));     
       Mred(2,1,:)=-surf.optPower; 
       if not(surf.N(:,1)==n_ob)
            warning('Refr. index of the object space and which thin lens is computed do not matched!! The data are not reliable !!')
        end  
       n_im=surf.N(:,2); % (relative image space)
       
    case {'thick','thicklens'}
        tHn_ob=(surf.ffl_ob-surf.f_ob)./surf.N(:,1);
        tHn_im=(surf.f_im-surf.bfl_im)./surf.N(:,3);
        a_red=1+surf.optPower .*(surf.f_im-surf.bfl_im)./surf.N(:,3);
        b_red=tHn_ob+tHn_im-surf.optPower.*tHn_ob.*tHn_im;  %tHob/nob+tHim/nim - K*tHob/nob*tHim/nim;  CHECKED
%         b_red0=surf.th./surf.N(:,2);
        c_red=-surf.optPower;
        d_red=1+surf.optPower .*(surf.ffl_ob-surf.f_ob)./surf.N(:,1);
        Mred=ones(2,2,size(n_ob,1));
        Mred(1,1,:)=a_red;Mred(1,2,:)=b_red;Mred(2,1,:)=c_red;Mred(2,2,:)=d_red;     
        if not(surf.N(:,1)==n_ob)
            warning('Refr. index of the object space and which thin lens is computed do not matched!! The data are not reliable !!')
        end  
       n_im=surf.N(:,3); % (relative image space)
    
    case {'GRIN','GRINlens'} 
        switch surf.profile.type
            case {'parabolic'}
                a_red=cos(surf.profile.alfa.*surf.th).*n_ob./n_ob;
                b_red=sin(surf.profile.alfa.*surf.th)./(surf.th).*n_ob./n_ob;
                c_red=-sin(surf.profile.alfa.*surf.th).*(surf.th).*n_ob./n_ob;
                d_red=a_red;
                Mred(1,1,:)=a_red;Mred(1,2,:)=b_red;Mred(2,1,:)=c_red;Mred(2,2,:)=d_red;
                
            otherwise                
               Mred=ones(2,2,size(n_ob,1));
               Mred(1,2,:)=zeros(1,1,size(n_ob,1));
               Mred(2,1,:)=zeros(1,1,size(n_ob,1));             
               warning('Not fount a valid profile fro GRIN lens!! Negleted contribution !!')
        end
       n_im=surf.N(:,2); % (relative image space)
            
    case {'diaphragm','diaph','aperture','apert','stop'} %not effect!!        
       Mred=ones(2,2,size(n_ob,1));
       Mred(1,2,:)=zeros(1,1,size(n_ob,1));
       Mred(2,1,:)=zeros(1,1,size(n_ob,1));      
       n_im=n_ob; % (relative image space)
end


switch matrix_type
    case {'reduced','red'}
        M=Mred;
    case {'not-reduced','notred',''}
        M=paraxMatrixRed2NotRed_red(Mred,n_ob,n_im);
    otherwise
        warning('Not fount a valid M matrix type!! Returned EMPTY !!')
end



%% Compute Cardinal point

if nargout>1
    % matrix_type0='reduced';
    matrix_type0='notred';
    % varargout{1}=paraxMatrix2CardinalPoints(Mred,n_ob,n_im,matrix_type0);
    varargout{1}=paraxMatrix2CardinalPoints(paraxMatrixRed2NotRed_red(Mred,n_ob,n_im),n_ob,n_im,matrix_type0);
end

