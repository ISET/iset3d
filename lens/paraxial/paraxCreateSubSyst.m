


function [SubSyst] = paraxCreateSubSyst(OptSyst,sub_index,n_ob,n_im,varargin)

% Function: Create an SubSystem from an Optical System
%
%       function [SubSyst] = paraxCreateSubSyst(OptSyst,sub_index,n_ob,n_im,varargin)
%
%INPUT
%OptSyst:optical system structure with K surface
%sub_index: vector (1xL) with the surface number to be included in the sub
%system.  

%OUTPUT
%SubSyst: struct of the SubSyst

%NOTE =L<K  subsystem composed with less surfaces that original system
%       sub_index refer to the number of the elements before sorting
%
% MP Vistasoft 2014


%% SET VALUEs
SubSyst.wave=OptSyst.wave;

%Unit
SubSyst.unit=OptSyst.unit;

%% Add and sort the list of surfaces along the optical axis
SubSyst.surfs.list={};

for i=1:length(sub_index)
    SubSyst.surfs.list{i}=OptSyst.surfs.list{sub_index(i)};
end

if length(sub_index)==1
    SubSyst.surfs.order=[1];
else
    [SubSyst.surfs.order]=paraxSortSurfaceList(SubSyst.surfs.list);
end
% if length(sub_index)==1
%     SubSyst.surfs.list{1}=OptSyst.surfs.list{sub_index};
%     SubSyst.surfs.order=[1];
% else
%     SubSyst.surfs.list=OptSyst.surfs.list{sub_index}; 
%     [SubSyst.surfs.order]=paraxSortSurfaceList(SubSyst.surfs.list);
% end


%% Refractive index of image and object space of the new subsystem
%Object side
SubSyst.n_ob=n_ob;
SubSyst.n_im=n_im;


%Augment parameters for not center surfaces
% list_augParam={};
anyNotCen=0; %flag
if length(SubSyst.surfs.list)==1
    list_surf{1}=SubSyst.surfs.list{1};
%     list_augParam{1}=OptSyst.surfs.augParam.list{sub_index};
else   
    list_surf=SubSyst.surfs.list;
%     list_augParam=OptSyst.surfs.augParam.list{sub_index};
end

for j=1:length(list_surf)
    if isempty(list_surf{j}.augParam.Dy_dec)
        list_augParam{j}(1,1)=0;
    else
        list_augParam{j}(1,1)=list_surf{j}.augParam.Dy_dec;
        anyNotCen=1;% exist not-centered surface
    end
    if isempty(list_surf{j}.augParam.Du_tilt)
        list_augParam{j}(2,1)=0;
    else
        list_augParam{j}(2,1)=list_surf{j}.augParam.Du_tilt;
        anyNotCen=1;% exist not-centered surface
    end
end
SubSyst.surfs.augParam.exist=anyNotCen;
SubSyst.surfs.augParam.list=list_augParam;



%% Compute reduced matrix (augmented parameters are used only in case that one or more surface are not centered (decentred or/and tilted)
    SubSyst.surfs.matrix.computed_order=SubSyst.surfs.order;
if SubSyst.surfs.augParam.exist
    matrix_type='reduced';
    [SubSyst.matrix.abcd_red,allMred,SubSyst.matrix.augParam_red,SubSyst.matrix.abcdef_red]=paraxComputeOptSystMatrix(SubSyst,matrix_type);
    SubSyst.surfs.matrix.surf_red=allMred.surf;SubSyst.surfs.matrix.transl_red=allMred.transl;SubSyst.surfs.matrix.list=allMred.list;
    %then compute not reduced matrix
    matrix_type='not-reduced';
    [SubSyst.matrix.abcd,allM,SubSyst.matrix.augParam,SubSyst.matrix.abcdef]=paraxComputeOptSystMatrix(SubSyst,matrix_type);
    SubSyst.surfs.matrix.surf=allM.surf;SubSyst.surfs.matrix.transl=allM.transl;

else
    matrix_type='reduced';
    [SubSyst.matrix.abcd_red,allM,SubSyst.matrix.augParam_red]=paraxComputeOptSystMatrix(SubSyst,matrix_type);
    SubSyst.surfs.matrix.surf_red=allM.surf;SubSyst.surfs.matrix.transl_red=allM.transl;SubSyst.surfs.matrix.list=allM.list;
    SubSyst.matrix.abcdef_red=[];
    %then compute not reduced matrix
    matrix_type='not-reduced';
    [SubSyst.matrix.abcd,allM,SubSyst.matrix.augParam]=paraxComputeOptSystMatrix(SubSyst,matrix_type);
    SubSyst.surfs.matrix.surf=allM.surf;SubSyst.surfs.matrix.transl=allM.transl;
%     [OptSyst.matrix.abcd]=paraxMatrixRed2NotRed(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im);
    [SubSyst.matrix.abcdef]=[];
end



