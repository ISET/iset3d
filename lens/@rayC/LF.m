function LF = LF(obj,position)
% Return the light field at the entrance, middle aperture, or exit plane
%
% Example:
%    ppsf.LF('in')
%    ppsf.LF('out')
%
% See Also
%   s3dLightField, s3dVOLTLFFromPosDir
%
% AL Vistasoft Copyright 2014


if notDefined('position'), position = 'out'; end

switch position
    case 'in'
        % 2 x nSamples_in_aperture x nWave
        %Andy: TODO: fix this bug... aEntranceInt isn't updated
        %correctly... when rays are blocked/apodized...
        inXY = obj.aEntranceInt.XY';
        inDir = ...
            [inXY(1, :) - obj.pointSourceLocation(1);
            inXY(2, :) - obj.pointSourceLocation(2);
            obj.aEntranceInt.Z * ones(size(inXY(1,:))) - obj.pointSourceLocation(3)];
        inDir = normvec(inDir, 'dim', 1);

        M = s3dVOLTLFFromPosDir(inXY, inDir);
        
    case 'middle'
        middleXY  = obj.aMiddleInt.XY';
        middleDir = obj.aMiddleDir';
        middleDir = normvec(middleDir, 'p', 2, 'dim', 1);
        
        M = s3dVOLTLFFromPosDir(middleXY, middleDir);
        
    case 'out'
        outXY  = obj.aExitInt.XY';
        outDir = obj.aExitDir';
        outDir = normvec(outDir, 'p', 2, 'dim', 1);
        
        M = s3dVOLTLFFromPosDir(outXY, outDir);
        
    otherwise
        error('Unknown position %s',position)
end

LF = LFC('LF',M,'wave',obj.wave,'waveIndex',obj.waveIndex);

end
