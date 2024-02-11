%% Illustrates how to configure Matlab prefs for different remote computers
%
% There is now a method in dockerWrapper called 'preset' that automates
% this process.
%

doc dockerWrapper.preset

%
% These three slots are enough for now.
%
% We should be able to make this just one slot, probably the first one
% though maybe the first one and which GPU?
%

% For mux
%{
  setpref('docker','remoteMachine','muxreconrt.stanford.edu');
  setpref('docker','renderContext','remote-mux');
  setpref('docker','remoteImage','digitalprodev/pbrt-v4-gpu-ampere-mux');
  dockerWrapper.reset;
  thisD = dockerWrapper;
  thisD.getPrefs
%}

% For orange
%{

  setpref('docker','remoteMachine','orange.stanford.edu');
  setpref('docker','renderContext','remote-orange');
  setpref('docker','remoteImage','digitalprodev/pbrt-v4-gpu-ampere-ti');
  dockerWrapper.reset;
  thisD = dockerWrapper;
  thisD.getPrefs
%}


v_iset3d_v4;
