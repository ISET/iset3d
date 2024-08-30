function value = piParameterGet(thisLine, match)
% Interpret the parameters on a text line in a PBRT file
%
% Synopsis
%  value = piParameterGet(thisLine, match)
%
% Input
%  thisLine - The input text
%  match    - the data type (e.g., integer or string)
%
% Output
%  value
%
% Description
%  Read in a line of text from a PBRT file.  Interpret the relevant
%  value.
%
% See also
%   piLightGetFromText

% Example:
%{
thisLine = 'AreaLightSource "diffuse" "integer nsamples" [ 16 ] "bool twosided" "true" "rgb L" [ 7.39489317 7.35641623 7.32100344 ]';
value = piParameterGet(thisLine, 'bool twosided')
val = piParameterGet(thisLine, 'rgb L')
%}

% A special case for the light spectrum
if strcmp(match, 'L')
    % There should be a space before the L
    match = ' L';
elseif strcmp(match,'I')
    match = ' I';
end

value=[];
if piContains(match,'string') || piContains(match,'bool') ||...
        piContains(match,'texture')
    matchIndex = regexp(thisLine, match);
    if isempty(matchIndex)
        return;
    end
    newline = thisLine(matchIndex+length(match)+2 : end);
    parameter_toc = regexp(newline, '"');
    value = newline(parameter_toc(1)+1: parameter_toc(2)-1);
elseif (piContains(match, ' L') || piContains(match,' I')) && piContains(thisLine,'.spd')
    % Find the position of '.spd' in the string
    spdPos = strfind(thisLine, '.spd');

    % Search backwards from '.spd' position to find the start quote
    startPos = find(thisLine(1:spdPos) == '"', 1, 'last');

    % Search forwards from '.spd' position to find the end quote
    endPos = spdPos + find(thisLine(spdPos:end) == '"', 1) - 1;

    % Extract the SPD file string between the start and end quotes
    value = thisLine(startPos+1:endPos-1);

    % If it is a spd file, load in the data as a vector.  Note that
    % piRead always adds the input scene directory to the path, so
    % partial descriptions of the file path should work here.
    % (BW.  8/27/2024).
    if exist(value, 'file')
        % One time this failed if not the full path.
        value = which(value);

        fid = fopen(value, 'r');
        spd = textscan(fid, '%d %f');
        fclose(fid);
        value = piMaterialCreateSPD(spd{1}, spd{2});
    else
        error('SPD file: %s does not exist.', value)
    end
else
    matchIndex = regexp(thisLine, match);
    if isempty(matchIndex), return;end
    newline = thisLine(matchIndex+length(match)+2 : end);
    quote_toc = regexp(newline, '"');
    if isempty(quote_toc)
        end_toc = numel(newline);
    else
        end_toc = quote_toc-1;
    end
    % get rid of squre brackets
    value = newline(1: end_toc(1));
    % value = str2num(value);
    value = strrep(strrep(value, '[', ''), ']', '');
    value = strsplit(value, ' ');
    idx = cellfun(@isempty, value);
    value(idx) = [];
    value = str2double(value);
end

end
