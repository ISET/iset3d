function files = list(varargin)
% List and summarize the lenses in data/lens
%
% Synopsis
%   files = lensC.list;
%
% Inputs
%   N/A
%
% Key/val pairs
%   quiet      - Do not print, just return the list (false)
%   nameonly   - Return the whole file struct, ot just the name (false)
%
% Output
%   files - Array of file information
%
% See also
%   lensC

%% Parse inputs

varargin = ieParamFormat(varargin);

p = inputParser;

% If you want the list returned without a print
p.addParameter('quiet',false,@islogical);
p.addParameter('nameonly',false,@islogical);

p.parse(varargin{:});

quiet = p.Results.quiet;
nameonly = p.Results.nameonly;

%%
files = dir(fullfile(piDirGet('lens'),'*.json'));

if nameonly
    names = cell(numel(files),1);
    for ii=1:numel(files)
        names{ii} = files(ii).name;
    end
    files = names;
end

if quiet, return;
else
    fprintf('\nLens JSON files\n\n')
    for ii=1:length(files)
        fprintf('%d - %s\n',ii,files(ii).name);
    end
end


end