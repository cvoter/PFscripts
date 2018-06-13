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
for i=1:nFiles
    %Raw data
    filename = files(i).name;
    data{i} = pfbTOmatrix(filename); %L[=]m, T[=]hr
    
    %As needed: squeeze 3D matrix to 2D, convert units
    if (strcmp(flux,'qflx_evap_grnd') == 1) || (strcmp(flux,'qflx_evap_veg') == 1) ||...
            (strcmp(flux,'qflx_tran_veg') == 1) %CLM flux
        data{i} = squeeze(data{i}(:,:,1))*dx*dy*3600/1000; %convert mm/s to m^3/hr
    elseif (strcmp(flux,'can_out') == 1) || (strcmp(flux,'swe_out') == 1) %CLM depth
        data{i} = squeeze(data{i}(:,:,1))*dx*dy/1000; %convert mm to m^3
    elseif (strcmp(flux,'overlandsum') == 1) %surface runoff, m^3/hr
        data{i} = squeeze(data{i}(:,:,1));
    elseif (strcmp(flux,'evaptranssum') == 1)
        data{i} = data{i}(:,:,(nz-9):nz); %Values only in top 10 layers (#CLM layers), m^3/hr
    end
    
end
save(savename1,'data','-v7.3');

%% 2. GET SUMMED HOURLY FLUXES (domain total)
if (strcmp(flux,'satur') ~= 1) && (strcmp(flux,'press') ~= 1)
    for i=1:length(data)
        dataT(i,1) = sum(sum(sum(data{i})));
    end
    save(savename2,'dataT','-v7.3');
end

%% 3. GET GRIDDED CUMULATIVE FLUXES
if (strcmp(flux,'satur') ~= 1) && (strcmp(flux,'press') ~= 1) && ...
        (strcmp(flux,'subsurface_storage') ~= 1) && ...
        (strcmp(flux,'surface_storage') ~= 1)
    dataSize = size(data{1});
    dataC = zeros(dataSize);
    for i=1:length(data)
        dataC = dataC+data{i};
    end
    save(savename3,'dataC','-v7.3');
end

end
        