%% Generate a lookuptable for use with HumenEye in PBRTv4
%
% In the newest version  of Human Eye in PBRT v4 (TG), we have the
% ability to give PBRT an arbitrary lookuptable to represent positions
% on the surface. This is supposed to reproduce the results from the
% legacy code that maps a position on the film to a position on a
% spherical surface
%
% The Z-values are negative because this side of the lens is negative
% and the object side is positive.
%
%  The distance between the zero point on the z-axis (i.e. the lens element
%  closest to the sensor) and the dotted line will be equal to the
%  "retinaDistance." The retina curvature is defined by the "retinaRadius" and
%  it's height in the y and x direction is defined by the "retinaSemiDiam."
%
%
%                                         :
%                                         |  :
%                                         | :
%                             | | |         |:
%             scene <------ | | | <----   |:
%                             | | |         |:
%                         Lens System      | :
%                                         |  :
%                                         :
%                                     retina
%             <---- +z
%
%
% Thomas Goossens 2022
%

%% Define Retina 

% This will be the lowest Z value of the surface)
retinaDistance = 16.320000;%mm  
retinaRadius   = 12.000000; %mm
retinaSemiDiam = 3.942150;  %mm
retinaDiag     = retinaSemiDiam*sqrt(2)*2;

%% Define film
filmDiagonal  = 10; % mm 
rowresolution = 256;
colresolution = 256;
rowcols = [rowresolution colresolution];

% Pixels are square by construction
pixelsize = filmDiagonal/sqrt(rowresolution^2+colresolution^2);

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

        % Construct map
        map = struct;
        map.rowcol = [r c]-[1 1]; % Array index (start counting at zero)
        map.point = [point.x point.y point.z]*1e-3;  % Target point


        % Add map to lookup table
        lookuptable.table(count) =map; 

        % Keep data for plotting the surface later
        Z(r,c)=point.z;


        count=count+1;
    end
end


%% Plote surface
figure;
surf(Z);
zlim([-retinaDistance -15.6])

%% Generate Loouptable JSON 

% jsonwrite('lookuptable-sphere.json',lookuptable);

