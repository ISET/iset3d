function [value]=paraxGetOptSyst(OptSyst,pName)
% Function: get specific value from an optical  system
%
%    [value]=paraxGetOptSyst(syst,systType,pName)
%
%
%INPUT
%  OptSyst: System structure [Optical System or Imaging System]
%  pName: specify which features to get
%  varargin: 
%
%OUTPUT
%  value: 
%
%
% MP Vistasoft 2014


%% Which feature or field?
pName=ieParamFormat(pName);



%% SWITCH for CASE

switch pName
    case {'wave'}
        value=OptSyst.wave;
    case {'unit'}
        value=OptSyst.unit;
    case {'n_ob';'objectrefractiveindex'; 'objrefrindex';'objectspacerefractiveindex'}
        value=OptSyst.n_ob;
    case {'n_im';'imagerefractiveindex'; 'imrefrindex';'imagespacerefractiveindex'}
        value=OptSyst.n_im;
    case {'surforder'} %surface orders
        value=OptSyst.surfs.order;
    case {'surflist'}  %List of surfaces
        value=OptSyst.surfs.list;
    case {'abcdmatrix';'abcd'}  % not reduced abcd matrix
       [value]=OptSyst.matrix.abcd;
    case {'abcdmatrixreduced';'abcdreduced';'abcdmatrixred';'abcdred'} %reduced abcd matrix
       [value]=OptSyst.matrix.abcd;
   case {'firstvertex'}
        ord=paraxGetOptSyst(OptSyst,'surforder');
        value=OptSyst.surfs.list{ord(1)}.z_pos;
%         value=OptSyst.surfs.list{OptSyst.surfs.order(1)}.z_pos;
    case {'lastvertex'}
        ord=paraxGetOptSyst(OptSyst,'surforder');
        value=OptSyst.surfs.list{ord(end)}.z_pos;
%         value=OptSyst.surfs.list{OptSyst.surfs.order(end)}.z_pos;
    case {'cardinalpoints';'cardpoint'} 
        %Compute cardinal point
        [OptSyst.cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced');
        % Add vertices of first and last surfaces (useful to find the 
%         % position of cardinal point along the optical axis
%         OptSyst.cardPoints.firstVertex = OptSyst.surfs.list{OptSyst.surfs.order(1)}.z_pos;
%         OptSyst.cardPoints.lastVertex  = OptSyst.surfs.list{OptSyst.surfs.order(end)}.z_pos;
        
        OptSyst.cardPoints.firstVertex = paraxGetOptSyst(OptSyst,'firstvertex');
        OptSyst.cardPoints.lastVertex  = paraxGetOptSyst(OptSyst,'lastvertex');
        [value]=OptSyst.cardPoints;      
       
    case {'effectivefocallength';'efl'}
        %Compute cardinal point
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced');        
        value=cardPoints.fi; %focal length in image space
    case {'imagefocallength'}
        %Compute cardinal point
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced');        
        value=cardPoints.fi; %focal length in image space
    case {'objectfocallength'}
        %Compute cardinal point
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced');        
        value=cardPoints.fo; %focal length in image space
    case {'focalradius';'petzval';'petzvalradius'}
        fi=paraxGetOptSyst(OptSyst,'imagefocallength');
        petzvalParam=paraxComputePetzvalSum(OptSyst.surfs,...
            OptSyst.n_ob,OptSyst.n_im,fi,OptSyst.wave);
        value=petzvalParam.radius; %focal plane radius
    case {'focalpoint'}
        fV=paraxGetOptSyst(OptSyst,'firstvertex'); %first vertex of the optical system
        lV=paraxGetOptSyst(OptSyst,'lastvertex'); % last vertex of the optical system
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced'); %cardinal point
        value.imPoint=cardPoints.dFi+lV; %focal point in image space
        value.obPoint=cardPoints.dFo+fV; %focal point in object space
        
    case {'imagefocalpoint'}
        lV=paraxGetOptSyst(OptSyst,'lastvertex'); % last vertex of the optical system
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced'); %cardinal point
        value=cardPoints.dFi+lV; %focal point in image space
    case {'objectfocalpoint'}
        fV=paraxGetOptSyst(OptSyst,'firstvertex'); %first vertex of the optical system
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced'); %cardinal point
        value=cardPoints.dFo+fV; %focal point in object space
    case {'principalpoint'}
        fV=paraxGetOptSyst(OptSyst,'firstvertex'); %first vertex of the optical system
        lV=paraxGetOptSyst(OptSyst,'lastvertex'); % last vertex of the optical system
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced'); %cardinal point
        value.imSpace=cardPoints.dHi+lV; %principal point in image space
        value.obSpace=cardPoints.dHo+fV; %principal point in object space
    case {'imageprincipalpoint'}        
        lV=paraxGetOptSyst(OptSyst,'lastvertex'); % last vertex of the optical system
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced'); %cardinal point
        value=cardPoints.dHi+lV; %principal point in image space
    case {'objectprincipalpoint';'objprincipalpoint'}
        fV=paraxGetOptSyst(OptSyst,'firstvertex'); %first vertex of the optical system
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced'); %cardinal point
         value=cardPoints.dHo+fV; %principal point in object space
   
    case {'nodalpoint'}
        fV=paraxGetOptSyst(OptSyst,'firstvertex'); %first vertex of the optical system
        lV=paraxGetOptSyst(OptSyst,'lastvertex'); % last vertex of the optical system
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced'); %cardinal point
        value=cardPoints.dNi+lV; %nodal point in image space
        value=cardPoints.dNo+fV; %nodal point in object space
    case {'imagenodalpoint'}
        lV=paraxGetOptSyst(OptSyst,'lastvertex'); % last vertex of the optical system
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced'); %cardinal point
        value=cardPoints.dNi+lV; %nodal point in image space
    case {'objectnodalpoint';'objnodalpoint'}
        fV=paraxGetOptSyst(OptSyst,'firstvertex'); %first vertex of the optical system
        [cardPoints] = ...
         paraxMatrix2CardinalPoints(OptSyst.matrix.abcd_red,OptSyst.n_ob,OptSyst.n_im,'reduced'); %cardinal point
        value=cardPoints.dNo+fV; %nodal point in object space        
    case {'entrancepupils';'enps'} % Possible Entrance Pupils
        pupil_type1 = 'EnP';
        value=paraxFindPupils(OptSyst,pupil_type1);
    case {'exitpupils';'exps'}  % Possible Exit Pupils
        pupil_type2 = 'ExP';
        value=paraxFindPupils(OptSyst,pupil_type2);
    case {'pupils'}  % Possible  Pupils
        pupils.EnPs=paraxFindPupils(OptSyst,'entrance');
        pupils.ExPs=paraxFindPupils(OptSyst,'exit');
        pupils.computed_order=paraxGetOptSyst(OptSyst,'surforder');
        value=pupils;
    otherwise
        error(['Non valid: ',type,' as system type!'])
end

