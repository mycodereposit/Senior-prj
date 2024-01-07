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
    
    
    PARAM.battery.charge_effiency = [0.95 0.95]; %bes charge eff
    PARAM.battery.discharge_effiency = [0.95*0.93 0.95*0.93]; %  bes discharge eff note inverter eff 0.93-0.96
    PARAM.battery.discharge_rate = [50 50]; % kW max discharge rate
    PARAM.battery.charge_rate = [50 50]; % kW max charge rate
    PARAM.battery.actual_capacity = [125 125]; % kWh soc_capacity 
    PARAM.battery.initial = [50 50]; % userdefined int 0-100 %
    PARAM.battery.min = [20 20]; %min soc userdefined int 0-100 %
    PARAM.battery.max = [80 80]; %max soc userdefined int 0-100 %
    PARAM.battery.num_batt = length(PARAM.battery.actual_capacity);
    % end of parameter part
    % optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]
    
    
    Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
    u =         optimvar('u',k,'LowerBound',0,'UpperBound',inf);
    Pdchg =     optimvar('Pdchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
    xdchg =     optimvar('xdchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
    Pchg =      optimvar('Pchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
    xchg =      optimvar('xchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
    soc =       optimvar('soc',k+1,PARAM.battery.num_batt,'LowerBound',ones(k+1,PARAM.battery.num_batt).*PARAM.battery.min,'UpperBound',ones(k+1,PARAM.battery.num_batt).*PARAM.battery.max);
    prob =      optimproblem('Objective',sum(u) );
    
    %constraint part
    %--constraint for buy and sell electricity
    prob.Constraints.epicons1 = -PARAM.Resolution*PARAM.Buy_rate.*Pnet - u <= 0;
    
    %--battery constraint

    prob.Constraints.chargeconsbatt = Pchg <= xchg.*(ones(k,PARAM.battery.num_batt).*PARAM.battery.charge_rate);
    
    prob.Constraints.dischargeconsbatt = Pdchg   <= xdchg.*(ones(k,PARAM.battery.num_batt).*PARAM.battery.discharge_rate);
    
    prob.Constraints.NosimultDchgAndChgbatt = xchg + xdchg >= 0;
    
    prob.Constraints.NosimultDchgAndChgconsbatt1 = xchg + xdchg <= 1;
    
    %--Pnet constraint
    prob.Constraints.powercons = Pnet == PARAM.PV + sum(Pdchg,2) - PARAM.PL - sum(Pchg,2);
    
    %end of static constraint part
    
    %--soc dynamic constraint 
    soccons = optimconstr(k+1,PARAM.battery.num_batt);
    
    soccons(1,1:PARAM.battery.num_batt) = soc(1,1:PARAM.battery.num_batt)  == PARAM.battery.initial ;
    for j = 1:PARAM.battery.num_batt
        soccons(2:k+1,j) = soc(2:k+1,j)  == soc(1:k,j) + ...
                                 (PARAM.battery.charge_effiency(:,j)*100*PARAM.Resolution/PARAM.battery.actual_capacity(:,j))*Pchg(1:k,j) ...
                                    - (PARAM.Resolution*100/(PARAM.battery.discharge_effiency(:,j)*PARAM.battery.actual_capacity(:,j)))*Pdchg(1:k,j);
        
    end
    prob.Constraints.soccons = soccons;
    
    
    
    %---solve for optimal sol
    
    sol = solve(prob,'Options',options);
    sol.dataset_name = dataset_name{i};
    sol.PARAM = PARAM;
    save(strcat('solution/EMS1/2batt/',TOU_CHOICE,'_',dataset_name{i},'.mat'),'-struct','sol')
end
