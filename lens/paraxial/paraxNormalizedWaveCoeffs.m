%Convert  Wavefront Error coeffs are normalized to the wavlenght [change of unit]: 
%Smith, George. The eye and visual optical instruments. Cambridge University Press, 1997." -Chapter 33- 33.1.2.


function  [Coeff_norm]=paUnit2NumWave(Coeff)

%INPUT
%Coeff: structure with 4th order wavefront coeff
%[.W040,.W131,.W222,.W220,.W.311] ...
... or Seidel coeff [.SI,.SII,.SIII,.SIV,.SV] ...
... or Peak Value coeff [.W40,.W31,.W22,.W20,.W11]


%OUTPUT
%waveCoeff_normalized: structure with wavefront coeff normalized [.W040,.W131,.W222,.W220,.W.311,.W400]



%% GET WAVELENGTH
wave=getfield(waveCoeff,'wave');


%% GET FIELD names of the INPUT
fnames=fieldnames(waveCoeff);

%% COMPUTE WAVEFRONT COEFFs
Coeff_norm=struct;
for si=1:length(fnames)
    switch fnames{si}
    case {'W040';'W131';'W222';'W220';'W311';'SI';'SII';'SIII';'SIV';'SV';'W40';'W31';'W22';'W20';'W11'}
        wX=getfield(waveCoeff,fnames{si});
        for ii=1:size(wX,2)
            wN(:,ii)=wX(:,ii)./wave;
        end
    waveCoeff_normalized=setfield(waveCoeff_normalized,fnames{si},wN);
    case {'unit'}
        waveCoeff=setfield(waveCoeff,'unit','#wave');
    otherwise 
    end

    
    
    %     switch fnames{si}
%         case{'SI';'S1'}
%             SI=getfield(SeidelCoeff,fnames{si});
%             waveCoeff.W040=SI/8;
%         case{'SII';'S2'}
%             SII=getfield(SeidelCoeff,fnames{si});
%             waveCoeff.W131=SII/2;
%         case{'SIII';'S3'}
%             SIII=getfield(SeidelCoeff,fnames{si});
%             waveCoeff.W222=SIII/2;
%         case{'SIV';'S4'}
%             SIV=getfield(SeidelCoeff,fnames{si});
%             if isfield(SeidelCoeff,'SIII')
%                 SIII=getfield(SeidelCoeff,'SIII');
%                 waveCoeff.W220=(SIV+SIII)/4;
%             elseif isfield(SeidelCoeff,'S3')
%                 SIII=getfield(SeidelCoeff,'S3');
%                 waveCoeff.W220=(SIV+SIII)/4;
%             else
%                 warning('For coeff W220 (Field of Curvature) is mandatory also the SIII!!')
%                 waveCoeff.W220=[];
%             end          
%             
%         case{'SV';'S5'}
%             SV=getfield(SeidelCoeff,fnames{si});
%             waveCoeff.W311=SV/2;
%          otherwise
%             warning (['The field ',fnames{si}, 'is unknown!'])
%     end
end