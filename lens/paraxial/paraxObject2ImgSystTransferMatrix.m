% Compute the transfer matrix from the object to the first surface of an
% Optical system

function [Matrix]=paraxObject2ImgSystTransferMatrix(ImagSyst,object)

%INPUT
%ImagSyst: structure with the following fields: .cardPoints,.n_ob,.wave
%Object: struct for the object with the following fields: .z_pos
%varargin  {1} augParam (not mandatory to specify)
%OUTPUT
%Matrix: structure with multi elements: .abcd,.abcd_red,.abcdef,.abcdef_red


%NOT accepted augParameter for Object 
if nargin>2
    augParam=varargin{1};
else
    augParam=[0;0];
end



switch object.profile
    
    case {'point','pointsource','point source'}
        if object.z_pos<Inf
            fV=paraxGet(ImagSyst,'firstvertex');
            th=fV-object.z_pos;
%             th=ImagSyst.cardPoints.firstVertex-object.z_pos;
            M_red=paraxComputeTranslationMatrix(th,ImagSyst.n_ob,'reduced');
            M=paraxComputeTranslationMatrix(th,ImagSyst.n_ob,'not-reduced');
            %with augmented parameter       
            M_aug_red(1:2,1:2,:)=M_red;
            M_aug(1:2,1:2,:)=M;
            %intermediate variables
            for n=1:size(ImagSyst.wave,1)            
                M_aug_red(1:2,3,n)=augParam;
                M_aug(1,3,n)=augParam(1);
                M_aug(2,3,n)=augParam(2).*ImagSyst.n_ob(n);
            end
            M_aug_red(3,1:2,:)=0;
            M_aug_red(3,3,:)=1;
            M_aug(3,1:2,:)=0;
            M_aug(3,3,:)=1;
        else
            for li=1:size(ImagSyst.wave,1)
                M(:,:,li)=eye(2,2);M_red(:,:,li)=eye(2,2);
                M_aug_red(:,:,li)=eye(3,3);M_augm(:,:,li)=eye(3,3);
                M_aug_red(1:2,3,li)=augParam.*[ImagSyst.n_ob(li)];M_aug(1:2,3,li)=augParam;
            end
        end
        
        
    case {'flat','plane'} %all pixel are at the same distance from the last vertex of the Optical System
        
%         warning ('This section has to be completed!! Missing multi-dependent thickness')
        
        if object.z_pos<Inf
            fV=paraxGet(ImagSyst,'firstvertex');
            th=fV-object.z_pos;
%             th=ImagSyst.cardPoints.firstVertex-object.z_pos;
            M_red=paraxComputeTranslationMatrix(th,ImagSyst.n_ob,'reduced');
            M=paraxComputeTranslationMatrix(th,ImagSyst.n_ob,'not-reduced');
            %with augmented parameter       
            M_aug_red(1:2,1:2,:)=M_red;
            M_aug(1:2,1:2,:)=M;
            %intermediate variables
            for n=1:size(ImagSyst.wave,1)            
                M_aug_red(1:2,3,n)=augParam;
                M_aug(1,3,n)=augParam(1);
                M_aug(2,3,n)=augParam(2).*ImagSyst.n_ob(n);
            end
            M_aug_red(3,1:2,:)=0;
            M_aug_red(3,3,:)=1;
            M_aug(3,1:2,:)=0;
            M_aug(3,3,:)=1;
        else
            for li=1:size(ImagSyst.wave,1)
                M(:,:,li)=eye(2,2);M_red(:,:,li)=eye(2,2);
                M_aug_red(:,:,li)=eye(3,3);M_augm(:,:,li)=eye(3,3);
                M_aug_red(1:2,3,li)=augParam.*[1;ImagSyst.n_ob(li)];M_aug(1:2,3,li)=augParam;
            end
        end

    case {'spherical','sphere'} %all pixel are at difference distance from the last vertex of the Optical System
        
%         warning ('This section has to be completed!! Missing spherical-dependent thickness')
        
        if object.z_pos<Inf
            th=ImagSyst.cardPoints.firstVertex-Objectz_pos;
            M_red=paraxComputeTranslationMatrix(th,ImagSyst.n_ob,'reduced');
            M=paraxComputeTranslationMatrix(th,ImagSyst.n_ob,'not-reduced');
            %with augmented parameter       
            M_aug_red(1:2,1:2,:)=M_red;
            M_aug(1:2,1:2,:)=M;
            %intermediate variables
            for n=1:size(ImagSyst.wave,1)            
                M_aug_red(1:2,3,n)=augParam;
                M_aug(1,3,n)=augParam(1);
                M_aug(2,3,n)=augParam(2).*ImagSyst.n_ob(n);
            end
            M_aug_red(3,1:2,:)=0;
            M_aug_red(3,3,:)=1;
            M_aug(3,1:2,:)=0;
            M_aug(3,3,:)=1;
        else
            for li=1:size(ImagSyst.wave,1)
                M(:,:,li)=eye(2,2);M_red(:,:,li)=eye(2,2);
                M_aug_red(:,:,li)=eye(3,3);M_augm(:,:,li)=eye(3,3);
                M_aug_red(1:2,3,li)=augParam.*[1;magSyst.n_ob(li)];M_aug(1:2,3,li)=augParam;
            end
        end
        
        
end
%append matrix
Matrix.abcd_red=M_red;
Matrix.abcd=M;
Matrix.abcdef_red=M_aug_red;
Matrix.abcdef=M_aug;