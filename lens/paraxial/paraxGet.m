function [value]=paraxGet(syst,pName,varargin)
% Function: get specific value from optical or imaging system
%
%    [value]=paraxGet(syst,systType,pName)
%
%
%INPUT
%  syst: System structure [Optical System or Imaging System]
%  pName: specify which features to get
%  varargin: 
%
%OUTPUT
%  value:
%
%
% MP Vistasoft 2014


%% WHICH TYPE OF SYSTEM we have to deal with?
type=syst.type;
type=ieParamFormat(type);

% Which feature or field?
pName=ieParamFormat(pName);



%% SWITCH for CASE

switch type
    
    case {'opticalsystem'}
       [value]=paraxGetOptSyst(syst,pName);
    case {'imagingsystem'}        
        if nargin>2
            [value]=paraxGetImagSyst(syst,pName,varargin{1});
        else
            [value]=paraxGetImagSyst(syst,pName);
        end
        
    otherwise
        error(['Non valid: ',type,' as system type!'])
end

