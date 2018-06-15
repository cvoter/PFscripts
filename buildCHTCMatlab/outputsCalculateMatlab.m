function [ ] = outputsCalculateMatlab()
%outputsCalculateMatlab.m
%Carolyn Voter
%April 2018

%Calculates additional matricies from original pfb to matrix conversions.
%Assumes all *.mat files are located in GHOME directory, a specified
%environment variable. Assumes runname, flux, and totalHrs are also
%environment variables.

%Be sure to add these lines to CHTC executable (run_foo.sh)
%Just before "eval" line:
% # Unique to MATcreate
%  set -- $args
%  export runname=`echo $1 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%  export flux=`echo $2 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%  export totalHr=`echo $3 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%  export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
%  cp $GHOME/MATin.tar.gz .
%  tar xzf MATin.tar.gz --strip-components=1
%  rm MATin.tar.gz
%Just after "eval" line:
%  # Clean up
%  mv $flux.*.mat $GHOME/
%  rm -f *.mat
%% 0. ESTABLISH DIRECTORIES AND FILES INVOLVED
% Environment variables
runname = getenv('runname');
flux = getenv('flux');
totalHr = getenv('totalHr');
GHOME = getenv('GHOME');

%Input matlab files (domainInfo, precip)
load('domainInfo.mat');

%Output matlab files
savename1=strcat(flux,'.grid.step.mat'); %data; Individual cell flux/dump interval
savename2=strcat(flux,'.total.step.mat'); %dataT; Total domain flux/dump interval
savename3=strcat(flux,'.grid.cum.mat'); %dataC; Cumulative individual cell flux/dump interval

%% 1. CALCULATE NEW FLUX
%1.1. LEAF EVAPORATION
if strcmp(flux,'qflx_evap_leaf') == 1
    %Load data, dataT, and dataC
    load(strcat(GHOME,'/qflx_evap_veg.grid.step.mat')); evV = data; clear data;
    load(strcat(GHOME,'/qflx_evap_veg.total.step.mat')); evVS = dataT; clear dataT;
    load(strcat(GHOME,'/qflx_evap_veg.grid.cum.mat')); evVC = dataC; clear dataC;
    load(strcat(GHOME,'/qflx_tran_veg.grid.step.mat')); tr = data; clear data;
    load(strcat(GHOME,'/qflx_tran_veg.total.step.mat')); trS = dataT; clear dataT;
    load(strcat(GHOME,'/qflx_tran_veg.grid.cum.mat')); trC = dataC; clear dataC;
    %Calculate new data, dataT, and dataC
    for i = 1:length(evV)
        data{i} = evV{i} - tr{i};
        dataT(i,1) = evVS(i) - trS(i);
    end
    dataC = evVC - trC;
    
%1.2. TOTAL EVAPORATION
elseif strcmp(flux,'qflx_evap_all') == 1
    %Load data, dataT, and dataC
    load(strcat(GHOME,'/qflx_evap_grnd.grid.step.mat')); evG = data; clear data;
    load(strcat(GHOME,'/qflx_evap_grnd.total.step.mat')); evGS = dataT; clear dataT;
    load(strcat(GHOME,'/qflx_evap_grnd.grid.cum.mat')); evGC = dataC; clear dataC;
    load(strcat(GHOME,'/qflx_evap_leaf.grid.step.mat')); evL = data; clear data;
    load(strcat(GHOME,'/qflx_evap_leaf.total.step.mat')); evLS = dataT; clear dataT;
    load(strcat(GHOME,'/qflx_evap_leaf.grid.cum.mat')); evLC = dataC; clear dataC;
    %Calculate new data, dataT, and dataC
    for i = 1:length(evG)
        data{i} = evG{i} + evL{i};
        dataT(i,1) = evGS(i) + evLS(i);
    end
    dataC = evGC + evLC;

%1.3. DEEP DRAINAGE BELOW 1M
elseif strcmp(flux,'deep_drainage') == 1
    load(strcat(GHOME,'/press.grid.step.mat')); p = data; clear data;
    zLow = find(z <(z(nz)+dz/2-1),1,'last'); %index for layer just below 1m depth
    dataC = zeros([ny nx]);
    for t = 1:(length(p)-1)
        p1 = p{t+1}(:,:,zLow); %[m] Pressure in layer just below 1m depth
        p2 = p{t+1}(:,:,(zLow-1)); %[m] Pressure in layer 2 below 1m depth
        z1 = z(zLow); z2 = z(zLow-1); %[m] Elevations at each point
        for i = 1:ny
            for j=1:nx
                if p1(i,j) > 0, p1(i,j)=0;
                end
                if p2(i,j) > 0, p2(i,j)=0;
                end
                if NaNimp(i,j,zLow) == 1
                    Ks = Ks_soil; N = VGn_soil; M = 1-(1/N); A=VGa_soil;
                else Ks = Ks_imperv; N = VGn_imperv; M = 1-(1/N); A=VGa_imperv;
                end
                if ((p2(i,j)+p1(i,j))-(z2-z1))<0
                    P=abs(p1(i,j));
                else P=abs(p2(i,j));
                end
                Se=((1/(1+(A*P)^N))^M);
                Kr(i,j)=(Se^(1/2))*((1-(1-Se^(1/M))^M)^2);
                K(i,j)=Ks*Kr(i,j);
            end
        end
        data{t} = dx*dy*(K + K.*(p1-p2)./(z1-z2)); %[m^3/hr]
        dataT(t,1) = sum(sum(data{t}));
        dataC = dataC+data{t};
    end

%1.4. RECHARGE AT MODEL BASE
elseif strcmp(flux,'recharge') == 1 
    load(strcat(GHOME,'/press.grid.step.mat')); p = data; clear data;
    dataC = zeros([ny nx]);
    for t = 1:(length(p)-1)
        p1 = zeros([ny nx]); %[m] Pressure hypothetical layer below base of domain
        p2 = p{t+1}(:,:,1); %[m] Pressure in last domain layer
        z1 = -dz/2; z2 = 0; %[m] Relative elevations at each point
        for i = 1:ny
            for j=1:nx
                if p1(i,j) > 0, p1(i,j)=0;
                end
                if p2(i,j) > 0, p2(i,j)=0;
                end
                Ks = Ks_soil; N = VGn_soil; M = 1-(1/N); A=VGa_soil;
                P=abs(p2(i,j));
                Se=((1/(1+(A*P)^N))^M);
                Kr(i,j)=(Se^(1/2))*((1-(1-Se^(1/M))^M)^2);
                K(i,j)=Ks*Kr(i,j);
            end
        end
        data{t} = dx*dy*(K + K.*(p1-p2)./(z1-z2)); %[m^3/hr]
        dataT(t,1) = sum(sum(data{t}));
        dataC = dataC+data{t};
    end
end

%% 2. SAVE NEW FLUX
save(savename1,'data','-v7.3');
save(savename2,'dataT','-v7.3');
save(savename3,'dataC','-v7.3');

end
        