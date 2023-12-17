clear; clc;
options = optimoptions('intlinprog','MaxTime',120);
% high load case : 2023-04-18 - 2023-04-22
% low  load case : 2023-05-26 - 2023-05-30
% high solar case: 2023-05-12 - 2023-05-16
% low  solar case: 2023-04-24 - 2023-04-28
dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (day)
PARAM.Resolution = 15; %sampling period(min) use multiple of 15. int 
%--- four extreme cases
name = 'high_solar high_load_9.csv'; % high load
%name = 'low_solar low_load_4.csv';  % low load
%name = 'high_solar low_load_5.csv'; % high solar
%name = 'low_solar high_load_5.csv'; % low  solar

TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
%TOU_CHOICE = 'THcurrent' ;
PARAM.PV.installed_capacity = 16; % (kw) PV sizing for this EMS
%end of ----- parameter ----


% change unit

h = 24*PARAM.Horizon; %optimization horizon(hr)
PARAM.Resolution = PARAM.Resolution/60; %sampling period(Hr)
fs = 1/PARAM.Resolution; %sampling freq(1/Hr)
Horizon = PARAM.Horizon;
% end of change unit

k = h*fs; %length of variable
for i = 1:length(dataset_name)
    %get solar/load profile and buy/sell rate
    [PARAM.PV,PARAM.PL] = loadPVandPLcsv(PARAM.Resolution,dataset_name{i});
    PARAM.PV = PARAM.PV*2/6; %scale pv size to 16 kW
    [PARAM.Buy_rate,PARAM.Sell_rate] = getBuySellrate(fs,Horizon,TOU_CHOICE);
    %end of solar/load profile and buy/sell rate
    
    
    %parameter part
    %get schedule for AC
    PARAM.schedule_start = 13; %schedule start @ 13:00
    PARAM.schedule_stop = 16;  %schedule end @ 16:00
    PARAM.ACschedule = getSchedule(PARAM.schedule_start,PARAM.schedule_stop,PARAM.Resolution,PARAM.Horizon);
    %get schedule for AC
    
    
    PARAM.battery.charge_effiency = 0.95; %bes charge eff
    PARAM.battery.discharge_effiency = 0.95*0.93; %  bes discharge eff note inverter eff 0.93-0.96
    PARAM.battery.discharge_rate = 45; % kW max discharge rate
    PARAM.battery.charge_rate = 75; % kW max charge rate
    PARAM.battery.usable_capacity = 150; % kWh soc_capacity 
    PARAM.battery.initial = 50; % userdefined int 0-100 %
    PARAM.battery.min = 40; %min soc userdefined int 0-100 %
    PARAM.battery.max = 70; %max soc userdefined int 0-100 %
    
    PARAM.battery.deviation_penalty_weight = 0.1; %max soc userdefined int 0-100 %
    PARAM.AClab.encourage_weight = 2; %(THB) weight for encourage lab ac usage
    PARAM.ACstudent.encourage_weight = 1; %(THB) weight for encourage student ac usage
    PARAM.AClab.Paclab_rate = 3.71*3; % (kw) air conditioner input Power for lab
    PARAM.ACstudent.Pacstudent_rate = 1.49*2 + 1.82*2; % (kw) air conditioner input Power for lab
    PARAM.Puload = min(PARAM.PL) ;% (kW) power of uncontrollable load
    % end of parameter part
    
    
    
    % optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]
    
    
    Pnet =      optimvar('Pnet',k,'LowerBound',0,'UpperBound',inf);
    PV =     optimvar('PV',k,'LowerBound',0,'UpperBound',inf);
    Pdchg =     optimvar('Pdchg',k,'LowerBound',0,'UpperBound',inf);
    xdchg =     optimvar('xdchg',k,'LowerBound',0,'UpperBound',1,'Type','integer');
    Pchg =      optimvar('Pchg',k,'LowerBound',0,'UpperBound',inf);
    xchg =      optimvar('xchg',k,'LowerBound',0,'UpperBound',1,'Type','integer');
    soc =       optimvar('soc',k+1,'LowerBound',PARAM.battery.min,'UpperBound',PARAM.battery.max);
    Pac_lab =       optimvar('Pac_lab',k,'LowerBound',0,'UpperBound',inf);
    Pac_student =       optimvar('Pac_student',k,'LowerBound',0,'UpperBound',inf);
    Xac_lab =      optimvar('Xac_lab',k,4,'LowerBound',0,'UpperBound',1,'Type','integer');
    Xac_student =      optimvar('Xac_student',k,4,'LowerBound',0,'UpperBound',1,'Type','integer');
    
    
    obj_fcn =      - PARAM.AClab.encourage_weight*sum( PARAM.ACschedule.*sum(Xac_lab,2))... 
                     - PARAM.ACstudent.encourage_weight*sum(PARAM.ACschedule.*sum(Xac_student,2) )...
                     + PARAM.battery.deviation_penalty_weight*sum((PARAM.battery.max - soc)/(PARAM.battery.max - PARAM.battery.min));
                    
    prob =      optimproblem('Objective',obj_fcn);
    
    
    %---------- AC constraint---------
    prob.Constraints.Paclabcons = Pac_lab  == PARAM.AClab.Paclab_rate*(Xac_lab(:,1) + 0.5*Xac_lab(:,2) + 0.7*Xac_lab(:,3) + 0.8*Xac_lab(:,4));
    
    prob.Constraints.AClabcons1 = sum(Xac_lab,2) <= 1;
    
    prob.Constraints.AClabcons2 = sum(Xac_lab,2) >= 0;
    
    prob.Constraints.Pacstudentcons = Pac_student  == PARAM.ACstudent.Pacstudent_rate*(Xac_student(:,1) + 0.5*Xac_student(:,2) + 0.7*Xac_student(:,3) + 0.8*Xac_student(:,4));
    
    prob.Constraints.ACstudentcons1 = sum(Xac_student,2) <= 1;
    
    prob.Constraints.ACstudentcons2 = sum(Xac_student,2) >= 0;
    
    %---------- PV ----------
    prob.Constraints.PV = optimconstr(k);
    prob.Constraints.PV(1:k) = PV(1:k) <= PARAM.PV(1:k);
    %---------- Battery constraint ----------
    prob.Constraints.chargecons = Pchg  <= xchg*PARAM.battery.charge_rate;
    
    prob.Constraints.dischargecons = Pdchg  <= xdchg*PARAM.battery.discharge_rate;
    
    prob.Constraints.NosimultDchgAndChgcons1 = xchg + xdchg >= 0;
    
    prob.Constraints.NosimultDchgAndChgcons2 = xchg + xdchg <= 1;
    
    %------------ Pnet constraint ----------
    
    prob.Constraints.powercons = Pnet  == PV + Pdchg - PARAM.Puload - Pac_lab - Pchg - Pac_student;
    
    prob.Constraints.PreservePnet = Pnet == 0;
    
    
    
    %----------- soc dynamic constraint
    prob.Constraints.soccons = optimconstr(k+1);
    prob.Constraints.soccons(1) = soc(1)  == PARAM.battery.initial ;
    prob.Constraints.soccons(2:k+1) = soc(2:k+1)  == soc(1:k) + ...
                                     (PARAM.battery.charge_effiency*100*PARAM.Resolution/PARAM.battery.usable_capacity)*Pchg(1:k) ...
                                     - (PARAM.Resolution*100/(PARAM.battery.discharge_effiency*PARAM.battery.usable_capacity))*Pdchg(1:k);
    
    
    %assign constraint and solve
    %assign constraint and solve
    sol = solve(prob,'Options',options);
    sol.dataset_name = dataset_name{i};
    sol.PARAM = PARAM;
    save(strcat('solution/EMS5/',dataset_name{i},'.mat'),'-struct','sol')
end
function schedule = getSchedule(start,stop,Resolution,Horizon)
    schedule = zeros(24/Resolution,1);
    schedule(start*(1/Resolution)+1:stop*(1/Resolution)+1) = 1;
    schedule = kron(ones(Horizon,1),schedule);
end