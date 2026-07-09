%% Upload local material textures into the PBRTResources database
%
% This script publishes the image files in piDirGet('textures') to the shared
% acorn resource tree:
%
%   /acorn/data/iset/PBRTResources/texture
%
% and creates one PBRTResources database record per missing texture file.
%
% The default block is a dry run.  Review the table, then set dryRun to false
% to sync files and create missing database records.
%
% See also
%   piTextureResourcesUpload, isetdb, s_dbResources

%%
ieInit;

%% Review what would be uploaded and registered

dryRun = true;
textureReport = piTextureResourcesUpload('dry run', dryRun);

%% Publish the textures
%
% Set dryRun to false when ready.  Existing remote files are skipped when the
% byte count matches, and existing database records are skipped when they
% already have the same texture mainfile.

% dryRun = false;
% textureReport = piTextureResourcesUpload('dry run', dryRun);

%% Confirm registered texture resources after publishing
%
% pbrtDB = isetdb();
% remoteTextures = pbrtDB.contentFind('PBRTResources', ...
%     'type', 'texture', ...
%     'show', true);

%% END
