function [rotM, translateM, scaleM] = piTransformWorld2Obj(thisR, nodeToRoot)
% Find rotation and translation from world axis to object axis
%
% Synopsis
%   [rotM, translateM, scaleM] = piTransformWorld2Obj(thisR, nodeToRoot)
%
% Brief description
%  The translation and rotations are represented with respect to homogeneous
%  coordinates. Represented in matrix (4 x 4), with each row represents one
%  dimension.
%
%  We multiply any scale branches together.  This is OK as long as the
%  scale is always expressed in the object coordinate frame.
%
% Input
%    thisR
%    nodeToRoot
%
% Key/val
%    N/A
%
% Output
%    rotM   - 4x4 matrix representing rotation
%    transM - 4x4 matrix representing translation
%    scaleM - vector of object size scale factors
%
% See also
%    recipeGet

%%
rotM   = eye(4);
translateM = eye(4);
scaleM = ones(1,3);   % Scale factors

for ii=numel(nodeToRoot):-1:1
    % Get asset and its rotation and translation
    thisAsset = thisR.get('asset', nodeToRoot(ii));
    if iscell(thisAsset), thisAsset = thisAsset{1}; end
    if isequal(thisAsset.type, 'branch')
        pointerT = 1; pointerR = 1; pointerS = 1;
        for tt = 1:numel(thisAsset.transorder)
            switch thisAsset.transorder(tt)
                case 'T'
                    thisTrans = thisAsset.translation{pointerT};

                    % This was here for a long time.  But we think
                    % thisTrans is unchanged through this calculation.
                    %  So we are deleting and just adding the
                    %  translation.
                    %{
                    curTransM =  piTransformTranslation(rotM(:, 1),...
                        rotM(:, 2),...
                        rotM(:, 3), thisTrans);
                    transM(1:3, 4) = transM(1:3, 4) + curTransM(1:3, 4);
                    %}

                    % Add the translation to the fourth column
                    translateM(1:3, 4) = translateM(1:3, 4) + thisTrans(:);

                    % At one point, we combined the scale with the
                    % translation.  Then Zhenyi and I took that out.
                    % We are looking into it.  11/15/2023.
                    % transM(1:3, 4) = transM(1:3, 4) + curTransM(1:3, 4) .* scaleM';
                    pointerT = pointerT + 1;
                    
                case 'R'
                    rotDegs = thisAsset.rotation{pointerR}(1,:);
                    thisRotM = piTransformDegs2RotM(rotDegs, rotM);
                    % Update x y z axis
                    [~, ~, ~, rotM] = piTransformAxis(rotM(:,1), rotM(:,2),rotM(:,3),thisRotM);

                    pointerR = pointerR + 1;
                case 'S'
                    thisScale = thisAsset.scale{pointerS};
                    scaleM = scaleM * diag(thisScale);
                    pointerS = pointerS + 1;
            end
        end

        %{
        % Residual code for previous structure
        thisTrans = piAssetGet(thisAsset, 'translate');
        thisScale = piAssetGet(thisAsset, 'scale');

        % Calculate this translation matrix
        curTransM =  piTransformTranslation(rotM(:, 1),...
            rotM(:, 2),...
            rotM(:, 3), thisTrans);
        transM(1:3, 4) = transM(1:3, 4) + curTransM(1:3, 4);
        scaleM = scaleM * diag(thisScale);


        % Section was wrapped into function piTransformDegs2RotM
        thisRot = fliplr(piAssetGet(thisAsset, 'rotate')); % PBRT uses wired order of ZYX
        % Calculate rotation transform
        thisRotM = eye(4);
        for jj=1:size(thisRot, 2)
            if thisRot(1, jj) ~= 0
                % rotation matrix from basis axis
                curRotM = piTransformRotation(rotM(:, jj), thisRot(1, jj));
                thisRotM = curRotM * thisRotM;
            end
        end
        % Update x y z axis
        [~, ~, ~, rotM] = piTransformAxis(rotM(:,1), rotM(:,2),rotM(:,3),thisRotM);
        %}
    end
end

end
