function newMat = piMaterialPresets(keyword,materialName, options)
% Create materials that are tuned for appearance (preset)
%
% Brief
%   The named material and related textures are returned in a struct.
%
%   There are methods for listing all the available preset materials and
%   returning lists of different types.
%
% Syntax:
%    newMat = piMaterialPresets(keyword,materialName)
%
% Inputs:
%    keyword  - Individual material name, or a material class, or
%             list, or preview
%       You can also print out and return the list of materials in a class by
%       setting the keyword to 'class list', say 'glass list' or
%       'metal list'.
%
%    materialName - Name to assign to the material.
%
% Outputs:
%    newMat - Struct defining the material and texture
%
% Description
%  Our knowledge of specific materials is encapsulated in this function.
%  These materials are taken from examples in the PBRT code from other
%  groups.
%
%  To list all the available materials use
%
%     piMaterialPresets('list');
%
%   A cell array of all the preset materials is returned, and a printed,
%   numbered list shows the materials in the returned cell array and their
%   indices.
%
%  To list one class of materials call do
%
%     piMaterialPresets('glass list') or 'wood list' or ...
%       {'diffuse list','glossy list','glass list','metal list','car
%       list','marble list','testpatterns list','wood list'};
%
%  To preview the material appearance from one of the precomputed examples,
%  use:
%
%     piMaterialPresets('preview','fabric-leather-var1.jpg');
%
%  To list the materials available for preview use
%
%     piMaterialPresets('preview')
%
% See also
%   piMaterialsInsert, v_Materials
%

%Examples:
%{
  allMaterials = piMaterialPresets('list');
  piMaterialPresets('wood list')
%}
%{
  newMat = piMaterialPresets('glass','glass-demo');
%}
%{
  newMat = piMaterialPresets('wood-medium-knots','woodfloor');
  newMat.material.name
%}
%{
  % Not yet tested fully and does not work for all materials!
  piMaterialPresets('preview','fabric-leather-var1.jpg');
  piMaterialPresets('preview','rough-metal');
  piMaterialPresets('asphalt-uniform','road-surface');
  piMaterialPresets('asphalt-crack','road-surface');
  piMaterialPresets('preview','metal-Ag');  % Mirror
%}
%% Parameters

arguments
    keyword;
    materialName = keyword;
    options.show = true; % whether to show the help dialog
end

%% Depending on the key word, go for it.
switch ieParamFormat(keyword)
    case 'preview'
        % The user wants to see a preview of a material.  Not all
        % materials have a preview.

        materialPath = piDirGet('materials');

        % piMaterialPresets('preview','glass-F11');
        if exist('materialName','var') && ~isempty(materialName)
            [~,n,e] = fileparts(materialName);
            if isempty(e), materialName = [n,'.jpg']; end
            fname = fullfile(materialPath,'previews',materialName);
            if exist(fullfile(materialPath,'previews',materialName), 'file')
                ieNewGraphWin; im = imread(fname); image(im);
            else
                warning('Could not find %s. Here are the files',materialName);
                dir(fullfile(materialPath,'previews'))
            end
        else
            dir(fullfile(materialPath,'previews'))
        end
        return;

        % The user wants a list of all the materials.
    case {'list','listall','listmaterial','listmaterials'}
        % Print out a list of the materials. Also, return a cell array of
        % all the preset materials. The printed number is the index into
        % that material in the returned cell array.
        types = {'diffuse list','glossy list','glass list','metal list','car list','marble list','testpatterns list','wood list'};
        cnt =  0;
        for tt = 1:numel(types)
            newList = piMaterialPresets(types{tt});
            fprintf('\n--- Preset materials in %s ---\n',types{tt});
            for ii = 1:numel(newList)
                cnt = cnt + 1;
                fprintf('%d: %s \n',cnt, newList{ii});
            end

            if tt == 1,  presetList = newList;
            else,        presetList = cellMerge(presetList,newList);
            end
        end

        fprintf('\n');
        newMat = presetList;

        if options.show
            % Now show it in a dialog box that can stay up in a screen window
            % mats = piMaterialPresets('list');
            h = helpdlg(presetList);

            % I can change the font size, but the window clips the text.  So we
            % would need to change the window size, too.  Maybe another time.
            str = findall(h,'Type','Text');
            str.FontSize = 10;
        end

        % ------------ DIFFUSE
    case 'diffuselist'
        newMat = {'diffuse-gray','diffuse-red','diffuse-white'};
    case 'diffuse-gray'
        newMat.material = piMaterialCreate(materialName, 'type', 'diffuse');
        newMat.material = piMaterialSet(newMat.material,'reflectance',[0.2 0.2 0.2]);
    case 'diffuse-red'
        newMat.material = piMaterialCreate(materialName, 'type', 'diffuse');
        newMat.material = piMaterialSet(newMat.material,'reflectance',[1 0.3 0.3]);
    case 'diffuse-white'
        newMat.material = piMaterialCreate(materialName, 'type', 'diffuse');
        newMat.material = piMaterialSet(newMat.material,'reflectance',[1 1 1]);

        % ------------ GLASS
    case 'glasslist'
        % 'red-glass' doesn't work yet
        newMat = {'glass','glass-bk7','glass-baf10','glass-fk51a','glass-lasf9','glass-f5','glass-f10','glass-f11'}';
        return;

    case 'glass'
        newMat.material = piMaterialCreate(materialName,'type',...
            'dielectric','roughness',0);

    case 'red-glass-broken' % mixed materials don't currently seem to work

        % Not sure about what to do with mixed materials.  Must ask
        % Zhenyi.
        newMat_glass = piMaterialCreate([materialName, '_mix_glass'], ...
            'type', 'dielectric','eta','glass-BK7');
        newMat_reflectance = piMaterialCreate([materialName, '_mix_reflectance'], ...
            'type', 'coateddiffuse',...
            'reflectance', [ 0.99 0.01 0.01 ], ...
            'roughness',0);
        mixMatString{1} = [materialName, '_mix_glass'];
        mixMatString{2} = [materialName, '_mix_reflectance'];
        newMat.material = piMaterialCreate(materialName,...
            'type','mix',...
            'amount',0.2,...
            'materials',mixMatString);

        % Not sure about this (BW).
        newMat.mixMat{1} = newMat_glass;
        newMat.mixMat{2} = newMat_reflectance;

    case 'glass-bk7'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-BK7');

    case 'glass-baf10'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-BAF10');

    case 'glass-fk51a'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-FK51A');

    case 'glass-lasf9'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-LASF9');

    case 'glass-f5'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-F5');

    case 'glass-f10'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-F10');

    case 'glass-f11'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-F11');

        % ----------- METALS
    case 'metallist'
        newMat = {'mirror','metal-ag','chrome','rough-metal','metal-au','metal-cu','metal-cuzn','metal-mgo','metal-tio2'};

    case {'metal-ag','mirror'}
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Ag-eta','k','metal-Ag-k');

    case {'metal-al','rim', 'chrome'}
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Al-eta','k','metal-Al-k');

    case 'metal-au'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Au-eta','k','metal-Au-k');

    case 'metal-cu'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Cu-eta','k','metal-Cu-k');
    case 'metal-cuzn'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-CuZn-eta','k','metal-CuZn-k');
    case 'metal-mgo'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-MgO-eta','k','metal-MgO-k');
    case 'metal-tio2'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-TiO2-eta','k','metal-TiO2-k');
    case 'rough-metal'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Al-eta','k','metal-Al-k');

        % ----------------  Glossy materials
    case 'glossylist'
        newMat = {'glossy-black','glossy-gray','glossy-red','glossy-white'};

    case 'glossy-black'    % barcelona-pavilion scene
        newMat.material = piMaterialCreate(materialName, 'type', 'coateddiffuse');
        newMat.material = piMaterialSet(newMat.material,'reflectance',[0.02 0.02 0.02]);
        newMat.material = piMaterialSet(newMat.material,'roughness',0.0104);

    case 'glossy-gray'
        newMat.material = piMaterialCreate(materialName, 'type', 'coateddiffuse');
        newMat.material = piMaterialSet(newMat.material,'reflectance',[0.2 0.2 0.2]);

    case 'glossy-red'
        newMat.material = piMaterialCreate(materialName, 'type', 'coateddiffuse');
        newMat.material = piMaterialSet(newMat.material,'reflectance',[1 0.3 0.3]);

    case 'glossy-white'
        newMat.material = piMaterialCreate(materialName, 'type', 'coateddiffuse');
        newMat.material = piMaterialSet(newMat.material,'reflectance',[1 1 1]);

        % -------- Advanced polligon materials
        % These materials are from the polligon website
        % https://www.poliigon.com/textures/free
    case 'metal-spotty-discoloration'
        newMat = polligon_materialCreate(materialName,...
            'MetalSpottyDiscoloration001_COL_3K_METALNESS.png','coatedconductor');

        % -------- Car materials
    case 'carlist'
        newMat = {'tire','asphalt-uniform'};
    case 'tire'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'coateddiffuse','reflectance',[ 0.06394 0.06235 0.06235 ],'roughness',0.1);
    case 'asphalt-uniform'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/asphalt-001.png');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);
    case 'asphalt-crack'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/asphalt-002.png');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

        % --------       Woods
        %{wood-medium-knots','wood-light-large-grain','wood-mahogany'}
    case 'woodlist'
        newMat = {'wood-medium-knots','wood-light-large-grain','wood-mahogany'};

        %     case 'wood-floor-merbau'
        %         newMat = polligon_materialCreate(materialName,...
        %             'WoodFlooringMerbauBrickBondNatural001_COL_3K.png','coateddiffuse');

    case 'wood-medium-knots'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/woodgrain001.png');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

    case 'wood-light-large-grain'        % Wood grain (light, large grain)
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/woodgrain002.exr');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

    case 'wood-mahogany'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/mahoganyDark.exr');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

        % ---------  Marble
    case 'marblelist'
        newMat = {'marble-beige'};

    case 'marble-beige'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/marbleBeige.exr');
        newMat.material = piMaterialCreate(materialName,'type','coateddiffuse','reflectance val',materialName);

        % Stored, but too much hassle to make work with jpg instead of
        % png and all the different components.
        %     case 'marble-tiles-sagegreen-brick'
        %         newMat = polligon_materialCreate(materialName,...
        %             'TilesMarbleSageGreenBrickBondHoned001_COL_2K.png','coatedconductor');

        % ---------  Bricks
    case 'bricklist'
        newMat = {'brickwall001','brickwall002','brickwall003'};

    case 'brickwall001'
        % We need better names
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/brickwall001.png');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

    case 'brickwall002'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/brickwall002.png');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

    case 'brickwall003'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/brickwall003.png');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

        % ---------  Fabrics
    case 'fabriclist'
        newMat = {'fabric-leather-var1','fabric-leather-var2','fabric-leather-var3'};
    case 'fabric-leather-var1'
        newMat = polligon_materialCreate(materialName,...
            'FabricLeatherBuffaloRustic001_COL_VAR1_3K.png','coateddiffuse');

    case 'fabric-leather-var2'
        newMat = polligon_materialCreate(materialName,...
            'FabricLeatherBuffaloRustic001_COL_VAR2_3K.png','coateddiffuse');

    case 'fabric-leather-var3'
        newMat = polligon_materialCreate(materialName,...
            'FabricLeatherBuffaloRustic001_COL_VAR3_3K.png','coateddiffuse');

        % ------------- Test patterns
    case {'testpatternslist'}
        newMat = {'checkerboard','ringsrays','macbethchart','slantededge','dots'};

    case 'checkerboard'
        newMat.texture = piTextureCreate(materialName,...
            'type', 'checkerboard',...
            'format', 'spectrum',...
            'uscale', 2,...
            'vscale', 2, ...
            'spectrum tex1', [.05 .05 .05],...
            'spectrum tex2', [.95 .95 .95]);

        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

        % Rings and Rays (Siemens star)
    case 'ringsrays'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/ringsrays.png');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

        % Macbeth chart
    case 'macbethchart'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/macbeth.png');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

        % Slanted edge
    case 'slantededge'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'textures/slantedbar.png');
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

        % Colored dots
    case 'dots'
        newMat.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'dots',...
            'uscale', 8,...
            'vscale', 8, ...
            'inside', [.1 .5 .9], ...
            'outside', [.9 .5 .1]);
        newMat.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

    otherwise
        warning('No material preset found for %s',keyword);
        piMaterialPresets('list material');
end

end




