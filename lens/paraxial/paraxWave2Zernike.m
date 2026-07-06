% Convert Wavefront Coeffs to Zernike Coeffs
%Data from "Mahajan, Virendra N. "Optical Imaging and Aberrations: Part 1. Ray Geometrical Optics." Bellingham: SPIE, 1998."
%CHAPTER 3- par 171


function [ZernikeCoeff]=paraxWave2Zernike(waveCoeff)

%INPUT
%waveCoeff: this coeffs has to be adapted to real field height [.W40;.W31;.W22;.W20;.W11]

%OUTPUT
%ZernikeCoeff: struct with several term





%% INITIALIZE WEIGHT
%ZERNIKE COEFF indices
Z_n=[0,1,2,2,3,3,4,4,4,5,5,5,6,6,6,6,7,7,7,7,8];
Z_m=[0,1,0,2,1,3,0,2,4,1,3,5,0,2,4,6,1,3,5,7,0];
Z_nm(1,:)=Z_n;Z_nm(2,:)=Z_m;

%WAVEFRONT COEFF indices
a_kl(1,:)=Z_n;a_kl(2,:)=Z_m;

%num coeff
ncoeff=size(a_kl,2);

for wi=1:ncoeff
    wM(:,wi)=zeros(size(Z_nm,2),1);
    switch wi
        case 1
            wM(1,wi)=1;
        case 2
            wM(2,wi)=1/2;
        case 3
            wM(1,wi)=1/2;wM(3,wi)=1/(2*sqrt(3));
        case 4
            wM(1,wi)=1/4;wM(3,wi)=1/(4*sqrt(3));
            wM(4,wi)=1/(2*sqrt(6));
        case 5
            wM(2,wi)=1/3;wM(5,wi)=1/(6*sqrt(2));
        case 6 
            wM(2,wi)=1/4;wM(5,wi)=1/(8*sqrt(2));
            wM(6,wi)=1/(8*sqrt(2));
        case 7 
            wM(1,wi)=1/3;wM(3,wi)=1/(2*sqrt(3));
            wM(7,wi)=1/(6*sqrt(5));
        case 8
            wM(1,wi)=1/6;wM(3,wi)=1/(4*sqrt(3));wM(4,wi)=1/8*(sqrt(3/2));
            wM(7,wi)=1/(12*sqrt(5));wM(8,wi)=1/(8*sqrt(10));
        case 9
            wM(1,wi)=1/8;wM(3,wi)=sqrt(3)/16;wM(4,wi)=1/8*(sqrt(3/2));
            wM(7,wi)=1/(16*sqrt(5));wM(8,wi)=1/(8*sqrt(10));wM(9,wi)=1/(8*sqrt(5));
        case 10
            wM(2,wi)=1/4;wM(5,wi)=1/(5*sqrt(2));wM(10,wi)=1/(20*sqrt(3));
        case 11
            wM(2,wi)=3/16;wM(5,wi)=3/(20*sqrt(2));wM(6,wi)=1/(10*sqrt(2));
            wM(10,wi)=sqrt(3)/80;wM(11,wi)=1/(40*sqrt(3));
        case 12
            wM(2,wi)=5/32;wM(5,wi)=1/(8*sqrt(2));wM(6,wi)=1/(8*sqrt(2));
            wM(10,wi)=1/(sqrt(3)*32);wM(11,wi)=1/(sqrt(3)*32);wM(12,wi)=1/(sqrt(3)*32);
        case 13
            wM(1,wi)=1/4;wM(3,wi)=3*sqrt(3)/20;
            wM(7,wi)=1/(4*sqrt(5));wM(13,wi)=1/(20*sqrt(7));
        case 14
            wM(1,wi)=1/8;wM(3,wi)=3*sqrt(3)/40;wM(4,wi)=1/10*sqrt(3/2);
            wM(7,wi)=1/(8*sqrt(5));wM(8,wi)=1/(6*sqrt(10));wM(9,wi)=sqrt(5)/48;
            wM(13,wi)=1/(40*sqrt(7));wM(14,wi)=1/(30*sqrt(14));
        case 15
            wM(1,wi)=3/32;wM(3,wi)=9*sqrt(3)/160;wM(4,wi)=1/10*sqrt(3/2);
            wM(7,wi)=3/(32*sqrt(5));wM(8,wi)=1/(6*sqrt(10));wM(9,wi)=sqrt(5)/32;
            wM(13,wi)=1/(160*sqrt(7));wM(14,wi)=1/(30*sqrt(14));wM(15,wi)=1/(40*sqrt(14));
        case 16 
            wM(1,wi)=5/64;wM(3,wi)=3*sqrt(3)/64;wM(4,wi)=3/32*sqrt(3/2);
            wM(7,wi)=(sqrt(5)/64);wM(8,wi)=1/32*sqrt(5/2);
            wM(13,wi)=1/(64*sqrt(7));wM(14,wi)=1/(32*sqrt(14));wM(15,wi)=1/(32*sqrt(14));
            wM(16,wi)=1/(32*sqrt(14));
        case 17 
            wM(2,wi)=1/5;wM(5,wi)=1/(5*sqrt(2));wM(10,wi)=sqrt(5)/35;
            wM(17,wi)=1/140;
        case 18
            wM(2,wi)=3/20;wM(5,wi)=3/(20*sqrt(2));wM(6,wi)=1/(12*sqrt(2));
            wM(10,wi)=3*sqrt(3)/140;wM(11,wi)=5/(140*sqrt(3));
            wM(17,wi)=3/560;wM(18,wi)=1/336;
        case 19
            wM(2,wi)=1/8;wM(5,wi)=1/(8*sqrt(2));wM(6,wi)=5/(48*sqrt(2));
            wM(10,wi)=sqrt(3)/56;wM(11,wi)=5/(112*sqrt(3));wM(12,wi)=sqrt(3)/112;
            wM(17,wi)=1/224;wM(18,wi)=5/1344;wM(19,wi)=1/448;
        case 20
            wM(2,wi)=7/64;wM(5,wi)=7/(64*sqrt(2));wM(6,wi)=7/(64*sqrt(2));
            wM(10,wi)=sqrt(3)/64;wM(11,wi)=sqrt(3)/64;wM(12,wi)=sqrt(3)/64;
            wM(17,wi)=1/256;wM(18,wi)=1/256;wM(19,wi)=1/256;wM(20,wi)=1/256;
        case 21
            wM(1,wi)=1/5;wM(3,wi)=2/(5*sqrt(3));
            wM(7,wi)=2/(7*sqrt(5));wM(13,wi)=1/(10*sqrt(7));
            wM(20,wi)=1/210;
        otherwise
            error('Only 21 term has ben already implemented!!')     
                  
    end
end


%% COMPUTE ZERNIKE coeffs

fnames=fieldnames(waveCoeff);
nfname=length(fnames);

dummy=getfield(waveCoeff,fnames{1});
%number of wavelengths
nw=size(dummy,1);

Z_coeff=zeros(ncoeff,nfname,nw);


for li=1:nw %for each wavelength
    for ci=1:nfname  %for each wavef. coeffs   
         wCoeff=getfield(waveCoeff,fnames{ci}); %get value from wavefront coeff
         k_coeff=str2num(fnames{ci}(2)); %k index
        l_coeff=str2num(fnames{ci}(3)); %l index
        for wi=1:ncoeff %Find weight for zernike coeffs for the given wavef. coeff
            if (k_coeff==a_kl(1,wi))&&(l_coeff==a_kl(2,wi))
                weight=wM(:,wi);
                Zc(:,wi)=weight.*wCoeff(li,1);
            end
        end        
    end  
    Zcoeff(:,li)=sum(Zc,2);
end


%% CREATE  OUTPUT and APPEND VALUEs to ZERNIKE STRUCTURE

ZernikeCoeff=struct('C00',[],'C11',[],'C20',[],'C22',[],'C31',[],...
    'C33',[],'C40',[],'C42',[],'C44',[],'C51',[],'C53',[],'C55',[],...
    'C60',[],'C62',[],'C64',[],'C66',[],'C71',[],'C73',[],'C75',[],...
    'C77',[],'C80',[]);
nZc=size(Zcoeff,1);

Zfnames=fieldnames(ZernikeCoeff);
for zi=1:nZc    
    ZernikeCoeff=setfield(ZernikeCoeff,Zfnames{zi},Zcoeff(zi,:)'); %Set the specific Zernike Coeff
end

% for ci=1:nframe
%     wCoeff=getfield(waveCoeff,fnames{ci}); %get value from wavefront coeff
%     %Get indices
%     k_coeff=str2num(fnames{ci}(2)); %k index
%     l_coeff=str2num(fnames{ci}(3)); %l index
%     for wi=1:ncoeff
%         if (k_coeff==a_kl(1,wi))&&(l_coeff==a_kl(2,wi))
%             for li=1:nw
%                 Z_coeff(:,ci,li)=wCoeff(li,1).*wM(:,wi);% Add the contribute of the Wavefront Coeff to each Zernike Coeff
%             end
%         end
%     end
% end
% 
% for wi=1:ncoeff
%     A=Z_coeff(wi,:,:);
%     Zc(:,wi)=sum(A,1);
% end

    

