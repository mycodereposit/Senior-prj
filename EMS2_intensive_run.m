clear; clc;

dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;

options = optimoptions('intlinprog','MaxTime',40);


%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (day)
PARAM.Resolution = 15; %sampling period(min) use multiple of 15. int 

%TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
TOU_CHOICE = 'THcurrent' ;
PARAM.PV_capacity = 50; % (kw) PV sizing for this EMS
%end of ----- parameter ----


% change unit


h = 24*PARAM.Horizon; %optimization horizon(hr)
PARAM.Resolution = PARAM.Resolution/60; %sampling period(Hr)
fs = 1/PARAM.Resolution; %sampling freq(1/Hr)
Horizon = PARAM.Horizon;
% end of change unit
k = h*fs; %length of variable

[PARAM.Buy_rate,PARAM.Sell_rate] = getBuySellrate(fs,Horizon,TOU_CHOICE);

for i = 1:length(dataset_name)
    % %get solar/load profile and buy/sell rate
    
    [PARAM.PV,PARAM.PL] = loadPVandPLcsv(PARAM.Resolution,dataset_name{i});
    PARAM.PV = PARAM.PV*(PARAM.PV_capacity/48); % divide by 8 kW * 6 (scaling factor) = 48 
    
    %end of solar/load profile and buy/sell rate
    
    %parameter part
    
    
    PARAM.battery.charge_effiency = 0.95; %bes charge eff
    PARAM.battery.discharge_effiency = 0.95*0.93; %  bes discharge eff note inverter eff 0.93-0.96
    PARAM.battery.discharge_rate = 30; % kW max discharge rate
    PARAM.battery.charge_rate = 30; % kW max charge rate
    PARAM.battery.actual_capacity = 125; % kWh soc_actual_capacity 
    PARAM.battery.initial = 50; % userdefined int 0-100 %
    PARAM.battery.min = 20; %min soc userdefined int 0-100 %
    PARAM.battery.max = 80; %max soc userdefined int 0-100 %
    % end of parameter part
    % optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]
    
    
    Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
    u =         optimvar('u',k,'LowerBound',-inf,'UpperBound',inf);
    Pdchg =     optimvar('Pdchg',k,2,'LowerBound',0,'UpperBound',inf);
    xdchg =     optimvar('xdchg',k,2,'LowerBound',0,'UpperBound',1,'Type','integer');
    Pchg =      optimvar('Pchg',k,2,'LowerBound',0,'UpperBound',inf);
    xchg =      optimvar('xchg',k,2,'LowerBound',0,'UpperBound',1,'Type','integer');
    soc =       optimvar('soc',k+1,2,'LowerBound',PARAM.battery.min,'UpperBound',PARAM.battery.max);
    prob =      optimproblem('Objective',sum(u) );
    
    %constraint part
    %--constraint for buy and sell electricity
    prob.Constraints.epicons1 = -PARAM.Resolution*PARAM.Buy_rate.*Pnet - u <= 0;
    prob.Constraints.epicons2 = -PARAM.Resolution*PARAM.Sell_rate.*Pnet - u <= 0 ;
    
    
    %--battery constraint
    prob.Constraints.chargeconsbatt1 = Pchg(:,1)  <= xchg(:,1)*PARAM.battery.charge_rate;
    prob.Constraints.chargeconsbatt2 = Pchg(:,2)  <= xchg(:,2)*PARAM.battery.charge_rate;
    
    prob.Constraints.dischargeconsbatt1 = Pdchg(:,1)   <= xdchg(:,1) *PARAM.battery.discharge_rate;
    prob.Constraints.dischargeconsbatt2 = Pdchg(:,2)   <= xdchg(:,2) *PARAM.battery.discharge_rate;
    
    prob.Constraints.NosimultDchgAndChgbatt1 = xchg(:,1) + xdchg(:,1) >= 0;
    prob.Constraints.NosimultDchgAndChgbatt2 = xchg(:,2) + xdchg(:,2) >= 0;
    
    prob.Constraints.NosimultDchgAndChgconsbatt1 = xchg(:,1) + xdchg(:,1) <= 1;
    prob.Constraints.NosimultDchgAndChgconsbatt2 = xchg(:,2) + xdchg(:,2) <= 1;
    %--Pnet constraint
    prob.Constraints.powercons = Pnet == PARAM.PV + Pdchg(:,1) + Pdchg(:,2) - PARAM.PL - Pchg(:,1) - Pchg(:,2);
    
    %end of static constraint part
    
    %--soc dynamic constraint 
    soccons = optimconstr(k+1,2);
    soccons(1,1:2) = soc(1,1:2)  == PARAM.battery.initial ;
    soccons(2:k+1,1) = soc(2:k+1,1)  == soc(1:k,1) + ...
                             (PARAM.battery.charge_effiency*100*PARAM.Resolution/PARAM.battery.actual_capacity)*Pchg(1:k,1) ...
                                - (PARAM.Resolution*100/(PARAM.battery.discharge_effiency*PARAM.battery.actual_capacity))*Pdchg(1:k,1);
    soccons(2:k+1,2) = soc(2:k+1,2)  == soc(1:k,2) + ...
                             (PARAM.battery.charge_effiency*100*PARAM.Resolution/PARAM.battery.actual_capacity)*Pchg(1:k,2) ...
                                - (PARAM.Resolution*100/(PARAM.battery.discharge_effiency*PARAM.battery.actual_capacity))*Pdchg(1:k,2);
    
    prob.Constraints.soccons = soccons;
    
    
    %---solve for optimal sol
    
    sol = solve(prob,'Options',options);
    sol.dataset_name = dataset_name{i};
    sol.PARAM = PARAM;
    save(strcat('solution/EMS2/',TOU_CHOICE,'_',dataset_name{i},'.mat'),'-struct','sol')
end
