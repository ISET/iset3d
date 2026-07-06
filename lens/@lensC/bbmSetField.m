function bbmSetField(obj,pName,val)
% Build the field to append to Black Box Model
%
%  val = bbmSetValue(BBoxModel,fileType)
%
%
%INPUT
% pName: field name
% val: value
%
%
%fileType: specify which field {'all';'focallength';'focalradius';
%                 'imagefocalpoint';'imageprincipalpoint';'imagenodalpoint';
%                 'objectfocalpoint';'objectprincipalpoint';'objectnodalpoint';'abcd'}
%
% OUTPUT
% field:       "pName"            "field name"
%              focal length->   .focal.length
%             focal plane radius->   .focal.radius
%             abcd equivalent matrix-> .abcdMatrix
%       IMAGE SPACE
%             focal point ->  .imSpace.focalPoint
%             principal point ->  .imSpace.principalPoint
%             principal point ->  .imSpace.nodalPoint
%
%       OBJECT SPACE
%             focal point -> .obSpace.focalPoint
%             principal point -> .obSpace.principalPoint
%             principal point ->.obSpace.nodalPoint
%
%        ALL struct
%                 OUTPUT=INPUTvalue
%
% MP Vistasoft 2014

switch pName
    case {'effectivefocallength';'efl'}
        obj.BBoxModel.focal.length=val;       %focal length
    case {'focalradius'}
        obj.BBoxModel.focal.radius=val;       %focal plane radius
    case {'imagefocalpoint'}
        obj.BBoxModel.imSpace.focalPoint=val; %focal point in image space
    case {'objectfocalpoint'}
        obj.BBoxModel.obSpace.focalPoint=val; %focal point in object space
    case {'imageprincipalpoint'}
        obj.BBoxModel.imSpace.principalPoint=val; %principal point in image space
    case {'objectprincipalpoint';'objprincipalpoint'}
        obj.BBoxModel.obSpace.principalPoint=val; %principal point in object space
    case {'imagenodalpoint'}
        obj.BBoxModel.imSpace.nodalPoint=val; %principal point in image space
    case {'objectnodalpoint';'objnodalpoint'}
        obj.BBoxModel.obSpace.nodalPoint=val; %principal point in image space
    case {'abcd';'abcdmatrix';'abcdMatrix'}
        obj.BBoxModel.abcd=val;               %abcd Matrix
    case {'all'}
        obj.BBoxModel=val;                    %all struct
    otherwise
        error (['Not valid: ',pName,' as field of Black Box Model'])
end


end
