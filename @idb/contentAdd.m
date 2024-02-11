function [status, result] = contentAdd(obj, collection, varargin)
% Add the data into database
%
% Brief
%   Add the data into database
%% Parse inputs
varargin = ieParamFormat(varargin);
p = inputParser;

try
    status =insert(obj.connection,collection, isetobj);
catch ex
    status = -1;
    fprintf("[MSG]: Database add failed: %s\n", ex.message);
end
end

