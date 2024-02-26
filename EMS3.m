clear; clc;

%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (day)
PARAM.Resolution = 15; %sampling period(min) use multiple of 15. int 

PARAM.TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
%TOU_CHOICE = 'THcurrent' ;
PARAM.PV_capacity = 16; % (kw) PV sizing for this EMS
%end of ----- parameter ----

name = 'high_load_low_solar_1'; 


%change unit
PARAM.Resolution = PARAM.Resolution/60; %sampling period(Hr)
% end of change unit
% %get solar/load profile and buy/sell rate

[PARAM.PV,PARAM.PL] = loadPVandPLcsv(PARAM.Resolution,name,PARAM.PV_capacity);
[PARAM.Buy_rate,PARAM.Sell_rate] = getBuySellrate(1/PARAM.Resolution,PARAM.Horizon,PARAM.TOU_CHOICE);

%end of solar/load profile and buy/sell rate
%parameter part

%parameter part
%for  2 batt
PARAM.battery.charge_effiency = [0.95 0.95]; %bes charge eff
PARAM.battery.discharge_effiency = [0.95*0.93 0.95*0.93]; %  bes discharge eff note inverter eff 0.93-0.96
PARAM.battery.discharge_rate = [30 30]; % kW max discharge rate
PARAM.battery.charge_rate = [30 30]; % kW max charge rate
PARAM.battery.actual_capacity = [125 125]; % kWh soc_capacity 
PARAM.battery.initial = [50 50]; % userdefined int 0-100 %
PARAM.battery.min = [20 20]; %min soc userdefined int 0-100 %
PARAM.battery.max = [80 80]; %max soc userdefined int 0-100 %
%end of 2 batt
PARAM.battery.deviation_penalty_weight = 0.05; 
PARAM.AClab.encourage_weight = 5; %(THB) weight for encourage lab ac usage
PARAM.ACstudent.encourage_weight = 2; %(THB) weight for encourage student ac usage
PARAM.AClab.Paclab_rate = 3.71*3; % (kw) air conditioner input Power for lab
PARAM.ACstudent.Pacstudent_rate = 1.49*2 + 1.82*2; % (kw) air conditioner input Power for lab
PARAM.Puload = min(PARAM.PL) ;% (kW) power of uncontrollable load
PARAM.battery.num_batt = length(PARAM.battery.actual_capacity);

% end of parameter part



%%
solution_path = 'solution';
sol = EMS3_opt(PARAM,name,1,solution_path);

%%
graph_path = 'graph';
[f,t] = EMS3_plot(sol,1,graph_path);
%%

