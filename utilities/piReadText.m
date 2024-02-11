function txtLines = piReadText(fname)
% Open text, read text, close excluding comment lines
%
% Synopsis
%    txtLines = piReadText(fname)
%
% Brief description:
%   Read the text lines in a PBRT file. Also 
%
%    * strips any trailing blanks on the line
%    * does some fix for square brackets (some historical thing)
%    * Removes all blank lines
%
%   Comment lines are included because they sometimes contain useful
%   information about object names.
%
% Inputs
%   fname = PBRT scene file name.  
%
% Outputs
%   txtLines - Cell array of each of the text lines in the file.
%
% See also
%   piRead, recipeGet

%% Open the PBRT scene file
fileID = fopen(fname);
if fileID < 0
    error('File not found %s\n',fname);
end

tmp = textscan(fileID,'%s','Delimiter','\n');

txtLines = tmp{1};

fclose(fileID);

% Remove empty lines.  Shouldn't this be handled in piReadText?
txtLines = txtLines(~cellfun('isempty',txtLines));

% We remove any trailing blank spaces from the text lines here. (BW).
for ii=1:numel(txtLines)
    idx = find(txtLines{ii} ~=' ',1,'last');
    txtLines{ii} = txtLines{ii}(1:idx);
end

% Replace left and right bracks with double-quote.  ISET3d formatting.
txtLines = strrep(txtLines, '[ "', '"');
txtLines = strrep(txtLines, '" ]', '"');

end