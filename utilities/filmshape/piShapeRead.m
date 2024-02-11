%% Read human eye EXR image, generated with lookuptable, and visualize the image
% on the surface
clear;


%%  Read EXR
%Iradiance =  piEXR2Mat('/home/thomas/Documents/stanford/libraries/pbrt-v4/scenes/lettersAtDepth/lettersAtDepth/pbrt-bump-256x256vector.exr','Radiance');
%Iradiance =  piEXR2Mat('/home/thomas/Documents/stanford/libraries/pbrt-v4/scenes/lettersAtDepth/lettersAtDepth/pbrt-bump-vector-40rays-100diag.exr','Radiance');
Iradiance =  piEXR2Mat('/home/thomas/Documents/stanford/libraries/pbrt-v4/scenes/lettersAtDepth/lettersAtDepth/pbrt-256x256-sobol-2000rays.exr','Radiance');
Iradiance =  piEXR2Mat('/home/thomas/Documents/stanford/libraries/pbrt-v4/scenes/lettersAtDepth/lettersAtDepth/legacy.exr','Radiance');
lookuptable= jsonread('/home/thomas/Documents/stanford/libraries/pbrt-v4/scenes/lettersAtDepth/lettersAtDepth/lookuptables/lookuptable-bump-vectorized-256x256.json');

%Iradiance =  piEXR2Mat('/home/thomas/Documents/stanford/libraries/pbrt-v4/scenes/lettersAtDepth/lettersAtDepth/pbrt-sphere.exr','Radiance');
%lookuptable = jsonread('/home/thomas/Documents/stanford/libraries/pbrt-v4/scenes/lettersAtDepth/lettersAtDepth/lookuptables/lookuptable-sphere-vectorized.json');

Ivec=sum(Iradiance(:,:,:),3);
sz = sqrt(numel(Ivec));
I = reshape(Ivec,[sz sz]);
% Plot image as is (row colums)
figure;
imagesc(I);
colormap gray
%% Read Lookuptable used for producing this image


for t=1:lookuptable.numberofpoints
    table=lookuptable.table(t);


    % Read pixel value from Image
    pixelvalue(t,:) = Ivec(lookuptable.table(t).index+1); 
    
    % Record position
    position(t,:)=table.point;
end


%% Plot image on 3D surface
figure;
scatter3(position(:,1),position(:,2),position(:,3), 40, pixelvalue(:), 'filled')
mm2meter=1e-3;
zlim([-16.4 -15]*mm2meter);
xlim([-5 5]*mm2meter);
ylim([-5 5]*mm2meter);
colormap gray
view(-162,86)

%% 
figure;
mesh(position(:,1),position(:,2),position(:,3), 'filled')

