function [ ] = outputsWaterBalanceMatlab()
%outputsWaterBalanceMatlab.m
%Carolyn Voter
%April 2018

% This script evaluates the water balance for a given PF run.

% Be sure to add these lines to CHTC executable (run_foo.sh)
% Replace everything below the end of the while loop with:
%  # Unique to WBcalcs
%   set -- $args
%   export runname=`echo $1 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
%   GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
%   cp $GHOME/MATin.tar.gz .
%   tar xzf MATin.tar.gz --strip-components=1
%   rm MATin.tar.gz
%   cp $GHOME/*.total.step.mat .
%   eval "\"${exe_dir}/outputsWaterBalanceMatlab\""
%   mv WB*.mat $GHOME/
%   rm $GHOME/MATin.tar.gz
%   rm $GHOME/qflx_evap_grnd.*.mat
%   rm $GHOME/qflx_evap_veg.*.mat
%   rm $GHOME/qflx_evap_leaf.*.mat
%   rm -f *.mat
% fi
% exit

%% 0. ESTABLISH DIRECTORIES AND FILES INVOLVED
%Input matlab files (domainInfo, precip)
load('domainInfo.mat');
load('precip.mat'); %[m/DumpInterval]

%% 2) WATER BALANCE
% DOMAIN FLUXES per hour (assumes dump interval = 1hr)
% INFLOW
precip_step = 1000*precip; %[mm/hr]
% INTERNAL FLUX
load('evaptranssum.total.step.mat'); etS_step = 1000*dataT/domainArea; clear dataT; %[mm/hr]
% OUTFLOW
load('overlandsum.total.step.mat'); sr_step = 1000*dataT/domainArea; clear dataT; %[mm/hr]
load('qflx_evap_all.total.step.mat'); ev_step = 1000*dataT/domainArea; clear dataT; %[mm/hr]
load('qflx_tran_veg.total.step.mat'); tr_step = 1000*dataT/domainArea; clear dataT; %[mm/hr]
load('recharge.total.step.mat'); re_step = 1000*dataT/domainArea; clear dataT; %[mm/hr]
% STORAGE
load('can_out.total.step.mat'); can = 1000*dataT/domainArea; clear dataT; %[mm]
load('swe_out.total.step.mat'); sno = 1000*dataT/domainArea; clear dataT; %[mm]
load('surface_storage.total.step.mat'); Ss_step = 1000*dataT/domainArea; clear dataT; %[mm]
load('subsurface_storage.total.step.mat'); Sss_step = 1000*dataT/domainArea; clear dataT; %[mm]
% EXTRAS
load(strcat('deep_drainage.total.step.mat')); dd_step = dataT/domainArea; clear dataT; %[mm/hr]

nt = length(Ss_step); totalHr = nt-1;
can_step = zeros(nt,1); can_step(2:nt,1) = can;
sno_step = zeros(nt,1); sno_step(2:nt,1) = sno;
for i=2:nt
    dSs_step(i-1,1) = (Ss_step(i)-Ss_step(i-1));    %[mm/hr]
    dSss_step(i-1,1) = (Sss_step(i)-Sss_step(i-1)); %[mm/hr]
    dcan_step(i-1,1) = (can_step(i)-can_step(i-1)); %[mm/hr]
    dsno_step(i-1,1) = (sno_step(i)-sno_step(i-1)); %[mm/hr]
end

precip_step = precip_step(1:totalHr);

% DOMAIN FLUXES cumulative
for i = 1:totalHr
        precip_cum(i,1) = sum(precip_step(1:i));
        etS_cum(i,1) = sum(etS_step(1:i));
        ev_cum(i,1) = sum(ev_step(1:i));
        tr_cum(i,1) = sum(tr_step(1:i));
        sr_cum(i,1) = sum(sr_step(1:i));
        re_cum(i,1) = sum(re_step(1:i));
        dSss_cum(i,1) = Sss_step(i+1)-Sss_step(1);
        dSs_cum(i,1) = Ss_step(i+1)-Ss_step(1);
        dcan_cum(i,1) = can_step(i+1);
        dsno_cum(i,1) = sno_step(i+1);
        dd_cum(i,1) = sum(dd_step(1:i));
end

% BALANCE per step
CLMforce_step = precip_step;
CLMcalc_step = dcan_step + dsno_step + ev_step + tr_step + etS_step;
CLMabsErr_step = CLMforce_step-CLMcalc_step;
CLMrelErr_step = CLMabsErr_step./CLMforce_step;

PFforce_step = etS_step;
PFcalc_step = dSss_step + dSs_step + sr_step + re_step;
PFabsErr_step = PFforce_step-PFcalc_step;
PFrelErr_step = PFabsErr_step./PFforce_step;

force_step = precip_step;
calc_step = dcan_step + dsno_step + dSss_step + dSs_step + ev_step + tr_step + sr_step + re_step;
absErr_step = force_step-calc_step;
relErr_step = absErr_step./force_step;

% BALANCE cumulative
CLMforce_cum = precip_cum;
CLMcalc_cum = dcan_cum + dsno_cum + ev_cum + tr_cum + etS_cum;
CLMabsErr_cum = CLMforce_cum-CLMcalc_cum;
CLMrelErr_cum = CLMabsErr_cum./CLMforce_cum;

PFforce_cum = etS_cum;
PFcalc_cum = dSss_cum + dSs_cum + sr_cum + re_cum;
PFabsErr_cum = PFforce_cum-PFcalc_cum;
PFrelErr_cum = PFabsErr_cum./PFforce_cum;

force_cum = precip_cum;
calc_cum = dcan_cum + dsno_cum + dSss_cum + dSs_cum + ev_cum + tr_cum + sr_cum + re_cum;
absErr_cum = force_cum-calc_cum;
relErr_cum = absErr_cum./force_cum;

%% 3) SAVE RESULTS
save('WBstep.mat','precip_step','dcan_step','dsno_step',...
    'dSss_step','dSs_step','ev_step','tr_step','sr_step','re_step','etS_step','dd_step','CLMforce_step',...
    'CLMcalc_step','CLMabsErr_step','CLMrelErr_step','PFforce_step','PFcalc_step','PFabsErr_step',...
    'PFrelErr_step','force_step','calc_step','absErr_step','relErr_step','domainArea','-v7.3');
save('WBcum.mat','precip_cum','dcan_cum','dsno_cum',...
    'dSss_cum','dSs_cum','ev_cum','tr_cum','sr_cum','re_cum','etS_cum','dd_cum','CLMforce_cum',...
    'CLMcalc_cum','CLMabsErr_cum','CLMrelErr_cum','PFforce_cum','PFcalc_cum','PFabsErr_cum',...
    'PFrelErr_cum','force_cum','calc_cum','absErr_cum','relErr_cum','domainArea','-v7.3');

end