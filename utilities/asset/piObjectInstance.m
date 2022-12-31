function piObjectInstance(thisR)
% Create instances for each of the objects in a recipe
%
% Synopsis
%   piObjectInstance(thisR)
%
% Brief
%   This function prepares a recipe with assets so that its objects can be
%   copied by creating an instance
%
% Inputs
%   thisR - A recipe
%
% Outputs
%   N/A
%
% Description
%   
%
% See also
%  piObjectInstanceCreate, t_piSceneInstances

% Find all the objects.  These all have a mesh that can be reused by the
% instances. 
objID = thisR.get('objects');

% Create an instance for each of the objects.  In principle, I suppose we
% could send in a list of objIDs and create instances of only those.
for ii = 1:numel(objID)

    % Find the path to the root node.
    p2Root = thisR.get('asset',objID(ii),'pathtoroot');    

    % The last index is the node just prior to root. We are passing in this
    % node to create the instance. But, I am not sure this is the right
    % logic (BW). 
    %
    % In the case of the macbeth color checker, there are many objects that
    % are all inside of a general MCC node. So all of the patches return
    % the index to the main node, and all of the instances point to that
    % node.
    %
    % Update the node by saying it is an object pointed to by other
    % instances.  Maybe we should write:
    %
    %   thisR.set('node',idx,'object instance',true);
    %
    thisNode = thisR.get('node',p2Root(end));
    thisNode.isObjectInstance = 1;
    thisR.set('assets',p2Root(end), thisNode);

    if isempty(thisNode.referenceObject)
        thisR = piObjectInstanceCreate(thisR, thisNode.name,'position',[0 0 0],'rotation',piRotationMatrix());
    end
    
end

% BW - I recall that Zhenyi pulled this out from here because of speed
% considerations.  At one time it was inside the loop, and that was very
% bad.  I think DJC put it back in, but down here outside the loop.  I am
% not sure that is OK with Zhenyi.  But he hasn't complained.  Maybe we
% should have a flag to not run this, and then the user can run it when
% ready?
thisR.assets = thisR.assets.uniqueNames;

end
