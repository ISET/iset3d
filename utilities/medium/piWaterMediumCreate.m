function [medium, properties] = piWaterMediumCreate(name, varargin)
% [medium, properties] = piWaterMediumCreate(name, varargin)
%
% Create a seawater medium.
% Creates a PBRT homogenous medium which uses biological models to create
% properties of natural waters.
%
% water is a description of a PBRT object that desribes a homogeneous
% medium.  The waterProp are the parameters that define the seawater
% properties, including absorption, scattering, and so forth.
%
% Creates a PBRT homogenous medium which uses biological models to create
% properties of natural waters.
%
% HB created a full representation model of scattering that has a number of
% different parameters.
%
% vsf is volume scattering function. Outer product of the scattering
% function and the phaseFunction.  For pbrt you only specify the scattering
% function and a single scalar that specifies the phaseFunction.
%
% phaseFunction 
%
% PBRT allows specification only of the parameters scattering, and
% absorption spectra.  We return all the properties in 'properties' but we
% compress all the variables into what PBRT can deal with in 'medium'.
%
% Some day, we may expand. 
%
% Maybe we should put 'properties' into the 'metadata' slot of the scene.
%
% We should implement sceneSet/Get on the 'medium' properties that PBRT can
% use.
%
% Henryk Blasinski, 2023

p = inputParser;
p.addOptional('aCDOM440',0);
p.addOptional('aNAP400',0);
p.addOptional('cPlankton',0);
p.addOptional('cSmall',0);
p.addOptional('cLarge',0);
p.addOptional('waterAbs',1);
p.addOptional('waterSct',1);

p.parse(varargin{:});

inputs = p.Results;

medium = piMediumCreate(name,'type','homogeneous');

%wave = 395:5:705;
wave = 400:10:700;

% Light and water page 90
%waterAbsWave = 200:10:800;
% waterAbs = [3.07 1.99 1.31 0.927 0.720 0.559 0.457 0.373 0.288 0.215...
%     0.141 0.105 0.0844 0.0678 0.0561 0.0463 0.0379 0.0300 0.0220 0.0191...
%     0.0171 0.0162 0.0153 0.0144 0.0145 0.0145 0.0156 0.0156 0.0176 0.0196...
%     0.0257 0.0357 0.0477 0.0507 0.0558 0.0638 0.0708 0.0799 0.108 0.157...
%     0.244  0.289 0.309 0.319 0.329 0.349 0.400 0.430 0.450 0.500 ...
%     0.650 0.839 1.169 1.799 2.38 2.47 2.55 2.51 2.36 2.16 2.07];

% waterAbs = [3.07 1.99 1.31 0.927 0.720 0.559 0.457 0.373 0.288 0.215...
%     0.141 0.105 0.0844 0.0678 0.0561 0.0463 0.0379 0.0300 0.0220 0.0191...
%     0.0171 0.0162 0.0153 0.0144 0.0145 0.0145 0.0156 0.0156 0.0176 0.0196...
%     0.0257 0.0357 0.0477 0.0507 0.0558 0.0638 0.0708 0.0799 0.108 0.157...
%     0.244  0.289 0.309 0.319 0.329 0.349 0.400 0.430 0.450 0.500 ...
%     0.650 0.839 1.169 1.799 2.38 2.47 2.55 2.51 2.36 2.16 2.07];

waterAbsWave = 400:10:700;
waterAbs = [0.0171 0.0162 0.0153 0.0144 0.0145 0.0145 0.0156 0.0156 0.0176 0.0196...
    0.0257 0.0357 0.0477 0.0507 0.0558 0.0638 0.0708 0.0799 0.108 0.157...
    0.244  0.289 0.309 0.319 0.329 0.349 0.400 0.430 0.450 0.500 ...
    0.650];

% Fog
% waterAbs = 0.15 * ones(1,31);


% absWave = [400, 405, 410, 415, 420, 425, 430, 435, 440, 445, 450, 455, 460, 465, 470, 475, 480, 485, 490, 495, 500, 505, 510, 515, 520, 525, 530, 535, 540, 545, 550, 555, 560, 565, 570, 575, 580, 585, 590, 595, 600, 605, 610, 615, 620, 625, 630, 635, 640, 645, 650, 655, 660, 665, 670, 675, 680, 685, 690, 695, 700];
% pureWaterAbs = [0.035080, 0.033118, 0.030408, 0.028562, 0.026118, 0.024902, 0.023099, 0.021404, 0.019910, 0.018851, 0.017619, 0.017859, 0.018095, 0.018295, 0.018501, 0.018991, 0.019880, 0.020770, 0.021810, 0.023542, 0.025761, 0.029207, 0.032930, 0.037112, 0.040245, 0.042098, 0.044156, 0.046693, 0.049525, 0.052769, 0.056292, 0.061013, 0.065429, 0.070765, 0.076831, 0.085858, 0.100352, 0.121569, 0.148864, 0.180922, 0.221222, 0.243105, 0.257202, 0.267508, 0.277863, 0.285397, 0.292787, 0.299453, 0.306261, 0.314608, 0.325244, 0.348966, 0.374212, 0.393069, 0.407539, 0.422468, 0.441646, 0.470825, 0.505272, 0.557488, 0.617855];
% planktonAbsWave = [400, 405, 410, 415, 420, 425, 430, 435, 440, 445, 450, 455, 460, 465, 470, 475, 480, 485, 490, 495, 500, 505, 510, 515, 520, 525, 530, 535, 540, 545, 550, 555, 560, 565, 570, 575, 580, 585, 590, 595, 600, 605, 610, 615, 620, 625, 630, 635, 640, 645, 650, 655, 660, 665, 670, 675, 680, 685, 690, 695, 700];
planktonAbsWave = waterAbsWave;
% planktonAbs = [0.015500, 0.016200, 0.016900, 0.016950, 0.017000, 0.017400, 0.017800, 0.018100, 0.018400, 0.018100,...
%     0.017800, 0.017950, 0.018100, 0.017600, 0.017100, 0.015850, 0.014600, 0.013850, 0.013100, 0.012600,...
%     0.012100, 0.011450, 0.010800, 0.010250, 0.009700, 0.009250, 0.008800, 0.008300, 0.007800, 0.007100,...
%     0.006400, 0.005800, 0.005200, 0.004900, 0.004600, 0.004700, 0.004800, 0.004850, 0.004900, 0.004500,...
%     0.004100, 0.004150, 0.004200, 0.004550, 0.004900, 0.005400, 0.005900, 0.006000, 0.006100, 0.005750,...
%     0.005400, 0.006500, 0.007600, 0.009500, 0.011400, 0.011250, 0.011100, 0.008650, 0.006200, 0.003900,...
%     0.001600];
planktonAbs = [0.015500, 0.016900, 0.017000, 0.017800, 0.018400,...
    0.017800, 0.018100, 0.017100, 0.014600, 0.013100,...
    0.012100, 0.010800, 0.009700, 0.008800, 0.007800,...
    0.006400, 0.005200, 0.004600, 0.004800, 0.004900,...
    0.004100, 0.004200, 0.004900, 0.005900, 0.006100,...
    0.005400, 0.007600, 0.011400, 0.011100, 0.006200,...
    0.001600];

cdomAbs = exp(-0.014 * (wave - 440));
napAbs = exp(-0.011 * (wave - 400));
%         
% totalAbs = interp1(waterAbsWave,waterAbs, wave, 'linear','extrap') * inputs.waterAbs + ...
%            interp1(planktonAbsWave,planktonAbs, wave, 'linear', 'extrap') * inputs.cPlankton + ...
%            cdomAbs * inputs.aCDOM440 + napAbs * inputs.aNAP400;

totalAbs = [0.01709999 0.01619999 0.0153     0.0144     0.0145     0.0145...
  0.0156     0.0156     0.01759999 0.01959996 0.02569949 0.03569044...
  0.04760448 0.05055081 0.05550808 0.06309916 0.06948583 0.07732511...
  0.09740299 0.1179949  0.13004342 0.13174472 0.13214479 0.13229474...
  0.13241882 0.13260643 0.13285853 0.13292556 0.13295315 0.13298976...
  0.13301151];





properties.wave = wave; 
properties.absorption = totalAbs; % change totalAbs to calculated absorption spectrum


particleAngles = [0.000000, 0.008727, 0.017453, 0.026180, 0.034907, 0.069813, 0.104720, 0.174533, 0.261799, 0.523599,...
    0.785398, 1.047198, 1.308997, 1.570796, 1.832596, 2.094395, 2.356194, 2.617994, pi];
smallParticles = [5.300000, 5.300000, 5.200000, 5.200000, 5.100000, 4.600000, 3.900000, 2.500000, 1.300000, 0.290000,...
    0.098000, 0.041000, 0.020000, 0.012000, 0.008600, 0.007400, 0.007400, 0.007500, 0.008100];
largeParticles = [140.000000, 98.000000, 46.000000, 26.000000, 15.000000, 3.600000, 1.100000, 0.200000, 0.050000, 0.002800,...
    0.000620, 0.000380, 0.000200, 0.000063, 0.000044, 0.000029, 0.000020, 0.000020, 0.000070];

numAngles = 33;
angles = (0:(numAngles-1))/(numAngles-1) * pi;

vsfWater = (550 ./ wave(:)).^(4.32) * (0.000093 * (1 + 0.835 * (cos(angles).^2)));
vsfSmall = (550 ./ wave(:)).^(1.7) * interp1(particleAngles, smallParticles, angles);
vsfLarge = (550 ./ wave(:)).^(0.3) * interp1(particleAngles, largeParticles, angles);
% disp(size(vsfWater))
% disp(size(vsfSmall))
% disp(size(vsfLarge))

inputs.waterSct = 0;
inputs.cSmall = 0.01;
inputs.cLarge = 0;
vsf = vsfWater * inputs.waterSct + inputs.cSmall * vsfSmall + inputs.cLarge * vsfLarge;

properties.vsf = vsf;
% properties.scattering = sum(vsf .* repmat(sin(angles),length(wave),1) .* angles(2) * 2 * pi, 2);
properties.scattering =[0.21891675 0.07703295 0.03602325 0.02443143 0.02031251 0.01817774...
  0.0147101  0.01229263 0.01268193 0.01430199 0.01472129 0.01439673...
  0.01326589 0.01236312 0.01304923 0.01472852 0.01569635 0.01523161...
  0.01350914 0.01215748 0.01134344 0.01114992 0.01096276 0.01084534...
  0.01054928 0.01017065 0.0099527  0.0095312  0.00945834 0.00917996...
  0.00892606];

% properties.phaseFunction = vsf ./ repmat(properties.scattering, [1, length(angles)]);
% properties.angles = angles;

medium.sigma_a.value = piSPDCreate(wave, properties.absorption);
medium.sigma_s.value = piSPDCreate(wave, properties.scattering);


end

