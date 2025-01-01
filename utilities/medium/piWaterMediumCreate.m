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
p.addOptional('aCDOM440',0); %[0, 19];
p.addOptional('aNAP400',0); 
p.addOptional('cPlankton',0);
p.addOptional('cSmall',0);
p.addOptional('cLarge',0);
p.addOptional('waterAbs', true, @islogical);
p.addOptional('waterSct', true, @islogical);

p.parse(varargin{:});

inputs = p.Results;

medium = piMediumCreate(name, 'type', 'homogeneous');

% These wavelengths are hard coded in PBRT do not change!
wave = 395:5:705;

% Light and water page 90
% waterAbsWave = 200:10:800;
% pureWaterAbs = [3.07 1.99 1.31 0.927 0.720 0.559 0.457 0.373 0.288 0.215...
%     0.141 0.105 0.0844 0.0678 0.0561 0.0463 0.0379 0.0300 0.0220 0.0191...
%     0.0171 0.0162 0.0153 0.0144 0.0145 0.0145 0.0156 0.0156 0.0176 0.0196...
%     0.0257 0.0357 0.0477 0.0507 0.0558 0.0638 0.0708 0.0799 0.108 0.157...
%     0.244  0.289 0.309 0.319 0.329 0.349 0.400 0.430 0.450 0.500 ...
%     0.650 0.839 1.169 1.799 2.38 2.47 2.55 2.51 2.36 2.16 2.07];

[pureWaterAbs, waterAbsWave] = getWaterAbsorption();

% Fog
% waterAbs = 0.15 * ones(1,31);


% waterAbsWave = [400, 405, 410, 415, 420, 425, 430, 435, 440, 445, 450, 455, 460, 465, 470, 475, 480, 485, 490, 495, 500, 505, 510, 515, 520, 525, 530, 535, 540, 545, 550, 555, 560, 565, 570, 575, 580, 585, 590, 595, 600, 605, 610, 615, 620, 625, 630, 635, 640, 645, 650, 655, 660, 665, 670, 675, 680, 685, 690, 695, 700];
% pureWaterAbs = [0.035080, 0.033118, 0.030408, 0.028562, 0.026118, 0.024902, 0.023099, 0.021404, 0.019910, 0.018851, 0.017619, 0.017859, 0.018095, 0.018295, 0.018501, 0.018991, 0.019880, 0.020770, 0.021810, 0.023542, 0.025761, 0.029207, 0.032930, 0.037112, 0.040245, 0.042098, 0.044156, 0.046693, 0.049525, 0.052769, 0.056292, 0.061013, 0.065429, 0.070765, 0.076831, 0.085858, 0.100352, 0.121569, 0.148864, 0.180922, 0.221222, 0.243105, 0.257202, 0.267508, 0.277863, 0.285397, 0.292787, 0.299453, 0.306261, 0.314608, 0.325244, 0.348966, 0.374212, 0.393069, 0.407539, 0.422468, 0.441646, 0.470825, 0.505272, 0.557488, 0.617855];

planktonAbsWave = [400, 405, 410, 415, 420, 425, 430, 435, 440, 445, 450, 455, 460, 465, 470, 475, 480, 485, 490, 495, 500, 505, 510, 515, 520, 525, 530, 535, 540, 545, 550, 555, 560, 565, 570, 575, 580, 585, 590, 595, 600, 605, 610, 615, 620, 625, 630, 635, 640, 645, 650, 655, 660, 665, 670, 675, 680, 685, 690, 695, 700];
planktonAbs = [0.015500, 0.016200, 0.016900, 0.016950, 0.017000, 0.017400, 0.017800, 0.018100, 0.018400, 0.018100,...
    0.017800, 0.017950, 0.018100, 0.017600, 0.017100, 0.015850, 0.014600, 0.013850, 0.013100, 0.012600,...
    0.012100, 0.011450, 0.010800, 0.010250, 0.009700, 0.009250, 0.008800, 0.008300, 0.007800, 0.007100,...
    0.006400, 0.005800, 0.005200, 0.004900, 0.004600, 0.004700, 0.004800, 0.004850, 0.004900, 0.004500,...
    0.004100, 0.004150, 0.004200, 0.004550, 0.004900, 0.005400, 0.005900, 0.006000, 0.006100, 0.005750,...
    0.005400, 0.006500, 0.007600, 0.009500, 0.011400, 0.011250, 0.011100, 0.008650, 0.006200, 0.003900,...
    0.001600];


cdomAbs = exp(-0.014 * (wave - 440));
napAbs = exp(-0.011 * (wave - 400));
         
totalAbs = interp1(waterAbsWave, pureWaterAbs, wave, 'linear','extrap') * inputs.waterAbs + ...
           interp1(planktonAbsWave, planktonAbs, wave, 'linear', 'extrap') * inputs.cPlankton + ...
           cdomAbs * inputs.aCDOM440 + napAbs * inputs.aNAP400;

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

% inputs.waterSct = 0;
% inputs.cSmall = 0.01;
% inputs.cLarge = 0;
vsf = vsfWater * inputs.waterSct + inputs.cSmall * vsfSmall + inputs.cLarge * vsfLarge;

properties.vsf = vsf;
properties.scattering = sum(vsf .* repmat(sin(angles),length(wave),1) .* angles(2) * 2 * pi, 2);

properties.phaseFunction = vsf ./ repmat(properties.scattering, [1, length(angles)]);
properties.angles = angles;

medium.sigma_a.value = piSPDCreate(wave, properties.absorption);
medium.sigma_s.value = piSPDCreate(wave, properties.scattering);


end



function [abs, wave] = getWaterAbsorption()

% H. Buiteveld and J. M. H. Hakvoort and M. Donze, "The optical properties
% of pure water," in SPIE Proceedings on Ocean Optics XII, edited by J. S.
% Jaffe, 2258, 174--183, (1994).

% lambda	 absorption
%  (nm) 	   (1/cm)   

data = [300	 0.000382
302	 0.000361
304	 0.000341
306	 0.000323
308	 0.000305
310	 0.000288
312	 0.000272
314	 0.000257
316	 0.000242
318	 0.000228
320	 0.000215
322	 0.000203
324	 0.000191
326	 0.00018
328	 0.00017
330	 0.00016
332	 0.000151
334	 0.000142
336	 0.000134
338	 0.000127
340	 0.000119
342	 0.000113
344	 0.000107
346	 0.000101
348	 9.6e-05
350	 9.1e-05
352	 8.6e-05
354	 8.2e-05
356	 7.8e-05
358	 7.5e-05
360	 7.1e-05
362	 6.9e-05
364	 6.6e-05
366	 6.4e-05
368	 6.2e-05
370	 6e-05
372	 5.8e-05
374	 5.7e-05
376	 5.6e-05
378	 5.5e-05
380	 5.4e-05
382	 5.4e-05
384	 5.3e-05
386	 5.3e-05
388	 5.3e-05
390	 5.4e-05
392	 5.4e-05
394	 5.4e-05
396	 5.5e-05
398	 5.6e-05
400	 5.8e-05
402	 5.9e-05
404	 6.1e-05
406	 6.3e-05
408	 6.5e-05
410	 6.7e-05
412	 6.9e-05
414	 7.2e-05
416	 7.4e-05
418	 7.6e-05
420	 7.9e-05
422	 8.2e-05
424	 8.4e-05
426	 8.7e-05
428	 8.9e-05
430	 9.2e-05
432	 9.4e-05
434	 9.7e-05
436	 9.9e-05
438	 0.000102
440	 0.000104
442	 0.000106
444	 0.000108
446	 0.00011
448	 0.000112
450	 0.000114
452	 0.000116
454	 0.000118
456	 0.00012
458	 0.000122
460	 0.000124
462	 0.000126
464	 0.000128
466	 0.00013
468	 0.000133
470	 0.000135
472	 0.000138
474	 0.000141
476	 0.000144
478	 0.000148
480	 0.000152
482	 0.000157
484	 0.000162
486	 0.000167
488	 0.000174
490	 0.000181
492	 0.000189
494	 0.000198
496	 0.000209
498	 0.000223
500	 0.000238
502	 0.000255
504	 0.000273
506	 0.000291
508	 0.00031
510	 0.000329
512	 0.000349
514	 0.000368
516	 0.000386
518	 0.000404
520	 0.000409
522	 0.000416
524	 0.000409
526	 0.000427
528	 0.000423
530	 0.000429
532	 0.000445
534	 0.000456
536	 0.00047
538	 0.00048
540	 0.000495
542	 0.000503
544	 0.000527
546	 0.000544
548	 0.000564
550	 0.000588
552	 0.000611
554	 0.000631
556	 0.000646
558	 0.000658
560	 0.000672
562	 0.000686
564	 0.000699
566	 0.000718
568	 0.000734
570	 0.000759
572	 0.000787
574	 0.000819
576	 0.000858
578	 0.000896
580	 0.000952
582	 0.001
584	 0.001079
586	 0.001159
588	 0.001253
590	 0.001356
592	 0.001459
594	 0.001567
596	 0.0017
598	 0.00186
600	 0.002224
602	 0.002366
604	 0.002448
606	 0.002587
608	 0.002653
610	 0.002691
612	 0.002715
614	 0.00274
616	 0.002764
618	 0.002785
620	 0.00281
622	 0.002839
624	 0.002868
626	 0.002893
628	 0.002922
630	 0.002955
632	 0.002988
634	 0.003011
636	 0.003038
638	 0.003076
640	 0.003111
642	 0.003144
644	 0.003181
646	 0.003223
648	 0.003263
650	 0.003315
652	 0.003362
654	 0.003423
656	 0.003508
658	 0.003636
660	 0.003791
662	 0.003931
664	 0.004019
666	 0.004072
668	 0.004098
670	 0.004122
672	 0.00415
674	 0.004173
676	 0.004223
678	 0.00427
680	 0.004318
682	 0.004381
684	 0.004458
686	 0.004545
688	 0.004646
690	 0.00476
692	 0.004903
694	 0.005071
696	 0.005244
698	 0.00547
700	 0.005722
702	 0.005995
704	 0.006303
706	 0.006628
708	 0.006993
710	 0.007415
712	 0.007893
714	 0.008445
716	 0.009109
718	 0.009871
720	 0.010724
722	 0.011679
724	 0.012684
726	 0.013719
728	 0.01487
730	 0.016211
732	 0.017872
734	 0.019917
736	 0.022074
738	 0.023942
740	 0.025319
742	 0.026231
744	 0.026723
746	 0.027021
748	 0.027216
750	 0.027334
752	 0.027413
754	 0.027478
756	 0.027542
758	 0.027628
760	 0.02771
762	 0.027733
764	 0.027742
766	 0.027701
768	 0.02761
770	 0.027542
772	 0.027482
774	 0.027305
776	 0.027097
778	 0.026896
780	 0.02659
782	 0.026332
784	 0.026062
786	 0.025702
788	 0.025335
790	 0.024924
792	 0.024481
794	 0.024083
796	 0.023742
798	 0.023332
800	 0.022932];

wave = data(:,1);
abs = data(:,2) * 100; % Convert 1/cm to 1/m

end

