function [ ] = outputsCreateMatlab()
%createMatlabOutputs.m
%Carolyn Voter
%April 2018

%Script that converts PF *.pfb files to Matlab cell arrays using HTC.
%Assumes this executable is in the same directory as extracted *.pfb files
%and domainInfo.mat file.
%Assumes runname, flux, and totalHrs are environment variables.

%Be sure to add these lines to CHTC executable (run_foo.sh)
%Just before "eval" line:
% # Unique to MATcreate
%  set -- $args
%  export runname=`echo $1 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%  export flux=`echo $2 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%  export totalHr=`echo $3 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%  GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
%  cp $GHOME/$flux.tar.gz .
%  tar xzf $flux.tar.gz --strip-components=1
%  rm $flux.tar.gz
%  cp $GHOME/MATin.tar.gz .
%  tar xzf MATin.tar.gz --strip-components=1
%  rm MATin.tar.gz
%Just after "eval" line:
%  # Clean up
%  mv $flux.*.mat $GHOME/
%  rm -f *.pfb *.mat

%% 0. ESTABLISH DIRECTORIES AND FILES INVOLVED
% Environment variables
runname = getenv('runname');
flux = getenv('flux');
totalHr = getenv('totalHr');

%Input pfb files (flux)
files = dir('*.pfb'); %creates structure with file info for all *.pfb files in current directory
nFiles = length(files(:,1));

%Input matlab files (domainInfo, precip)
load('domainInfo.mat');

%Output matlab files
savename1=strcat(flux,'.grid.step.mat'); %data; Individual cell flux/dump interval
savename2=strcat(flux,'.total.step.mat'); %dataT; Total domain flux/dump interval
savename3=strcat(flux,'.grid.cum.mat'); %dataC; Cumulative individual cell flux/dump interval

%% 1. GET GRIDDED HOURLY FLUXES
% Get matrices
for i=1:nFiles
    %Raw data
    filename = files(i).name;
    data{i} = pfbTOmatrix(filename); %L[=]m, T[=]hr
    
    %As needed: squeeze 3D matrix to 2D, convert units
    if (strcmp(flux,'clm_output') == 1) %CLM fluxes
        %qflx_evap_grnd, convert mm/s to m^3/hr
        data01{i} = squeeze(data{i}(:,:,6))*dx*dy*3600/1000;
        %qflx_evap_veg, convert mm/s to m^3/hr
        data02{i} = squeeze(data{i}(:,:,8))*dx*dy*3600/1000; 
        %qflx_tran_veg, convert mm/s to m^3/hr
        data03{i} = squeeze(data{i}(:,:,9))*dx*dy*3600/1000;
        %swe_out, convert mm to m^3
        data04{i} = squeeze(data{i}(:,:,11))*dx*dy/1000;
        %can_out, convert mm to m^3
        data05{i} = squeeze(data{i}(:,:,12))*dx*dy/1000;
    elseif (strcmp(flux,'overlandsum') == 1)
        %surface runoff, m^3/hr
        data{i} = squeeze(data{i}(:,:,1));
    elseif (strcmp(flux,'evaptranssum') == 1)
        %Values only in top 10 layers (#CLM layers), m^3/hr
        data{i} = data{i}(:,:,(nz-9):nz); 
    end
    
end

% Save data
if (strcmp(flux,'clm_output') == 1) %CLM fluxes
    clear data;
    data = data01; save('qflx_evap_grnd.grid.step.mat','data','-v7.3'); clear data;
    data = data02; save('qflx_evap_veg.grid.step.mat','data','-v7.3'); clear data;
    data = data03; save('qflx_tran_veg.grid.step.mat','data','-v7.3'); clear data;
    data = data04; save('swe_out.grid.step.mat','data','-v7.3'); clear data;
    data = data05; save('can_out.grid.step.mat','data','-v7.3'); clear data;
else %non-CLM fluxes
    save(savename1,'data','-v7.3');
end
%% 2. GET SUMMED HOURLY FLUXES (domain total)
if (strcmp(flux,'satur') ~= 1) && (strcmp(flux,'press') ~= 1)
    if (strcmp(flux,'clm_output') == 1) %CLM fluxes
        for i=1:length(data01)
            dataT01(i,1) = sum(sum(sum(data01{i})));
            dataT02(i,1) = sum(sum(sum(data02{i})));
            dataT03(i,1) = sum(sum(sum(data03{i})));
            dataT04(i,1) = sum(sum(sum(data04{i})));
            dataT05(i,1) = sum(sum(sum(data05{i})));
        end
        dataT = dataT01; save('qflx_evap_grnd.total.step.mat','dataT','-v7.3'); clear dataT;
        dataT = dataT02; save('qflx_evap_veg.total.step.mat','dataT','-v7.3'); clear dataT;
        dataT = dataT03; save('qflx_tran_veg.total.step.mat','dataT','-v7.3'); clear dataT;
        dataT = dataT04; save('swe_out.total.step.mat','dataT','-v7.3'); clear dataT;
        dataT = dataT05; save('can_out.total.step.mat','dataT','-v7.3'); clear dataT;
    else %non-CLM fluxes
        for i=1:length(data)
            dataT(i,1) = sum(sum(sum(data{i})));
        end
        save(savename2,'dataT','-v7.3');
    end
end

%% 3. GET GRIDDED CUMULATIVE FLUXES
if (strcmp(flux,'satur') ~= 1) && (strcmp(flux,'press') ~= 1) && ...
        (strcmp(flux,'subsurface_storage') ~= 1) && ...
        (strcmp(flux,'surface_storage') ~= 1)
    if (strcmp(flux,'clm_output') == 1) %CLM fluxes
        dataSize = size(data01{1});
        dataC01 = zeros(dataSize);
        dataC02 = zeros(dataSize);
        dataC03 = zeros(dataSize);
        for i=1:length(data01)
            dataC01 = dataC01+data01{i};
            dataC02 = dataC02+data02{i};
            dataC03 = dataC03+data03{i};
        end
        dataC = dataC01; save('qflx_evap_grnd.grid.cum.mat','dataC','-v7.3'); clear dataC;
        dataC = dataC02; save('qflx_evap_veg.grid.cum.mat','dataC','-v7.3'); clear dataC;
        dataC = dataC03; save('qflx_tran_veg.grid.cum.mat','dataC','-v7.3'); clear dataC;
    else %non-CLM fluxes
        dataSize = size(data{1});
        dataC = zeros(dataSize);
        for i=1:length(data)
            dataC = dataC+data{i};
        end
        save(savename3,'dataC','-v7.3');
    end
end

end
        