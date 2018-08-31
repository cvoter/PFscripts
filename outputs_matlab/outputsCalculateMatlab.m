function [ ] = outputsCalculateMatlab()
%outputsCalculateMatlab.m
%Carolyn Voter
%April 2018

% Calculates additional matricies from original pfb to matrix conversions.
% Assumes all *.mat files are located in GHOME directory, a specified
% environment variable. Assumes runname, flux, and totalHrs are also
% environment variables.

% Be sure to add these lines to CHTC executable (run_foo.sh)
% Replace everything below the end of the while loop with:
% # Unique to MATcalc
%   set -- $args
%   export runname=`echo $1 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%   export flux=`echo $2 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%   export totalHr=`echo $3 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%   export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
%   cp $GHOME/MATin.tar.gz .
%   tar xzf MATin.tar.gz --strip-components=1
%   rm MATin.tar.gz
%   eval "\"${exe_dir}/outputsCalculateMatlab\""
%   # Clean up
%   mv ${flux}.*.mat $GHOME/
%   rm -f *.mat
% fi
% exit

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
    load(strcat(GHOME,'/subsurface_parameters.mat'));
    zLow = find(z < z(nz)-1,1,'last'); %index for layer just below 1m depth
    dataC = zeros([ny nx]);
    for t = 1:(length(p)-1)
        pBelow = p{t+1}(:,:,zLow); %[m] Pressure in layer just below 1m depth
        pAbove = p{t+1}(:,:,(zLow-1)); %[m] Pressure in layer just above 1m depth
        zBelow = z(zLow); zAbove = z(zLow-1); %[m] Elevations at each point
        pBelow(pBelow > 0) = 0;
        pAbove(pAbove > 0) = 0;
        for i = 1:ny
            for j=1:nx
                if ((pAbove(i,j)+pBelow(i,j))-(zAbove-zBelow))<0
                    thisPress=abs(pBelow(i,j));
                else
                    thisPress=abs(pAbove(i,j));
                end
                Se=((1/(1+(VGalpha(i,j,zLow)*thisPress)^VGn(i,j,zLow)))^VGm(i,j,zLow));
                Kr(i,j)=(Se^(1/2))*((1-(1-Se^(1/VGm(i,j,zLow)))^VGm(i,j,zLow))^2);
                K(i,j)=perm_z(i,j,zLow)*Kr(i,j);
            end
        end
        data{t} = dx*dy*(K + K.*(pBelow-pAbove)./(zBelow-zAbove)); %[m^3/hr]
        dataT(t,1) = sum(sum(data{t}));
        dataC = dataC+data{t};
    end

%1.4. RECHARGE AT MODEL BASE
elseif strcmp(flux,'recharge') == 1 
    load(strcat(GHOME,'/press.grid.step.mat')); p = data; clear data;
    load(strcat(GHOME,'/subsurface_parameters.mat'));
    dataC = zeros([ny nx]);
    for t = 1:(length(p)-1)
        pBelow = zeros([ny nx]); %[m] Pressure hypothetical layer at base of domain
        pAbove = p{t+1}(:,:,1); %[m] Pressure in last domain layer
        zBelow = 0; zAbove = z(1); %[m] Relative elevations at each point
        pBelow(pBelow > 0) = 0;
        pAbove(pAbove > 0) = 0;
        for i = 1:ny
            for j=1:nx
                thisPress=abs(pAbove(i,j));
                Se=((1/(1+(VGalpha(i,j,1)*thisPress)^VGn(i,j,1)))^VGm(i,j,1));
                Kr(i,j)=(Se^(1/2))*((1-(1-Se^(1/VGm(i,j,1)))^VGm(i,j,1))^2);
                K(i,j)=perm_z(i,j,1)*Kr(i,j);
            end
        end
        data{t} = dx*dy*(K + K.*(pBelow-pAbove)./(zBelow-zAbove)); %[m^3/hr]
        dataT(t,1) = sum(sum(data{t}));
        dataC = dataC+data{t};
    end
%1.5. SUBSURFACE STORAGE
% Assumes zL = 0
elseif strcmp(flux,'subsurface_storage') == 1
    load(strcat(GHOME,'/satur.grid.step.mat')); sat = data; clear data;
    load(strcat(GHOME,'/press.grid.step.mat')); p = data; clear data;
    load(strcat(GHOME,'/subsurface_parameters.mat'));
    dz = dz*dz_mult;
    for t = 1:length(sat)
        thisSat = sat{t};
        thisPress = p{t};
        for k = 1:length(z)
            thisSubStorage(:,:,k) = thisSat(:,:,k).*dx.*dy.*dz(:,:,k).*(specific_storage(:,:,k).*thisPress(:,:,k) + porosity(:,:,k));
        end
        data{t} = thisSubStorage;
        dataT(t,1) = sum(sum(sum(data{t})));
    end
    
%1.6. SURFACE STORAGE
elseif strcmp(flux,'surface_storage') == 1
    load(strcat(GHOME,'/press.grid.step.mat')); p = data; clear data;
    for t = 1:length(p)
        thisPress = p{t};
        surfacePress = thisPress(:,:,end);
        surfacePress(surfacePress < 0) = 0;
        data{t} = surfacePress*dx*dy;
        dataT(t,1) = sum(sum(data{t}));
    end
end

%% 2. SAVE NEW FLUX
save(savename1,'data','-v7.3');
save(savename2,'dataT','-v7.3');
save(savename3,'dataC','-v7.3');

end
        