clear; clc;
options = optimoptions('intlinprog','MaxTime',120);
dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (day)
PARAM.Resolution = 15; %sampling period(min) use multiple of 15. int 



PARAM.PV_capacity = 16; % (kw) PV sizing for this EMS
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
    PARAM.PV = PARAM.PV*(PARAM.PV_capacity/48); % divide by 8 kW * 6 (scaling factor) = 48
    %end of solar/load profile and buy/sell rate
    
    
    %parameter part
    %get schedule for AC
    PARAM.schedule_start = 13; %schedule start @ 13:00
    PARAM.schedule_stop = 16;  %schedule end @ 16:00
    PARAM.ACschedule = getSchedule(PARAM.schedule_start,PARAM.schedule_stop,PARAM.Resolution,PARAM.Horizon);
    %get schedule for AC
    
    
    %for 1 batt 
    % PARAM.battery.charge_effiency = [0.95]; %bes charge eff
    % PARAM.battery.discharge_effiency = [0.95*0.93]; %  bes discharge eff note inverter eff 0.93-0.96
    % PARAM.battery.discharge_rate = [60]; % kW max discharge rate
    % PARAM.battery.charge_rate = [60]; % kW max charge rate
    % PARAM.battery.actual_capacity = [250]; % kWh soc_capacity 
    % PARAM.battery.initial = [50]; % userdefined int 0-100 %
    % PARAM.battery.min = [20]; %min soc userdefined int 0-100 %
    % PARAM.battery.max = [80]; %max soc userdefined int 0-100 %
    %end of 1 batt
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
    
    PARAM.battery.num_batt = length(PARAM.battery.actual_capacity);
    
    PARAM.battery.deviation_penalty_weight = 0.1; %max soc userdefined int 0-100 %
    PARAM.AClab.encourage_weight = 2; %(THB) weight for encourage lab ac usage
    PARAM.ACstudent.encourage_weight = 1; %(THB) weight for encourage student ac usage
    PARAM.AClab.Paclab_rate = 3.71*3; % (kw) air conditioner input Power for lab
    PARAM.ACstudent.Pacstudent_rate = 1.49*2 + 1.82*2; % (kw) air conditioner input Power for lab
    PARAM.Puload = min(PARAM.PL) ;% (kW) power of uncontrollable load
    % end of parameter part
    
    
    
    % optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]
    
    
    Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
    PV =     optimvar('PV',k,'LowerBound',0,'UpperBound',inf);
    u =         optimvar('u',k,'LowerBound',0,'UpperBound',inf);
    s =         optimvar('s',k,'LowerBound',0,'UpperBound',inf);
    Pdchg =     optimvar('Pdchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
    xdchg =     optimvar('xdchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
    Pchg =      optimvar('Pchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
    xchg =      optimvar('xchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
    soc =       optimvar('soc',k+1,PARAM.battery.num_batt,'LowerBound',ones(k+1,PARAM.battery.num_batt).*PARAM.battery.min,'UpperBound',ones(k+1,PARAM.battery.num_batt).*PARAM.battery.max);
    Pac_lab =       optimvar('Pac_lab',k,'LowerBound',0,'UpperBound',inf);
    Pac_student =       optimvar('Pac_student',k,'LowerBound',0,'UpperBound',inf);
    Xac_lab =      optimvar('Xac_lab',k,4,'LowerBound',0,'UpperBound',1,'Type','integer');
    Xac_student =      optimvar('Xac_student',k,4,'LowerBound',0,'UpperBound',1,'Type','integer');
    obj_fcn =           sum(u) ...
                     - PARAM.AClab.encourage_weight*sum( PARAM.ACschedule.*sum(Xac_lab,2))... 
                     - PARAM.ACstudent.encourage_weight*sum(PARAM.ACschedule.*sum(Xac_student,2) )...
                     + PARAM.battery.deviation_penalty_weight*sum( sum( (PARAM.battery.max.*(ones(k+1,PARAM.battery.num_batt)) - soc)./(ones(k+1,PARAM.battery.num_batt).*(PARAM.battery.max - PARAM.battery.min)),2) )...
                     + sum(s);
    prob =      optimproblem('Objective',obj_fcn);
    
    %---------- epigraph constraint for energy
    prob.Constraints.epicons1 = - PARAM.Resolution*Pnet  <= u;
    

    % %--battery should be used equally
    prob.Constraints.battdeviate1 = soc(2:k+1,1) - soc(2:k+1,2) <= s;
    prob.Constraints.battdeviate2 = -s <= soc(2:k+1,1) - soc(2:k+1,2);
    
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
    
    %--battery constraint

    prob.Constraints.chargeconsbatt = Pchg <= xchg.*(ones(k,PARAM.battery.num_batt).*PARAM.battery.charge_rate);
    
    prob.Constraints.dischargeconsbatt = Pdchg   <= xdchg.*(ones(k,PARAM.battery.num_batt).*PARAM.battery.discharge_rate);
    
    prob.Constraints.NosimultDchgAndChgbatt = xchg + xdchg >= 0;
    
    prob.Constraints.NosimultDchgAndChgconsbatt1 = xchg + xdchg <= 1;
    
    %------------ Pnet constraint ----------
    
    prob.Constraints.powercons = Pnet == PV + sum(Pdchg,2) - PARAM.Puload - sum(Pchg,2) - Pac_lab - Pac_student;
    
    prob.Constraints.PreservePnet = Pnet == 0;
    
    
    
    %--soc dynamic constraint 
    soccons = optimconstr(k+1,PARAM.battery.num_batt);
    
    soccons(1,1:PARAM.battery.num_batt) = soc(1,1:PARAM.battery.num_batt)  == PARAM.battery.initial ;
    for j = 1:PARAM.battery.num_batt
        soccons(2:k+1,j) = soc(2:k+1,j)  == soc(1:k,j) + ...
                                 (PARAM.battery.charge_effiency(:,j)*100*PARAM.Resolution/PARAM.battery.actual_capacity(:,j))*Pchg(1:k,j) ...
                                    - (PARAM.Resolution*100/(PARAM.battery.discharge_effiency(:,j)*PARAM.battery.actual_capacity(:,j)))*Pdchg(1:k,j);
        
    end
    prob.Constraints.soccons = soccons;
    
    %assign constraint and solve
    %assign constraint and solve
    sol = solve(prob,'Options',options);
    sol.dataset_name = dataset_name{i};
    sol.PARAM = PARAM;
    save(strcat('solution/EMS4_3/',dataset_name{i},'.mat'),'-struct','sol')
end
function schedule = getSchedule(start,stop,Resolution,Horizon)
    schedule = zeros(24/Resolution,1);
    schedule(start*(1/Resolution)+1:stop*(1/Resolution)+1) = 1;
    schedule = kron(ones(Horizon,1),schedule);
end