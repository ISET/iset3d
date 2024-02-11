% s_shapeExample
%
% TO BE DEPRECATED USING s_shapeModern examples.
%
% In the newest version  of Human Eye in PBRT v4 (TG), we have the
% ability to give PBRT an arbitrary lookuptable to represent positions
% on the surface. This is supposed to reproduce the results from the
% legacy code that maps a position on the film to a position on a
% spherical surface.
%
% This script illustrates how we made a bumpy retina and then rendered
% a scene using sceneEye.  Various quality of life things left to do,
% but it ran through the first visualization.
%
% See also
%  s_shapeModern

%% Initialize
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Define the Bump method (gaussian)

center = [0 0];
sigma  = 0.9;
height = 400*1e-3; % 0.4 mm
width  = 400*1e-3; % 0.4 mm

maxnorm=@(x)x;
bump1=@(x,y) 2*height*maxnorm(exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2)));
center=[2 0];sigma=0.9;
bump2=@(x,y) 2*height*maxnorm(exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2)));
center=[-1.9 -2];sigma=0.9;
bump3=@(x,y) 2*height*maxnorm(exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2)));

bump=@(x,y) (bump1(x,y) + bump2(x,y)+ bump3(x,y));


%% Define the basic retinal surface

retinaDistance = 16.320000; %mm  (This will be the lowest Z value of the surface)
retinaRadius   = 12.000000; %mm
retinaSemiDiam = 3.942150;  %mm

retinaDiag = retinaSemiDiam*1.4142*2; % sqrt(2)*2

%% Define rendering parameters

filmDiagonal  = 10; % mm
rowresolution = 256; % number of pixels
colresolution = 256; % number of pixels
rowcols = [rowresolution colresolution];

% Pixels are square by construction
pixelsize = filmDiagonal/sqrt(rowresolution^2+colresolution^2);

% Total size of the film in mm
row_physicalwidth= pixelsize*rowresolution;
col_physicalwidth= pixelsize*colresolution;

%% Sample positions for the lookup table

index = 1;
Zref_mm  = zeros(rowcols);
Zbump_mm = zeros(rowcols);
pointPlusBump_meter = zeros(prod(rowcols),3);

% We need a better way to sample so we can render the OI later.
for r=1:rowcols(1)
    for c=1:rowcols(2)

        % Define the film index (r,c) in the 2d lookuptable
        pFilm = struct;
        pFilm.x = r;
        pFilm.y = c;

        % Map Point to sphere using the legacy realisticEye code
        filmRes   = struct;        
        filmRes.x = rowcols(1);        
        filmRes.y = rowcols(2);

        % The Mara code ran on a sphere and used a spherical region.
        % We are going to shift to a square (x,y) grid to make it
        % easier to visualize in the oiWindow, later.
        point = mapToSphere(pFilm,filmRes,retinaDiag,retinaSemiDiam,retinaRadius,retinaDistance);
        %[point.x,point.y] = meshgrid(1:rowcols(1),1:rowcols(2));
        %point.z = (retinaDistance + bump(point.x,point.y))*-1*mm2meter;
        % mesh(point.x,point.y,point.z);

        % PBRT expects meters for lookuptable not milimeters.
        % The retina is typically around -16.2 mm from the lens, which is
        % at 0 mm.  A bump towards the lens will be, say, -15.5 mm 
        mm2meter = 1e-3;
        pointPlusBump_meter(index,:) = [point.x point.y point.z + bump(point.x,point.y)]*mm2meter;

        % Keep data for plotting the surface later
        Zref_mm(r,c)  = point.z;
        Zbump_mm(r,c) = pointPlusBump_meter(index,3)/mm2meter;

        index=index+1;
    end
end


%% Plot surface

Zref_mm(Zref_mm>0)     = NaN;
Zbump_mm(Zbump_mm>-13) = NaN;

fig = ieNewGraphWin; 
subplot(121); 
s=surf(Zbump_mm);

s.EdgeColor = 'none';
zlim([-retinaDistance -15])
subplot(122);
imagesc(Zbump_mm,[-retinaDistance -15]);
axis image; colorbar;

%% Set up the sceneEye and bumpy film (retinal) surfaces

thisSE = sceneEye('letters at depth','eye model','arizona');

fname = fullfile(piRootPath,'local','deleteMe.json');
piShapeWrite(fname, pointPlusBump_meter);

thisSE.set('film shape file',fname);
% thisSE.get('film shape file')

% Read the film shape.  The film shape (fs) has a slot for a table.  The
% table has a set of indices and corresponding points.  The points are 3D
% values for a film position.  The indices start at 0 and are used by PBRT
% code to index the positions.
fs = jsonread(fname);

% We render with a long list of positions.  We set the film resolution to
% have one point for each resolution.
% Resolution is (x,y), not row, col
thisSE.set('film resolution',[fs.numberofpoints 1]);

% The samplers have some issues with TG's code; sobol seems the least
% problematic.
thisSE.set('sampler subtype','sobol');
thisSE.set('rays per pixel',64);

% Render with the humanEye camera model.
thisD = dockerWrapper.humanEyeDocker;
% oi = thisSE.render('docker wrapper',thisD);

% The data are returned in the format of a long vector, not an image.
oi = thisSE.piWRS('docker wrapper',thisD,'show',false);

%%  Deal with reformatting the OI vector so we can visualize

% Each returned point is measured at an (x,y,z) position in the fs
% JSON file. This is the illuminance from those points.
illuminance = oiGet(oi,'illuminance');

% Each point in the rendered oi corresponds to a position specified by
% the lookup table.
%
% The film shape table specifies the point and its index
%
pixelvalue = zeros(fs.numberofpoints,1);
position   = zeros(fs.numberofpoints,3);
for t=1:fs.numberofpoints
    pixelvalue(t) = illuminance(fs.table(t).index+1); 
    
    % (x,y,z) position
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




