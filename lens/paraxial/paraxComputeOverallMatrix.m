

function [Mt,varargout]=paraxComputeOverallMatrix(comp_type,varargin)
%  Compute System Matrix
%
%       function [Mt,varargout]=paraxComputeOverallMatrix(comp_type,varargin)
%
%INPUT
%comp_type:  type of system to compute
     %      'OpticalSystem':  vararging{1}: cell of K surface
     %          transformations (2x2xN) N  sampling; varargin{2}: cell of K-1
     %          translation matrix; varargin{3}: cell of K augmented parameters
     %          for the relative surface transformation     
%OUTPUT
%Mt: (2x2xN) output matrix
%
% NOTE: K # of non-translation transoformation; N # of wavelength for the system sampling
%       all the matrices should be built homogenously
%
% MP Vistasoft 2014


switch comp_type
    case {'OpticalSystem','OptSyst','abcd','abcd_red'}
        surf_M=varargin{1};transl_M=varargin{2};
        augParam_exist=0;
        if nargin>3
            augParam_exist=1;
            augParam=varargin{3}; 
        end
       % Check of elements size 
       if (size(surf_M,2)-1==size(transl_M,2))
           n_mat=size(surf_M,2)+size(transl_M,2); %num matrices (all type)
           n_surf=size(surf_M,2);n_transl=size(transl_M,2);
           if augParam_exist
               Dyu=[0;0];% initialization at zero
               Dyu=repmat(Dyu,1,size(surf_M{1},3));
               Dyu=reshape(Dyu,2,1,size(surf_M{1},3));
               %Create starting matrix (Identity)
               Mt=eye(2,2);
               Mt=repmat(Mt,1,size(surf_M{1},3));
               Mt=reshape(Mt,2,2,size(surf_M{1},3));               
               for k=1:size(surf_M,2) %move along the surface
                   if k<size(surf_M,2)
                       for n=1:size(surf_M{k},3) %move between the wavelenghts
                          Dyu(:,:,n)=Mt(:,:,n)*augParam{end+1-k}+Dyu(:,:,n); %Dyu=sum[r=1 to n]{Qr+1*Dyu_r}   Qr=Mk*Mk-1*Mk-2*....Mr
                          Mt(:,:,n)=Mt(:,:,n)*surf_M{end+1-k}(:,:,n)*transl_M{end+1-k}(:,:,n); %Mt=Mk*Mk-1*Mk-2*....*M3*M2*M1
                       end
                   else
                       for n=1:size(surf_M{k},3) %move between the wavelenghts
                          Dyu(:,:,n)=Mt(:,:,n)*augParam{end+1-k}+Dyu(:,:,n); %Dyu=sum[r=1 to n]{Qr+1*Dyu_r}
                          Mt(:,:,n)=Mt(:,:,n)*surf_M{end+1-k}(:,:,n); %Mt=Mk*Mk-1*Mk-2*....*M3*M2*M1
                       end
                   end
               end
               varargout{1}=Dyu;
           else
               %Case of computation without augmented parameter
               %Create starting matrix (Identity)
               Mt=eye(2,2);
               Mt=repmat(Mt,1,size(surf_M{1},3));
               Mt=reshape(Mt,2,2,size(surf_M{1},3));               
               for k=1:size(surf_M,2) %move along the surface
                   if k<size(surf_M,2)
                       for n=1:size(surf_M{k},3) %move between the wavelenghts                          
                          Mt(:,:,n)=Mt(:,:,n)*surf_M{end+1-k}(:,:,n)*transl_M{end+1-k}(:,:,n); %Mt=Mk*Mk-1*Mk-2*....*M3*M2*M1                          
                       end
                   else
                       for n=1:size(surf_M{k},3) %move between the wavelenghts
                          Mt(:,:,n)=Mt(:,:,n)*surf_M{end+1-k}(:,:,n); %Mt=Mk*Mk-1*Mk-2*....*M3*M2*M1
                       end
                   end
               end
               
           end           
       else
           warning('#of surfaces matrixes does not match to #of translation matrixes!\n Use different method for compute the overall matrix  or adjust input data ');
           Mt=[];           
       end
end