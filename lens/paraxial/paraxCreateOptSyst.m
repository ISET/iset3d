function [OptSyst]=paraxCreateOptSyst(list_surf,n_ob,n_im,unit,wavelength,varargin)
% Function: Create an Optical System
%
%    [OptSyst]=paraxCreateOptSyst(list_surf,n_ob,n_im,unit,wavelength,varargin)
%
%
%INPUT
%  list_surf: list of the surface structures in the optical system
%  n_ob: refractive index in object space
%  n_im: refractive index in image space
%  unit: unit refers to distance e.g. 'mm' ,'m'
%  wavelength: (column) of the wavelength of refractive indices (in unit)
%              Typically in millimeters here.  The rest of the code 
%  varargin: 
%
%OUTPUT
%  OptSyst: struct of the OptSyst
%
%c.v. =column vector for wavelenght dependence
%
% MP Vistasoft 2014

%% CHECKs

%Wavelength must be a column vector
wavelength   = wavelength(:);
OptSyst.wave = wavelength;

%Unit
OptSyst.unit=unit;

%Type
OptSyst.type='Optical System';

%Refractive index of image and object space
[n_ob]=checkNandWave(n_ob,wavelength);
[n_im]=checkNandWave(n_im,wavelength);

OptSyst.n_ob=n_ob; OptSyst.n_im=n_im;


%% Add and sort the list of surfaces along the optical axis
OptSyst.surfs.list = list_surf;

[OptSyst.surfs.order] = paraxSortSurfaceList(OptSyst.surfs.list);

%According to the sorting check and fill missing field on the surface
%structures
[OptSyst.surfs.list] = paraxCheckSurfaceList(OptSyst.surfs,n_ob,n_im);

%Augment parameters for surfaces that are not centered or not perpendicular
%to the main axis
list_augParam={};
anyNotCen=0; %flag

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
OptSyst.surfs.augParam.exist=anyNotCen;
OptSyst.surfs.augParam.list=list_augParam;



%% Compute reduced matrix 
% Aaugmented parameters are used only in case that one or more surface are
% not centered (decentred or/and tilted) 

OptSyst.surfs.matrix.computed_order = OptSyst.surfs.order;

% This code creates both a 'reduced' and 'not-reduced' optical system.
%
% The reduced one is used when we combine the effects of several optical
% systems as a chain.
%
% The not-reduced one is used when we only want the output light field when
% we know the input light field (height and angle)
%
if OptSyst.surfs.augParam.exist
    % The augmented parameters already exist
    matrix_type='reduced';
    [OptSyst.matrix.abcd_red,allMred,OptSyst.matrix.augParam_red,OptSyst.matrix.abcdef_red] = ...
        paraxComputeOptSystMatrix(OptSyst,matrix_type);
    OptSyst.surfs.matrix.surf_red=allMred.surf;OptSyst.surfs.matrix.transl_red=allMred.transl;
    OptSyst.surfs.matrix.list=allMred.list;
    
    %Then compute not reduced matrix
    matrix_type='not-reduced';
    [OptSyst.matrix.abcd,allM,OptSyst.matrix.augParam,OptSyst.matrix.abcdef]= ...
        paraxComputeOptSystMatrix(OptSyst,matrix_type);
    OptSyst.surfs.matrix.surf=allM.surf;OptSyst.surfs.matrix.transl=allM.transl;

else
    % The augmented parameters don't exist
    matrix_type='reduced';
    [OptSyst.matrix.abcd_red,allM,OptSyst.matrix.augParam_red] = ...
        paraxComputeOptSystMatrix(OptSyst,matrix_type);
    OptSyst.surfs.matrix.surf_red   = allM.surf;
    OptSyst.surfs.matrix.transl_red = allM.transl;OptSyst.surfs.matrix.list=allM.list;
    OptSyst.matrix.abcdef_red = [];
    %then compute not reduced matrix
    matrix_type='not-reduced';
    [OptSyst.matrix.abcd,allM,OptSyst.matrix.augParam] = ...
        paraxComputeOptSystMatrix(OptSyst,matrix_type);
    OptSyst.surfs.matrix.surf=allM.surf;OptSyst.surfs.matrix.transl = allM.transl;
    
    % [OptSyst.matrix.abcd]=paraxMatrixRed2NotRed(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im);
    [OptSyst.matrix.abcdef]=[];
end
OptSyst.matrix.computed_order=OptSyst.surfs.order;% It indicates the order of the surfaces used to compute the abcd Matrix

% %% FIND CARDINAL POINTS from ABCD matrices
% 
% % These might all be bbm get calls, so we can't have any inconsistencies.
% 
% [OptSyst.cardPoints] = ...
%     paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced');
% 
% % Add vertices of first and last surfaces (useful to find the 
% % position of cardinal point along the optical axis
% OptSyst.cardPoints.firstVertex = OptSyst.surfs.list{OptSyst.surfs.order(1)}.z_pos;
% OptSyst.cardPoints.lastVertex  = OptSyst.surfs.list{OptSyst.surfs.order(end)}.z_pos;


%% Compute the possible Entrance Pupils (EnP) and Exit Pupils (ExP)

% % We need these so that we can determine which is the smallest pupil.  
% pupil_type1 = 'EnP';
% EnPs=paraxFindPupils(OptSyst,pupil_type1);
% 
% pupil_type2 = 'ExP';
% ExPs=paraxFindPupils(OptSyst,pupil_type2);
% 
% OptSyst.Pupils.EnPs=EnPs;
% OptSyst.Pupils.ExPs=ExPs;
% 
% % It indicates the order of the surface by which En and Ex Pupils refer to
% OptSyst.Pupils.computed_order = OptSyst.surfs.order;

% %% Compute Petzval SUM to find curvature of the image plane
% [OptSyst.Petzval] = ...
%     paraxComputePetzvalSum(OptSyst.surfs,OptSyst.n_ob,OptSyst.n_im,OptSyst.cardPoints.fi,OptSyst.wave);
% 

%% END