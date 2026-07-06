%% Lens focus distances
%
% Compare film distances for several object distances and lens files.  This
% local example replaces the older render-based focus-distance script from
% ISETLens so it can run without Docker.
%
% See also
%   lensFocus, lensC

%% Initialize
ieInit;

%% Compute focus curves
lensNames = {'dgauss.22deg.3.0mm.json','dgauss.22deg.12.5mm.json'};
objectDistanceMM = [500 1000 2000 1e6];
filmDistanceMM = zeros(numel(lensNames),numel(objectDistanceMM));

for ll = 1:numel(lensNames)
    lensFile = fullfile(piDirGet('lens'),lensNames{ll});
    for dd = 1:numel(objectDistanceMM)
        filmDistanceMM(ll,dd) = lensFocus(lensFile,objectDistanceMM(dd));
    end
end

disp(array2table(filmDistanceMM, ...
    'RowNames',lensNames, ...
    'VariableNames',compose('object_%gmm',objectDistanceMM)));

assert(all(isfinite(filmDistanceMM(:))));
assert(all(filmDistanceMM(:) > 0));

%% Plot the focus shift
ieFigure;
semilogx(objectDistanceMM,filmDistanceMM','o-','LineWidth',1.5);
grid on;
xlabel('Object distance (mm)');
ylabel('Film distance (mm)');
legend(lensNames,'Interpreter','none','Location','best');

%% END
