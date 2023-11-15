clear; clc;

dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;

options = optimoptions('intlinprog','MaxTime',40);
% high load case : 2023-04-18 - 2023-04-22
% low  load case : 2023-05-26 - 2023-05-30
% high solar case: 2023-05-12 - 2023-05-16
% low  solar case: 2023-04-24 - 2023-04-28

%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (day)
PARAM.Resolution = 15; %sampling period(min) use multiple of 15. int 
%scenario = 'high_load'; % choose from high_load , low_load , high_solar , low_solar, normal1
% scenario = 'low_load';
%scenario = 'high_solar';
% scenario = 'low_solar';
% scenario = 'normal1';
TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
%TOU_CHOICE = 'THcurrent' ;
PARAM.PV_capacity = 48; % (kw) PV sizing for this EMS
%end of ----- parameter ----


% change unit


h = 24*PARAM.Horizon; %optimization horizon(hr)
PARAM.Resolution = PARAM.Resolution/60; %sampling period(Hr)
fs = 1/PARAM.Resolution; %sampling freq(1/Hr)
Horizon = PARAM.Horizon;
% end of change unit
k = h*fs; %length of variable

for i = 1:length(dataset_name)
% %get solar/load profile and buy/sell rate

[PARAM.PV,PARAM.PL] = loadPVandPLcsv(PARAM.Resolution,dataset_name{i});
[PARAM.Buy_rate,PARAM.Sell_rate] = getBuySellrate(fs,Horizon,TOU_CHOICE);

%end of solar/load profile and buy/sell rate

%parameter part


PARAM.battery.charge_effiency = 0.95; %bes charge eff
PARAM.battery.discharge_effiency = 0.95*0.93; %  bes discharge eff note inverter eff 0.93-0.96
PARAM.battery.discharge_rate = 45; % kW max discharge rate
PARAM.battery.charge_rate = 75; % kW max charge rate
PARAM.battery.usable_capacity = 150; % kWh soc_capacity 
PARAM.battery.initial = 50; % userdefined int 0-100 %
PARAM.battery.min = 40; %min soc userdefined int 0-100 %
PARAM.battery.max = 70; %max soc userdefined int 0-100 %
% end of parameter part
% optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]


Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
u =         optimvar('u',k,'LowerBound',0,'UpperBound',inf);
Pdchg =     optimvar('Pdchg',k,'LowerBound',0,'UpperBound',inf);
xdchg =     optimvar('xdchg',k,'LowerBound',0,'UpperBound',1,'Type','integer');
Pchg =      optimvar('Pchg',k,'LowerBound',0,'UpperBound',inf);
xchg =      optimvar('xchg',k,'LowerBound',0,'UpperBound',1,'Type','integer');
soc =       optimvar('soc',k+1,'LowerBound',PARAM.battery.min,'UpperBound',PARAM.battery.max);
prob =      optimproblem('Objective',sum(u));

%constraint part
%--constraint for buy and sell electricity
prob.Constraints.epicons1 = -PARAM.Resolution*PARAM.Buy_rate.*Pnet - u <= 0;

%--battery constraint
prob.Constraints.chargecons = Pchg  <= xchg*PARAM.battery.charge_rate;
prob.Constraints.dischargecons = Pdchg  <= xdchg*PARAM.battery.discharge_rate;
prob.Constraints.NosimultDchgAndChgcons1 = xchg + xdchg >= 0;
prob.Constraints.NosimultDchgAndChgcons2 = xchg + xdchg <= 1;

%--Pnet constraint
prob.Constraints.powercons = Pnet  == PARAM.PV + Pdchg - PARAM.PL - Pchg;

%end of static constraint part

%--soc dynamic constraint 
soccons = optimconstr(k+1);
soccons(1) = soc(1)  == PARAM.battery.initial ;
soccons(2:k+1) = soc(2:k+1)  == soc(1:k) + ...
                         (PARAM.battery.charge_effiency*100*PARAM.Resolution/PARAM.battery.usable_capacity)*Pchg(1:k) ...
                     - (PARAM.Resolution*100/(PARAM.battery.discharge_effiency*PARAM.battery.usable_capacity))*Pdchg(1:k);
prob.Constraints.soccons = soccons;


%---solve for optimal sol

sol = solve(prob,'Options',options);
sol.dataset_name = dataset_name{i};
sol.PARAM = PARAM;
save(strcat('solution/EMS1/',TOU_CHOICE,'_',dataset_name{i},'.mat'),'-struct','sol')
end
