

function [out]=drawPupil(obj,wave0,wave,textFlag)

% DRAW the Pupils of the Imaging System
%
%function [out]=drawPupil(obj,wave0,wave,textFlag)
%
% INPUT
% EnP: Entrance Pupil   .zpos  (optical axis position)
                      % .diam   (diameter)
% ExP: Exit Pupil   .zpos  (optical axis position)
                      % .diam   (diameter)
% wave0: specify the wavelength to plot
% wave: set of all possible wavelength
% textFlag: flag to include or not the label of the 'entrance' and 'exit
% pupil'
%                  
%OUTPUT
%out: 0 or 1
%
% MP Vistasoft 2014


%% Get Pupil

EnP=obj.bbmGetValue('entrancepupil');
ExP=obj.bbmGetValue('exitpupil');

%% Plot parameters
n_sam=100; % num samples

lColor_ExP='m'; %color of the line for Exit Pupil
lWidth=2; %lone width
fontSize=10; %Font Size

overDiam=[EnP.diam,ExP.diam];
maxDim=2*max(max(overDiam)); %twice the max pupil diameter

%% CHECK if wavelength matches

% wave0=550; %nm   select a wavelengt
indW=find(wave==wave0);

if isempty(indW)
    error(['Not valid matching between wavelength ',wave0,' among ',wave])
end

%% DRAW: Entrace Pupil
if not(isempty(EnP))
    lColor_EnP='r'; %color of the line for Entrance Pupil
    % Upper section    
    enp_Zup=linspace(EnP.zpos(indW),EnP.zpos(indW),n_sam);
    enp_Yup=linspace(EnP.diam(indW),maxDim,n_sam)/2;
    line('xData',enp_Zup, 'yData',enp_Yup,...
    'color',lColor_EnP,'linewidth',lWidth);
    % Lower section    
    enp_Zlo=enp_Zup;
    enp_Ylo=linspace(-EnP.diam(indW),-maxDim,n_sam)/2;
    line('xData',enp_Zlo, 'yData',enp_Ylo,...
            'color',lColor_EnP,'linewidth',lWidth);
     if textFlag=='true'
        text(enp_Zup(1),maxDim/2.2,...
        'EntrancePupil \rightarrow','FontSize',10,'HorizontalAlignment','right')        
     end
    out(1)=1;
end

%% DRAW: Exit Pupil
if not(isempty(EnP))
    lColor_ExP='m'; %color of the line for Exit Pupil
    % Upper section    
    exp_Zup=linspace(ExP.zpos(indW),ExP.zpos(indW),n_sam);
    exp_Yup=linspace(ExP.diam(indW),maxDim,n_sam)/2;
    line('xData',exp_Zup, 'yData',exp_Yup,...
            'color',lColor_ExP,'linewidth',lWidth);
    % Lower section    
    exp_Zlo=exp_Zup;
    exp_Ylo=linspace(-ExP.diam(indW),-maxDim,n_sam)/2;
    line('xData',exp_Zlo, 'yData',exp_Ylo,...
            'color',lColor_ExP,'linewidth',lWidth);
     if textFlag=='true'
        text(exp_Zup(1),maxDim/3,...
        '\leftarrow ExitPupil ','FontSize',10,'HorizontalAlignment','left')         
     end
    out(2)=1;
end

