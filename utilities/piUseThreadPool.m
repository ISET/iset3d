function result = piUseThreadPool(options)
%PIUSETHREADPOOL Choose thread pool instead of process pool for parallel
% operations. Allows much faster pool initializtion, but does not work
% for some cases where certain operations are done inside a parallel
% function, so an't always be use

arguments
    options.numThreads = 0;
end

% Mod for faster parpool startup
poolobj = gcp('nocreate');
if isempty(poolobj)
    if ~isMATLABReleaseOlderThan("R2022b") && (options.numThreads > 0)
        parpool('Threads', options.numThreads);
    else
        parpool('Threads'); % let it use its default
    end
end

end

