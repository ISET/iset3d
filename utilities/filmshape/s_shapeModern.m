% s_shapeModern
%
% In the newest version  of Human Eye in PBRT v4 (TG), we have the
% ability to give PBRT an arbitrary lookup table to represent
% positions on the surface. This is supposed to reproduce the results
% from the legacy code that maps a position on the film to a position
% on a spherical surface.
%
% This script illustrates how we made a bumpy retina and rendered
% using the sceneEye with that.  Various quality of life things left
% to do, but it ran through the first visualization.
%
% See also
%  s_shapeExample

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the default retinal parameters from this SE (sceneEye)
%
% The code from TG doesn't work well for all semi diameters.  Not sure why,
% but when it is 6 mm rather than 4 mm the shape looks odd.

SE = sceneEye;
SE.set('film resolution',[256 256]);
SE.set('retina semidiam',3.942150,'mm');  

%% Define Bump (gaussian)

% These will be superimposed on the default shape.

% Bump height and width?
height = 400*1e-3; % 0.4 mm
% width  = 400*1e-3; % 0.4 mm

maxnorm=@(x)x;

center = [0 0]; sigma  = 0.9;
bump1=@(x,y) 2*height*maxnorm(exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2)));

center=[2 0];sigma=0.9;
bump2=@(x,y) 2*height*maxnorm(exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2)));

center=[-1.9 -2];sigma=0.9;
bump3=@(x,y) 2*height*maxnorm(exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2)));

bump=@(x,y) (bump1(x,y) + bump2(x,y)+ bump3(x,y));


%% Define Retina

% This will be the lowest Z value of the retina.  It is negative.
retinaDistance = SE.get('retina distance','mm');  
retinaRadius   = SE.get('retina radius','mm');   
retinaSemiDiam = SE.get('retina semidiam','mm');

retinaDiag = retinaSemiDiam*1.4142*2; % sqrt(2)*2

%% Define film properties using sceneEye methods

filmDiagonal  = SE.get('film diagonal','mm'); % mm
rowcols       = SE.get('film resolution');
rowresolution = rowcols(1); % number of pixels
colresolution = rowcols(2); % number of pixels

% Pixels are square by construction
% pixelsize = filmDiagonal/sqrt(rowresolution^2 + colresolution^2);

% Total size of the film in mm
filmHeight = SE.get('film height','m');
filmWidth  = SE.get('film width','m');

%% Sample positions for the lookup table

index = 1;
% Zref_mm  = zeros(rowcols);
% Zbump_mm = zeros(rowcols);
filmXYZ_m = zeros(prod(rowcols),3);

x = linspace(-filmWidth/2,filmWidth/2,rowcols(2));
y = linspace(-filmHeight/2,filmHeight/2,rowcols(1));

% shapeType = 'flatnoisy';
shapeType = 'gaussian bump';
switch ieParamFormat(shapeType)
    case 'flatnoisy'
        % We need a better way to sample so we can render the OI later.
        sigma = 0.01;  % SD of retinal flatness in Millimeters
        for r=1:rowcols(1)
            for c=1:rowcols(2)
                z = (-16.32 + randn(1,1)*sigma)*1e-3;
                filmXYZ_m(index,:) = [x(c) y(r) z];
                index=index+1;
            end
        end
    case 'gaussianbump'
        % center = [-filmWidth/4,filmWidth/4]; 
        center = [0,0];
        sigma = filmWidth/12; height_mm = 0.3;
        [X,Y] = meshgrid(x,y);
        bump =  retinalBump(X,Y,center,sigma);
        
        % bump = fspecial('gaussian',rowcols,10);
        % bump = ieScale(bump,0,height_mm);
        for r=1:rowcols(1)
            for c=1:rowcols(2)
                z = (-16.32 + bump(r,c))*1e-3;
                filmXYZ_m(index,:) = [x(c) y(r) z];
                index=index+1;
            end
        end
    otherwise
end


%% Show the film surface graph

ieNewGraphWin;
filmSurface = XW2RGBFormat(filmXYZ_m,rowcols(1),rowcols(2));
mesh(filmSurface(:,:,1),filmSurface(:,:,2),filmSurface(:,:,3));
% set(gca,'zlim',[-16.5 -16]*1e-3)

%{
mesh(filmSurface(:,:,3));
set(gca,'zlim',[-16.5 -16]*1e-3)
%}

%% From utilities/filmshape

thisSE = sceneEye('letters at depth','eye model','arizona');
% thisSE = sceneEye('slanted edge','eye model','arizona');

thisSE.set('retina semidiam',SE.get('retina semidiam'));

fname = fullfile(piRootPath,'local','deleteMe.json');
piShapeWrite(fname, filmXYZ_m);

thisSE.set('film shape file',fname);
% thisSE.get('film shape file')

% Read the film shape.  The film shape (fs) has a slot for a table.  The
% table has a set of indices and corresponding points.  The points are 3D
% values for a film position.  The indices start at 0 and are used by PBRT
% code to index the positions.
fs = jsonread(fname);

% We render with one long list of positions.  We set the film resolution to
% have one point for each resolution.
% Resolution is (x,y), not row, col
thisSE.set('film resolution',[fs.numberofpoints 1]);

% The samplers have some issues with TG's code, and sobol seems the least
% problematic.
thisSE.set('sampler subtype','sobol');
thisSE.set('rays per pixel',64);

% Render with the humanEye camera model.
thisD = dockerWrapper.humanEyeDocker;
% oi = thisSE.render('docker wrapper',thisD);

% We cannot view yet, because the data are in the format of a long line.
oi = thisSE.piWRS('docker wrapper',thisD,'show',false);

%%  Show the oi

p = XW2RGBFormat(squeeze(oi.data.photons),rowcols(1),rowcols(2));
p = imageRotate(p,'cw');

% tmp = sum(p,3);
% ieNewGraphWin;
% imagesc(tmp); axis image; colormap(gray);
oi = oiSet(oi,'photons',p);
% oi = piAIdenoise(oi);
oiWindow(oi);

% p = reshape(oi.data.photons,256,256,31);

%%

% If a general case, we have (x,y,z) in the JSON file and
% corresponding radiance and illuminance ... 
illuminance = oiGet(oi,'illuminance');

X = filmSurface(:,:,1);
Y = filmSurface(:,:,2);
Z = filmSurface(:,:,3);

ieNewGraphWin;
s = mesh(X,Y,Z,illuminance);
hold on;
s.FaceLighting = 'gouraud';
colormap(gray);

% Try to find the mesh method in s_retinalShapes
%
%%

% Each point in the rendered oi corresponds to a position specified by
% the lookup table.
%
% The film shape table specifies the point and its index
%
pixelvalue = zeros(fs.numberofpoints,1);
position = zeros(fs.numberofpoints,3);
for t=1:fs.numberofpoints
    pixelvalue(t) = illuminance(fs.table(t).index+1); 
    
    % Record position
    position(t,1:3) = fs.table(t).point;
end

% Vector length of each row
distances = vecnorm(position,2,2);
ieNewGraphWin; histogram(distances,50);

% We are picking Xq/Yq values that are out of the measurement range.  We
% need to select the original points c
mnmx(1,:) = min(position);
mnmx(2,:) = max(position);

xq = linspace(mnmx(1,1),mnmx(2,1),256);
yq = linspace(mnmx(1,2),mnmx(2,2),256);
[Xq,Yq] = meshgrid(xq,yq);
pQ = [Xq(:),Yq(:)];

distancesQ = vecnorm([Xq(:),Yq(:)],2,2);
histogram(distancesQ,50);
ieNewGraphWin; histogram(distancesQ,50);

Vq = griddata(position(:,1),position(:,2),pixelvalue(:),fliplr(Xq),Yq);
Zq = griddata(position(:,1),position(:,2),position(:,3),fliplr(Xq),Yq);

size(Vq)
ieNewGraphWin; imagesc(Vq);

%%
mesh(Xq,Yq,Zq);

%% griddatan version

VVq = griddatan(position,pixelvalue(:),Xq,Yq,Zq);

%%

ieNewGraphWin;
scatter3(position(:,1),position(:,2),position(:,3), 40, pixelvalue(:), 'filled')

mm2meter=1e-3;
zlim([-16.4 -15]*mm2meter);
xlim([-5 5]*mm2meter);
ylim([-5 5]*mm2meter);
colormap gray
view(-162,86)

%% Rendering on a 3D mesh
checks = imread('hatsC.jpg');
checks = imresize(checks,size(X));

ieNewGraphWin;
s = mesh(X,Y,Z,checks); hold on;
s.FaceColor = 'flat';
hold on; plot3(X(:),Y(:),Z(:),'k.'); set(gca,'zlim',[-20 bumpSize]); 

%%
% If a grid, this would work
p = sceneGet(oi,'photons');
p = reshape(p,50,50,31);
oi = oiSet(oi,'photons',p);
oiWindow(oi);  

% If not a grid, you could still interpolate from position and
% pixelvalue to fill up an approximate photon data set

%% END

%{
        % Define the film index (r,c) in the 2d lookuptable
        pFilm = struct;
        pFilm.x = r;
        pFilm.y = c;

        % Map Point to sphere using the legacy realisticEye code
        filmRes   = struct;        
        filmRes.x = rowcols(1);        
        filmRes.y = rowcols(2);

        % This is the original retinal sphere shape method
        point = mapToSphere(pFilm,filmRes,retinaDiag,retinaSemiDiam,retinaRadius,retinaDistance);


        % PBRT expects meters for lookuptable not milimeters.
        % The retina is typically around -16.2 mm from the lens, which is
        % at 0 mm.  A bump towards the lens will be, say, -15.5 mm 
        mm2meter = 1e-3;
        pointPlusBump_meter(index,:) = [point.x point.y point.z + bump(point.x,point.y)]*mm2meter;

        % Keep data for plotting the surface later.  This is the sphere
        Zref_mm(r,c)  = point.z;

        % This is the sphere with the added bump
        Zbump_mm(r,c) = pointPlusBump_meter(index,3)/mm2meter;

        index=index+1;
        %}
%% Plot surface
%{
Zref_mm(Zref_mm>0)     = NaN;
Zbump_mm(Zbump_mm>-13) = NaN;

ieNewGraphWin; 

subplot(121); 
s=surf(Zbump_mm);

s.EdgeColor = 'none';
zlim([-retinaDistance -15])
subplot(122);
imagesc(Zbump_mm,[-retinaDistance -15]);
axis image; colorbar;

%}

