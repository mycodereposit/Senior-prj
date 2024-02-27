clear; clc;

dataset_detail = readtable('batch_dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;

options = optimoptions('intlinprog','MaxTime',40);

%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (unit: day)
PARAM.Resolution = 15; %sampling period (unit: min) use multiple of 15:int 

%change unit
PARAM.Resolution = PARAM.Resolution/60; %sampling period(Hr)
% end of change unit

%TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
PARAM.TOU_CHOICE = 'THcurrent' ;
PARAM.PV_capacity = 66; % (kW) PV sizing for this EMS
%end of ----- parameter ----

[PARAM.Buy_rate,PARAM.Sell_rate] = getBuySellrate(1/PARAM.Resolution,PARAM.Horizon,PARAM.TOU_CHOICE);

%--- system parameter ----
num_batt = 2;  % input number of bettery
batt_actual_cap2 = 125; % battery actual capacity (per each) when use 2 batteries
batt_actual_cap1 = 2*batt_actual_cap2;   % battery actual capacity (per each) when use only 1 battery
with_sc = 'yes';
PARAM.battery.num_batt = num_batt;

switch num_batt
    case 1 % scenario 1 battery
    PARAM.battery.charge_effiency = [0.95]; %bes charge eff
    PARAM.battery.discharge_effiency = [0.95*0.93]; %  bes discharge eff note inverter eff 0.93-0.96
    PARAM.battery.discharge_rate = [60]; % kW max discharge rate
    PARAM.battery.charge_rate = [60]; % kW max charge rate
    PARAM.battery.actual_capacity = [batt_actual_cap1]; % kWh soc_capacity 
    PARAM.battery.initial = [50]; % userdefined int 0-100 %
    PARAM.battery.min = [20]; %min soc userdefined int 0-100 %
    PARAM.battery.max = [80]; %max soc userdefined int 0-100 %
    %end of 1 batt

    case 2 % scenario 2 batteries
    PARAM.battery.charge_effiency = [0.95 0.95]; %bes charge eff
    PARAM.battery.discharge_effiency = [0.95*0.93 0.95*0.93]; %  bes discharge eff note inverter eff 0.93-0.96
    PARAM.battery.discharge_rate = [30 30]; % kW max discharge rate
    PARAM.battery.charge_rate = [30 30]; % kW max charge rate
    PARAM.battery.actual_capacity = [batt_actual_cap2 batt_actual_cap2]; % kWh soc_capacity
    PARAM.battery.initial = [20 20]; % userdefined int 0-100 %
    PARAM.battery.min = [20 20]; %min soc userdefined int 0-100 %
    PARAM.battery.max = [80 80]; %max soc userdefined int 0-100 %
    %end of 2 batt
end
    
%end of ----- system parameter ----

for i = 1:length(dataset_name)
    % get solar/load profile and buy/sell rate
    [PARAM.PV,PARAM.PL] = loadPVandPLcsv(PARAM.Resolution,dataset_name{i},PARAM.PV_capacity);
    
    sol = EMS1_opt(PARAM,dataset_name{i},0,'a');

    switch PARAM.battery.num_batt
        case 1
        save(strcat('solution/EMS1/pv',num2str(PARAM.PV_capacity), 'kW_batt', ...
            num2str(batt_actual_cap2),'kWh/', num2str(num_batt),'batt/', ...
            PARAM.TOU_CHOICE,'_',dataset_name{i},'.mat'), '-struct','sol')
        case 2
            switch with_sc
                case 'no'
                save(strcat('solution/EMS1/pv',num2str(PARAM.PV_capacity), 'kW_batt', ...
                    num2str(batt_actual_cap2),'kWh/', num2str(num_batt),'batt/', ...
                    'without_sc/', PARAM.TOU_CHOICE,'_',dataset_name{i},'.mat'), '-struct','sol')
                case 'yes'
                    save(strcat('solution/EMS1/pv',num2str(PARAM.PV_capacity), 'kW_batt', ...
                    num2str(batt_actual_cap2),'kWh/', num2str(num_batt),'batt/', ...
                     PARAM.TOU_CHOICE,'_',dataset_name{i},'.mat'), '-struct','sol')
            end
    end
    
end
