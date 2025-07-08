function [newlines] = piFormatConvert(txtLines)
% Format txtlines so that ISET3d parser (Zheng) can interpret it
%
% Brief Description
%  PBRT accepts free-style formats for the PBRT commands where the
%  parameters can be spread across several lines. ISET3d wants the key
%  words to be followed by all the parameters in a single line. 
%  
% Inputs
%   txtLines - A cell array of text lines read from a pbrt file.
%              These lines are from the geometry PBRT file.
%
% Output
%   newlines - Formatted to be compliant with ISET3d needs. 
%
% Description
%  This routine formats the free-style PBRT text files  so that the
%  key words are followed by their parameters in a single line.  Key
%  words include NamedMaterial, Shape, ConcatTransform, Transform,
%  MakeNamedMateria, Scale, Texture, LightSource (maybe others).
%
% It also catches various special cases.  For example,
%
%   1. Delete any empty lines
%   2. Remove comments (lines starting with #) unless it contains a
%      key string (parseString), such as #ObjectName
%   3. We delete lines with 'Warning'
%
% See also
%   Called by piRead -> piReadWorldText -> piFormatConvert and also
%   called by piRead -> piFormatConvert for the 'World' cell array

%% Initialize counters
nn=1;ii=1;

%% remove empty cells
txtLines = txtLines(~cellfun('isempty',txtLines));

%% remove lines start with '#' but we keep lines with these strings

% We keep the text lines that do NOT start with # or that do contain
% one of the parseStrings.
parseStrings = {'#ObjectName','#object name','#CollectionName','#Instance','#MeshName'};
txtLines = txtLines(or(~strncmp(txtLines,'#',1), contains(txtLines,parseStrings)));

% We use these tokens to decide whether this is a line we process.  I
% am not sure how this list was generated.  Perhaps we should
% literally list the terms that we are looking for? (BW)
tokenlist = {'A', 'C' , 'F', 'I', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T'};

% We replace tabs with a blank in all lines.
txtLines = regexprep(txtLines, '\t', ' ');

%% Put the block on a single line for the parser

% If the text has a right bracket, ], we are at the end of the block.
% We concatenate all the lines prior to this until we come to a stop.
% That way the block is on a single line for Zheng's parser.

% These are the lines with nothing but a right bracket.  We will merge
% them with the prior line.  This happens in the
% MacBethChecker_geometry.pbrt, and therefore someone else in the
% universe might have done this. 
idxList = find(strcmp(txtLines,']'));
for idx = 1:numel(idxList)
    % For each one we concatenate the prior line with this one.
    txtLines{idxList(idx)-1} = strcat(txtLines{idxList(idx)-1},txtLines{idxList(idx)});
    % Then we set this line to empty.  Empty lines will be removed shortly.
    txtLines{idxList(idx)} = [];
end
%}

txtLines = txtLines(~cellfun('isempty',txtLines));
nLines = numel(txtLines);
newlines = cell(nLines, 1);

% For all nLines, we process
while ii <= nLines
    thisLine = txtLines{ii};   % Here is the line

    % Why are we testing against the length of 'Shape'?  That's weird.
    % Also, should we be removing any spaces at the front of the line?
    if length(thisLine) >= length('Shape')
        % We see if the first letter is any of the tokens, and the
        % line does not start with 'Include' or 'Attribute'.
        if any(strncmp(thisLine, tokenlist, 1)) && ...
                ~strncmp(thisLine,'Include', length('Include')) && ...
                ~strncmp(thisLine,'Attribute', length('Attribute'))
            
            % We begin the block on this line.
            blockBegin = ii;

            % If this is the last line, we just add it and leave.
            if ii == nLines
                newlines{nn,1}=thisLine;
                break;
            end

            % Starting with the next line, keep adding lines whose
            % first symbol is a double quote ("), but we handled the
            % last line first. 
            for jj=(ii+1):nLines+1
                % If we are at the end (ii == nLines) or this line is
                % empty, or the first entry on this line is not a
                % double quote
                if jj==nLines+1 || isempty(txtLines{jj}) || ~isequal(txtLines{jj}(1),'"')
                    % If we are at the end (ii == nLines) or this line
                    % is empty, or the second two characters are empty
                    % or if the first character is in the token list
                    % or if the first two entries are numeric.
                    if jj==nLines+1 || ...
                            isempty(txtLines{jj}) || ...
                            isempty(sscanf(txtLines{jj}(1:2), '%f')) ||...
                            any(strncmp(txtLines{jj}, tokenlist, 1))

                        % If we got this far, we are at the end of the
                        % block.
                        blockEnd = jj;

                        % These are the lines in this block that we
                        % will parse.
                        blockLines = txtLines(blockBegin:(blockEnd-1));

                        % This is the first line of the block.
                        % Starting with the 2nd line, we step through
                        texLines=blockLines{1};
                        for texI = 2:numel(blockLines)
                            % If the last texLine is not empty and the
                            % first character is not a space, append the
                            % line but put in a space
                            if ~strcmp(texLines(end),' ') && ~strcmp(blockLines{texI}(1),' ')
                                texLines = [texLines,' ',blockLines{texI}];
                            else
                                % It had a space, we just append the
                                % line
                                texLines = [texLines,blockLines{texI}];
                            end
                        end
                        % Append this line to what we will return, all
                        % the blocks each on a single line.
                        newlines{nn,1}=texLines; nn=nn+1;

                        % Update the Block counter.
                        ii = jj-1;
                        break;
                    end
                end
                
            end
        else
            % None of the tokens, or maybe an Include or Attribute.
            % So, we just add the line here and increment the counter.
            newlines{nn,1}=thisLine; nn=nn+1;
        end
    end
    ii=ii+1;
end

%% Clear out junk
newlines(piContains(newlines,'Warning'))=[];
newlines = newlines(~cellfun('isempty', newlines));

%% MakeNamedMaterial lines with string type "mix" need a pair [ ]

% Find strings that start with 'MakedNamedMaterial' and contain 'mix'
result = cellfun(@(x) startsWith(x, 'MakeNamedMaterial') & contains(x,'mix'), newlines); 
idx = find(result);

%% Fix up the mix material line
% 
% Insert the brackets following the two strings after 'string materials' 
for ii=1:numel(idx)
    str = newlines{idx(ii)};
    x = strfind(str,'"string materials"') + length('"string materials"') - 1;
    nextQuotes = strfind(str((x+1):end),'"');
    if x + nextQuotes(4) == length(str)
        % Nothing beyond the material names
        newlines{idx(ii)} = [ str(1:x),' [',str((x+1):end),' ]'];
    else
        % Insert
        newlines{idx(ii)} = [ str(1:x),'[ ',str((x+1):(x+nextQuotes(4))),'] ', str((x+nextQuotes(4)+1):end)];
    end
end

end