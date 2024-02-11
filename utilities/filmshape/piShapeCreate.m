%% Generate a lookuptable for use with HumenEye in PBRTv4
% In the newest version  of Human Eye in PBRT v4 (TG), we have the ability to give PBRT an arbitrary
% lookuptable to represent positions on the surface.
% This is supposed to reproduce the results from the legacy code that maps
% a position on the film to a position on a spherical surface
%
% Thomas Goossens 2022
clear;

%% Define Retina 
retinaDistance =16.320000;%mm  (This will be the lowest Z value of the surface)
retinaRadius= 12.000000; %mm
retinaSemiDiam = 3.942150; %mm
retinaDiag = retinaSemiDiam*1.4142*2; % sqrt(2)*2


%% Define film
filmDiagonal = 10; % mm 
rowresolution = 256;
colresolution = 256;
rowcols = [rowresolution colresolution];

% Pixels are square by construction
pixelsize = filmDiagonal/sqrt(rowresolution^2+colresolution^2)

% Total size of the film in mm
row_physicalwidth= pixelsize*rowresolution;
col_physicalwidth= pixelsize*colresolution;


%% Sample positions for the lookup table

lookuptable = struct;
lookuptable.rowcols = rowcols;

index = 1;
for r=1:rowcols(1)
    for c=1:rowcols(2)
     

        % Define the film index (r,c) in the 2d lookuptable
        pFilm = struct;       
        pFilm.x=r; 
        pFilm.y=c;    


        % Map Point to sphere using the legacy realisticEye code
        filmRes= struct;        filmRes.x=rowcols(1);        filmRes.y=rowcols(2);
        point = mapToSphere(pFilm,filmRes,retinaDiag,retinaSemiDiam,retinaRadius,retinaDistance);
        
        if(point.x==12 && point.z > -13)
            a=1;
            disp(point)
        end
        % PBRT expects meters for lookuptable not milimeters
        mm2meter=1e-3;
        points_meter(index,:) = [point.x point.y point.z]*mm2meter;
        
    
        
        % Keep data for plotting the surface later
        Z(r,c)=point.z;


        index=index+1;
    end
end


%% Plote surface
figure;
surf(Z);
zlim([-retinaDistance -15.6])

%% Generate Loouptable JSON 
lookuptable = pointsToLookuptable(points_meter);
jsonwrite('lookuptable-sphere-vectorized.json',lookuptable);