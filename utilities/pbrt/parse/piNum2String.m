function string = piNum2String(num)
% ISET3d replacement for num2str
%
% Synopsis
%   string = piNum2String(num)
%
% Input
%   num - An array of numbers
%
% Output
%   str - A char array?  A string array?
%
% Description
%
%  The speed on num2str is bad.  But the function has some features we
%  like, though. This function emulates num2string (we think) but runs much
%  faster
%
%  Because these are supposed to fit in text, we always force the num to be
%  a row vector.
%
% See also
%    sprintf

% Convert a number to a string
if isinteger(num)
    % Adding num(:)' to avoid dimension mismatch
    string = int2str(num(:)');
else
    % using %.5f is much slower than simply asking for precision
    % ZLY 2022: In some special cases, the shape value can be very small 
    % (less than 0.01). If so, num2str with formatSpec = integer won't
    % work. So for that special case, we keep the formatSpec = '%.5f' to
    % keep the string from scientific notation.
    if all(num(:) >= 1e-2)
        formatSpec = 7; % 7 significant digits
        string = num2str(num(:)', formatSpec);
    else
        formatSpec = '%.5f ';
        string = num2str(num(:)', formatSpec);
    end
end

% remove extra space from num2str function
stringSplits = strsplit(string,' ');
string = stringSplits{1};
for ii = 2:numel(stringSplits)
    space = ' ';
    string = [string, space, stringSplits{ii}];
end
end
