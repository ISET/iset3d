%  Converting the radiance in a rendered image into something
%  plausible
%

%% This was a kitchen scene

scene = ieGetObject('scene');

%%
E    = sceneGet(scene,'energy');
wave = sceneGet(scene,'wave');

size(E)
[E,r,c] = RGB2XWFormat(E);
E = E';

%% Normalize the radiance levels
s = max(E);
lst = s>1e-4;
Es = E(:,lst);
s = max(Es);
for ii = 1:size(Es,2)
    Es(:,ii) = (1/s(ii))*Es(:,ii);
end
[U,S,V] = svd(Es,'econ');

% Radiance basis
plotRadiance(wave,U(:,1:6));
% cumsum(diag(S.^2))/sum(diag(S.^2))

% [coef, score, latent] = pca(Es);

% Radiance basis via pca
% plotRadiance(wave,score(:,1:6));

% L = sceneGet(scene,'illuminant energy');
% ieNewGraphWin;
% plot(wave,L);

%% Reflectance

R = diag(1./L)*Es;
[W,D,Y] = svd(R,'econ');
% cumsum(diag(D.^2))/sum(diag(D.^2))

plotReflectance(wave,W(:,1:6));

%% Replace the simulated radiance or reflectance functions
%
% We choose a desired radiance or radiance basis, and then using that
% to replace the simulated radiance (or reflectance).

E = sceneGet(scene,'energy');
wave = sceneGet(scene,'wave');
size(E)

[E,r,c] = RGB2XWFormat(E);
E = E';

% ieNewGraphWin;
% plot(wave,E(:,randi(5000,50)));

L = sceneGet(scene,'illuminant energy');
R = diag(1./L)*E;

% The window is very bright and dominates ... but it isn't really a
% reflectance.
% plotReflectance(wave,R(:,randi(5000,50)));

%% Rapprox = R;

% Our default 8 dimensional basis
b1 = ieReadSpectra('reflectanceBasis.mat',wave);

nDims = 8;
bsmall = b1(:,1:nDims);
Rapprox = bsmall*(bsmall'* R);

Rapprox = ieScale(Rapprox,1);

% You can see the window here, I think.
% ieNewGraphWin; histogram(Rapprox(10,:));
% img = Rapprox(10,:); img = reshape(img,r,c); imagesc(img);

% Maybe we should add a little random noise to the reflectance
% functions?  Poisson or Gaussian?  The small scale here is because
% the window is so bright.  This value is about 1 percent of the true
% reflectances.
% Rapprox = Rapprox + randn(size(Rapprox))*1e-4;

% ieNewGraphWin;
% plot(wave,Rapprox(:,randi(5000,50)));

Eapprox = diag(L)*Rapprox;
Eapprox = XW2RGBFormat(Eapprox',r,c);

sceneb1 = sceneSet(scene,'energy',Eapprox);
sceneb1 = sceneSet(sceneb1,'name',sprintf('dim %d',nDims));

sceneWindow(sceneb1);

%%  END


