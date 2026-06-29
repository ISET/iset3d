%% update assets in flywheel to v4
%
%  Deprecated.
%

%%
ieInit
st = scitran('stanfordlabs');

%%
assetType = {'city1','city2','city3','city4'};
for aa = 3:numel(assetType)
    session = st.lookup(sprintf('wandell/Graphics auto/assets/%s',assetType{aa}),true);
    acqs    = session.acquisitions();
    %%
    
    for dd = 1:numel(acqs)
        clearvars -except st acqs dd aa assetType
        
        assetname = acqs{dd}.label;
        % The lookup reads from group/project/subject/session/acquisition
        %     object_acq = st.lookup(sprintf('wandell/Graphics auto/assets/%s/%s',assetType, assetname),true);%
        
        % We are going to put the object here
        dstDir = fullfile(piRootPath, 'local',assetname);
        thisR = piFWAssetCreate(acqs{dd}, 'resources', true, 'dstDir', dstDir);
        
        %% update recipe
        % update material types
        materialKeys = keys(thisR.materials.list);
        for ii = 1:numel(materialKeys)
            thisMat = thisR.materials.list(materialKeys{ii});
            switch thisMat.type
                case 'uber'
                    if piContains(thisMat.kd.value,'wandell')
                        thisMat.kd.value = [0.6 0.6 0.6];
                    end
                    newMat = piMaterialCreate(materialKeys{ii}, ...
                        'type', 'coateddiffuse',...
                        'roughness',thisMat.roughness.value,...
                        'reflectance', thisMat.kd.value);
                case 'glass'
                    newMat = piMaterialCreate(materialKeys{ii}, ...
                        'type', 'dielectric',...
                        'eta', 1.3);
            end
            thisR.materials.list(materialKeys{ii}) = newMat;
        end
        % update texture
        texKeys = keys(thisR.textures.list);
        for ii = 1:numel(texKeys)
            thisTexture = thisR.textures.list(texKeys{ii});
            texPath = fullfile(dstDir, ['textures/', thisTexture.filename.value]);
            if ~piContains(thisTexture.filename.value,'textures/')&& ...
                    exist(texPath, 'file')
                thisTexture.filename.value = ['textures/', thisTexture.filename.value];
                thisR.textures.list(texKeys{ii})=thisTexture;
            elseif ~exist(texPath, 'file')
                thisTexture = piTextureCreate(texKeys{ii},'type','constant','value',[0.6 0.6 0.6]);
                thisR.textures.list(texKeys{ii})=thisTexture;
            end
        end
        %% update geometry pbrt
        
        cd(fullfile(dstDir,'scene/PBRT/pbrt-geometry'));
        pbrtList = dir(fullfile(dstDir,'scene/PBRT/pbrt-geometry/*.pbrt'));
        
        for pp = 1:numel(pbrtList)
            pbrtEXE = '/Users/zhenyi/git_repo/PBRT_code/pbrt_zhenyi/pbrt_gpu/pbrt-v4/build/pbrt';
            if ~exist(pbrtList(pp).name, 'file')
                sprintf('%s not exist\n', pbrtList(pp).name);
                continue;
            end
            if piContains(pbrtList(pp).name, ' ')
                newName = strrep(pbrtList(pp).name,' ','ext-');
                movefile(pbrtList(pp).name, newName);
                pbrtList(pp).name = newName;
            end
            newTempFile = ['new_',pbrtList(pp).name];
            update_cmd = [pbrtEXE, ' --upgrade ',pbrtList(pp).name,' > ', newTempFile];
            [status,result] = system(update_cmd);
            if status
                error(result);
            end
            movefile(newTempFile,pbrtList(pp).name);
            toply_cmd = [pbrtEXE, ' --toply ',pbrtList(pp).name, ' > ',newTempFile];
            [status,result] = system(toply_cmd);
            if status
                error(result);
            end
            if exist(fullfile(dstDir,'scene/PBRT/pbrt-geometry/mesh_00001.ply'),'file')
                meshFile = strrep(pbrtList(pp).name,'.pbrt','.ply');
                movefile('mesh_00001.ply',meshFile);
                delete(newTempFile);
                delete(pbrtList(pp).name);
            else
                checkGeometryConvertBugs(pbrtList(pp).name)
                delete(newTempFile);
                disp('No ply converted.')
            end
        end
        %% fix some bugs
        objIdxList = thisR.get('objects');
        for jj = 1:numel(objIdxList)
            thisNode = thisR.assets.Node{objIdxList(jj)};
            if piContains(thisNode.shape.filename,'.pbrt')
                if piContains(thisNode.shape.filename, ' ')
                    newName = strrep(thisNode.shape.filename,' ','ext-');
                    thisNode.shape.filename = newName;
                end
                plyfile = strrep(thisNode.shape.filename,'.pbrt','.ply');
                if exist(plyfile,'file')
                    thisNode.shape.meshshape = 'plymesh';
                    thisNode.shape.filename = plyfile;
                    thisR.assets = thisR.assets.set(objIdxList(jj),thisNode);
                elseif exist(thisNode.shape.filename,'file')
                    thisNode.shape.meshshape = 'trianglemesh';
                    thisR.assets = thisR.assets.set(objIdxList(jj),thisNode);
                end
            end
            
            if isempty(thisNode.material.namedmaterial)
                thisNode.material.namedmaterial = materialKeys{1};
                thisR.assets = thisR.assets.set(objIdxList(jj),thisNode);
            end
            
            if isempty(find(piContains(materialKeys, thisNode.material.namedmaterial),1))
                % if the material is not defined, use the first material.
                thisNode.material.namedmaterial = materialKeys{1};
                thisR.assets = thisR.assets.set(objIdxList(jj),thisNode);
            end
        end
        %%
        thisR.world = {'WorldBegin'};
        thisR.film.subtype = 'gbuffer';
        if isfield(thisR.integrator,'strategy')
            thisR.integrator = rmfield(thisR.integrator,'strategy');
        end
        thisR.version = 4;
        
        thisR.set('fov',38);
        thisR.set('pixelsamples',16);
        thisR.integrator.subtype = 'path';
        thisR.set('film resolution',[800, 500]);
        %     iaAutoMaterialGroupAssign(thisR);
        outfile  = thisR.get('outputfile');
        [~, fname,ext] = fileparts(outfile);
        thisR.set('outputFile',fullfile(piRootPath,'local',fname,[fname,ext]));
        thisR.lights{1}.mapname.value = [];
        thisR.lights{1}.spd.value = 6500;
        thisR.lights{1}.spd.type = 'blackbody';
        piWrite(thisR);
        scene = piRender(thisR);
        %%
        cd(dstDir);
        outFile = thisR.get('outputfile');
        [outFolder, fname,~]=fileparts(outFile);
        EXRFile = fullfile(outFolder, 'renderings',[fname,'.exr']);
        pngFile(:,:,1)  = single(py.pyexr.read(EXRFile,'R'));
        pngFile(:,:,2)  = single(py.pyexr.read(EXRFile,'G'));
        pngFile(:,:,3)  = single(py.pyexr.read(EXRFile,'B'));
        pngFile = imadjust(pngFile,[],[],0.5);
        figure(1);
        imshow(pngFile);
        jpgFile = sprintf('%s.jpg',assetname);
        imwrite(pngFile,jpgFile);
        
        
        %     folder = fullfile(piRootPath,'local',assetname);
        %     chdir(folder);
        resourceFile = sprintf('%s.cgresource.zip',assetname);
        zip(resourceFile,{'textures','scene'});
        oldRecipeFile = sprintf('%s.json',assetname);
        recipeFile = sprintf('%s.recipe.json',assetname);
        movefile(oldRecipeFile,recipeFile);
        %% There could be an stScitranConfig
        
        current_acquisitions = assetname;
        
        try
            acquisition = st.lookup(sprintf('wandell/Graphics auto v4/assets/%s/%s',assetType{aa}, assetname),true);
            st.fileUpload(recipeFile,acquisition.id,'acquisition');
            fprintf('%s uploaded \n',recipeFile);
            st.fileUpload(resourceFile,acquisition.id,'acquisition');
            fprintf('%s uploaded \n',resourceFile);
            st.fileUpload(jpgFile,acquisition.id,'acquisition');
            fprintf('%s uploaded \n',jpgFile);toc
            cd(piRootPath);
            rmdir(dstDir,'s');
        catch
            disp('Creating acq...')
            current_id = st.containerCreate('Wandell Lab', 'Graphics auto v4',...
                'session',assetType{aa},'subject','assets','acquisition',current_acquisitions);
            if ~isempty(current_id.acquisition)
                fprintf('%s acquisition created \n',current_acquisitions);
            end
            st.fileUpload(recipeFile,current_id.acquisition,'acquisition');
            fprintf('%s uploaded \n',recipeFile);
            st.fileUpload(resourceFile,current_id.acquisition,'acquisition');
            fprintf('%s uploaded \n',resourceFile);
            st.fileUpload(jpgFile,current_id.acquisition,'acquisition');
            fprintf('%s uploaded \n',jpgFile);toc
            cd(piRootPath);
            rmdir(dstDir,'s');
        end
        
        
    end
end

function checkGeometryConvertBugs(outputFull)
fileID = fopen(outputFull);
tmp = textscan(fileID,'%s','Delimiter','\n','CommentStyle',{'#'});
% tmp = textscan(fileID,'%s','Delimiter','\n');

txtLines = tmp{1};
fclose(fileID);
txtLinesFormated = piFormatConvert(txtLines);
try
    thisShape = piParseShape(txtLinesFormated{1});
catch
    disp('debug');
end
fileIDin = fopen(outputFull);
outputFullTmp = fullfile(piRootPath, ['local/tmp-',num2str(randi(100)),'.pbrt']);
fileIDout = fopen(outputFullTmp, 'w');
shapeText = piShape2Text(thisShape);
fprintf(fileIDout, '%s', shapeText);
fclose(fileIDin);
fclose(fileIDout);
movefile(outputFullTmp, outputFull);
end