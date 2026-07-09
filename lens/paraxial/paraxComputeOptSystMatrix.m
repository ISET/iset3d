function [abcd,allM,varargout]=paraxComputeOptSystMatrix(OptSyst,matrix_type,varargin)
% Compute the paraxial matrices for each surface and for the overall optical system
%
%
%
%INPUT
%  OptSyst: Optical System structure
%  matrix_type: string describing which type of matrix has to be computer : %for 'reduced' or 'non-reduced'  parameters
%  varargin: possible inputs
%
%NB: n_ob and n_im ar column vector sampled at N different wavelength (check it before use the function)
%
%OUTPUT
%abcd: (2x2xN): overall system paraxial matrix for the N wavelength
%varargout{1}: list of M (# of surface) refractive matrices (2x2xN) and M-1 translation matrices (2x2xN)
%
% MP Vistasoft 2014

%% CHECK if the first and last surfaces are thin or thick lenses and if their optical parameters have been properly computed 
list=OptSyst.surfs.list;
in_order=OptSyst.surfs.order;
n_ob=OptSyst.n_ob;
n_im=OptSyst.n_im;

%First surface
switch list{in_order(1)}.type
    case ('thin')
        if not(all(list{in_order(1)}.N(:,1)==n_ob))
            warning('Refr. index of the object space and which thin lens is computed do not matched!! The data are not reliable !!')
        end  
    case ('GRIN')
        if not(all(list{in_order(1)}.N(:,1)==n_ob))
            warning('Refr. index of the object space and which GRIN lens is computed do not matched!! The data are not reliable !!')
        end
    case ('thick')
        if not(all(list{in_order(1)}.N(:,1)==n_ob))
            warning('Refr. index of the object space and which thick lens is computed do not matched!! The data are not reliable !!')
        end
        
end

%Last surface
switch list{in_order(end)}.type
    case ('thin')
        if not(all(list{in_order(end)}.N(:,2)==n_im))
            warning('Refr. index of the image space and which thin lens is computed do not matched!! The data are not reliable !!')
        end
    case ('GRIN')
        if not(all(list{in_order(end)}.N(:,2)==n_im))
            warning('Refr. index of the image space and which GRIN lens is computed do not matched!! The data are not reliable !!')
        end
    case ('thick')
        if not(all(list{in_order(end)}.N(:,3)==n_im))
            warning('Refr. index of the image space and which thick lens is computed do not matched!! The data are not reliable !!')
        end
        
end


%% MERIDIONAL PLANE : compute matrices with reduced parameters
%create several useful objects
matrix_list={};
vertex_z=[]; %list of surface vertex
thickness=[]; %list of translation 
N=[n_ob]; %refractive index before surface
aper_diam=[]; %list of aperture of the surface
surf_M={}; %list of the surface parax matrix
transl_M={}; %list of the translation parax matrix
type_Ms={}; %list of the type of parax matrix to be computed in order
in_transl=0; %inizialitazion of the index about translation

%Augmented parametes
augParm=[];


%Surface Parax Matrix and Translation
for j=1:length(in_order)
     vertex_z(j)=[list{in_order(j)}.z_pos];    
    aper_diam(j)=[list{in_order(j)}.diam];
    
    if j>=2
       switch  list{in_order(j-1)}.type
        case {'refractive','flat','thin','diaphragm','mirror'}
            th(j-1)=vertex_z(j)-vertex_z(j-1); %traveled distance
            transl_M{j-1}=paraxComputeTranslationMatrix(th(j-1),N(:,j),matrix_type);
        case {'thick','GRIN'}
            th(j-1)=vertex_z(j)-(vertex_z(j-1)+list{in_order(j-1)}.th); %traveled distance
            transl_M{j-1}=paraxComputeTranslationMatrix(th(j-1),N(:,j),matrix_type);
       end
       matrix_list{j+in_transl}=('translation');
       in_transl=in_transl+1;
    end    
    matrix_list{j+in_transl}={list{in_order(j)}.type};
    switch  list{in_order(j)}.type
        case {'refractive','flat'}
            [surf_M{j}]=paraxComputeSurfaceMatrix(list{in_order(j)},N(:,j),matrix_type);
             N(:,j+1)=list{in_order(j)}.N;
        case {'mirror'}
            [surf_M{j}]=paraxComputeSurfaceMatrix(list{in_order(j)},N(:,j),matrix_type);            
            N(:,j+1)=N(:,j);
        case {'thin'}
            [surf_M{j}]=paraxComputeSurfaceMatrix(list{in_order(j)},N(:,j),matrix_type);
            N(:,j+1)=list{in_order(j)}.N(:,2);
        case {'thick'}
            [surf_M{j}]=paraxComputeSurfaceMatrix(list{in_order(j)},N(:,j),matrix_type);
            N(:,j+1)=list{in_order(j)}.N(:,3);
        case {'GRIN','GRINlens'} 
            [surf_M{j}]=paraxComputeSurfaceMatrix(list{in_order(j)},N(:,j),matrix_type);
            N(:,j+1)=list{in_order(j)}.N(:,2);
        case {'diaphragm'}
            surf_M{j}=eye(2,2);
            surf_M{j}=repmat(surf_M{j},1,size(OptSyst.wave,1));
            surf_M{j}=reshape(surf_M{j},2,2,size(OptSyst.wave,1));
            N(:,j+1)=N(:,j);  
        otherwise
            warning(['Not fount a valid M matrix type for the ', num2str(j),'a surface'])
    end
    
    % Augmented Parameters
    if OptSyst.surfs.augParam.exist==1
        augParam{j}=OptSyst.surfs.augParam.list{in_order(j)};
    end

    
end

%% Compute Optical System Matrix  (abcd)
comp_type='OpticalSystem';
 if OptSyst.surfs.augParam.exist==1
     [abcd,Dyu]=paraxComputeOverallMatrix(comp_type,surf_M,transl_M,augParam);
 else
     [abcd]=paraxComputeOverallMatrix(comp_type,surf_M,transl_M);
     Dyu=zeros(2,1,size(OptSyst.wave,1));
 end

 %SET output
abcd=abcd;

allM.surf=surf_M;allM.transl=transl_M; allM.list=matrix_list;

if nargout>1
   varargout{1}=Dyu; %set not-center parameters
    %3x3 abcd augmented matrix
    if nargout>2
        varargout{2}(1:2,1:2,:)=abcd;
        varargout{2}(1:2,3,:)=Dyu;
        varargout{2}(3,1:2,:)=0;
        varargout{2}(3,3,:)=1;
    end
end


