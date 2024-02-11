function [MTF,LSF,ESF] = piCalculateMTF(varargin)
% Calculate The MTF, LSF and, ESF
% A vertical step function (black/white edge) is placed at a given
% distance, this requires the 'stepfunction' scene. 
% The scene is simulated for one horizontal line to allow for high
% resolution. This gives the edge spread function (ESF) from which the
% linespread (LSF) is calculated using differentation. The MTF is then
% obtained as the Fourier Transform of the Linespread function.
%
% RERUIRED INPUTS
%  camera - Camera (omni or RTF)
%  filmwidth - filmwidth (mm)  
%
% OPTIONAL INPUTS
%  rays - Number of rays
%  resolution - Number of pixels on a horizontal line
%  distances - Array of chart distances to the step function measured from
%              the film
%
% OUTPUT
% The output parameters are structs
%
% ESF = matrix , each column corresponding to a chart distance
% ESF.pixelsMicron;
%
% LSF.LSF: matrix , each column corresponding to a chart distance
% LSF.pixelsMicron = pixelsLSF;%
%
% MTF =struct;
% MTF.cyclespermillimeter=cyclespermillimeter;
% MTF.MTF: matrix , each column corresponding to a chart distance
%    
% Thomas Goossens

varargin = ieParamFormat(varargin);
p = inputParser;

%  required
p.addParameter('camera',@isstruct);
p.addParameter('filmwidth', @isnumeric);

% optional
p.addParameter('rays',2000, @isnumeric);
p.addParameter('resolution',1000,@isnumeric);
p.addParameter('quiet',false,@islogical);

p.addParameter('distances',[1000],@isnumeric); % Array with chart distances measured from the film position
p.parse(varargin{:});

camera= p.Results.camera; 
filmwidth_mm = p.Results.filmwidth;

distancesFromFilm_mm = p.Results.distances; % passed in as mm
nbRaysPerPixel = p.Results.rays;
resolution = p.Results.resolution;


%%  Setup distances from film
% Positions of chart as measured from the film
distancesFromFilm_meter = 1e-3* (distancesFromFilm_mm);

%% Create A camera for each polynomial degree
cameras={camera};


%% Loop over different chart distances, as measured from film
for c=1:numel(cameras)
    for i=1:numel(distancesFromFilm_meter)
        if ~p.Results.quiet
            disp(['Render Camera ' num2str(c) ' position ' num2str(i)]);
        end
        % Build the scene
        thisR=piRecipeDefault('scene name','stepfunction');
        
        % Control Distance to Step Funtion Chart
        setChartDistance(thisR,distancesFromFilm_meter(i));
        
        
        % Set Camera Properaties
        thisR.set('camera',cameras{c});
        thisR.set('spatial resolution',[resolution 1]); % Only one line
        thisR.set('rays per pixel',nbRaysPerPixel);
        thisR.set('film diagonal',filmwidth_mm); % Original
        
        
        % Write and render
        piWrite(thisR);
        oiESF{i} = piRender(thisR,'render type','radiance'); %,'dockerimagename','vistalab/pbrt-v3-spectral:latest');
        oiESF{i}.name=['Chart distance from film: ' num2str(distancesFromFilm_meter(i))];
        %oiWindow(oiESF)
        
    end
    
end



%% Generate ESF matrix
clear esf
filmWidth = oiGet(oiESF{1},'width','mm');
pixels_micron = 1e3*linspace(-filmWidth/2,filmWidth/2,oiGet(oiESF{1},'cols'));

% define a smoothing function to help filter out noise
smoothingFactor = 5; % originally 5 in Thomas's paper
smooth = @(x)conv(x,[1 1 1 1 1]/smoothingFactor, 'same');

for i = 1:numel(distancesFromFilm_meter)
    edgePBRT = oiESF{i}.data.photons(end,:,1); % Take horizontal line in center
    % apply our smoothing function
    esf(:,i) = edgePBRT/max(smooth(edgePBRT)); %#ok<AGROW> 
end



%% Calculate MTF using FFT

% STEP 1 : Calculate Linespread (LSF) from ESF by differentation
lsf = -diff(esf,1); % Calculate differences (approximate the derivative)
pixelsLSF = pixels_micron(1:end-1); % One less because of we only have n-1 differences


% STEP 2: Calculate MTF by applying FFT
nbPoints = numel(pixelsLSF);
deltaMicron = diff(pixelsLSF(1:2));
freqNyquist = 1/(2*deltaMicron);
frequencies = linspace(-freqNyquist/2,freqNyquist/2,nbPoints);
cyclespermilimeter = frequencies*1000;

%% Trick to get rid of rendering noise where we know esf should be one

OneIndex = find(esf<0.98,1,'first');
esf(1:OneIndex,:)=1;


%% Make Output Variables
ESF = struct;
ESF.pixelsMicron = pixels_micron;
ESF.ESF= esf;

LSF=struct;
LSF.LSF = lsf;
LSF.pixelsMicron = pixelsLSF;

MTF =struct;
MTF.cyclespermilimeter=cyclespermilimeter;
for i=1:size(lsf,2)
    MTF.MTF(:,i)=fftshift(abs((fft(lsf(:,i)))));
    
end

%% Helper functions
% The distance to the stepfunction chart, positioned at the xy-plane at z=0, is controlled by changing the distance of the
% camera.
    function thisR = setChartDistance(thisR,distanceFromFilm)
        thisR.lookAt.from= [0 0 -distanceFromFilm];
        thisR.lookAt.to= [0 0 1];
        thisR.lookAt.up=[ 0 1 0];
    end



end

