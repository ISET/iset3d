%% Generate a lookuptable for use with HumenEye in PBRTv4
% In the newest version  of Human Eye in PBRT v4 (TG), we have the ability to give PBRT an arbitrary
% lookuptable to represent positions on the surface.
% This is supposed to reproduce the results from the legacy code that maps
% a position on the film to a position on a spherical surface
%
% Thomas Goossens 2022
clear;

%% Define Bump (gaussian
center=[0 0];sigma=0.5;
bump1=@(x,y) 0.5*exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2));
center=[2 0];sigma=0.2;
bump2=@(x,y) 0.4*exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2));
center=[-1.9 -2];sigma=0.3;
bump3=@(x,y) 0.5*exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2));

bump=@(x,y) bump1(x,y) + bump2(x,y)+ bump3(x,y);


%% Define Retina 
retinaDistance =16.320000;%mm  (This will be the lowest Z value of the surface)
retinaRadius= 12.000000; %mm
retinaSemiDiam = 3.942150; %mm
retinaDiag = retinaSemiDiam*1.4142*2; % sqrt(2)*2


%% Define film
filmDiagonal = 10; % mm 
rowresolution = 256; % number of pixels
colresolution = 256; % number of pixels
rowcols = [rowresolution colresolution];

% Pixels are square by construction
pixelsize = filmDiagonal/sqrt(rowresolution^2+colresolution^2)

% Total size of the film in mm
row_physicalwidth= pixelsize*rowresolution;
col_physicalwidth= pixelsize*colresolution;


%% Sample positions for the lookup table

lookuptable = struct;
lookuptable.rowcols = rowcols;

count = 1;
for r=1:rowcols(1)
    for c=1:rowcols(2)
     

        % Define the film index (r,c) in the 2d lookuptable
        pFilm = struct;       
        pFilm.x=r; 
        pFilm.y=c;    


        % Map Point to sphere using the legacy realisticEye code
        filmRes= struct;        filmRes.x=rowcols(1);        filmRes.y=rowcols(2);
        point = mapToSphere(pFilm,filmRes,retinaDiag,retinaSemiDiam,retinaRadius,retinaDistance);



        % PBRT expects meters for lookuptable not milimeters
        mm2meter=1e-3;
        pointPlusBump_meter = [point.x point.y point.z+bump(point.x,point.y)]*mm2meter;
        

        % Construct map
        map = struct;
        map.rowcol = [r c]-[1 1]; % Array index (start counting at zero)
        map.point =  pointPlusBump_meter;  % Target point

        % Add map to lookup table
        lookuptable.table(count) =map; 
        
        % Keep data for plotting the surface later
        Zref_mm(r,c)=point.z;
        Zbump_mm(r,c)=pointPlusBump_meter(3)/mm2meter;


        count=count+1;
    end
end


%% Plot surface
Zref_mm(Zref_mm>0)=nan;
Zbump_mm(Zbump_mm>-13)=nan;
fig=figure(5);clf
fig.Position = [700 487 560 145];
fig.Position=[700 487 560 145];
subplot(121)
s=surf(Zbump_mm);
s.EdgeColor = 'none';
zlim([-retinaDistance -15])
subplot(122)
imagesc(Zbump_mm,[-retinaDistance -15]);




%% Generate Loouptable JSON 

jsonwrite('lookuptable-bump.json',lookuptable);


