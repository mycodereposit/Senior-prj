function sol = EMS3_opt(PARAM,dataset_name,is_save,save_path) 



    options = optimoptions('intlinprog','MaxTime',120);
    % change unit
    h = 24*PARAM.Horizon; %optimization horizon(hr)
    fs = 1/PARAM.Resolution; %sampling freq(1/Hr)
    % end of change unit
    k = h*fs; %length of variable
    %get schedule for AC
    PARAM.schedule_start = 13; %schedule start @ 13:00
    PARAM.schedule_stop = 16;  %schedule end @ 16:00
    PARAM.ACschedule = getSchedule(PARAM.schedule_start,PARAM.schedule_stop,PARAM.Resolution,PARAM.Horizon);
    %get schedule for AC
    
    Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
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
    obj_fcn = sum(u) - PARAM.AClab.encourage_weight*sum( PARAM.ACschedule.*sum(Xac_lab,2))... 
                         - PARAM.ACstudent.encourage_weight*sum(PARAM.ACschedule.*sum(Xac_student,2) )...
                         + PARAM.battery.deviation_penalty_weight*sum( sum( (PARAM.battery.max.*(ones(k+1,PARAM.battery.num_batt)) - soc)./(ones(k+1,PARAM.battery.num_batt).*(PARAM.battery.max - PARAM.battery.min)),2) )...
                         + sum(s);
                        
    
    
    prob =      optimproblem('Objective',obj_fcn);
    
    %constraint part
    
    %---------- epigraph constraint for buying electricity
    prob.Constraints.epicons1 = - PARAM.Resolution*PARAM.Buy_rate.*Pnet  <= u;
    
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
    
    %--battery constraint
    
    prob.Constraints.chargeconsbatt = Pchg <= xchg.*(ones(k,PARAM.battery.num_batt).*PARAM.battery.charge_rate);
    
    prob.Constraints.dischargeconsbatt = Pdchg   <= xdchg.*(ones(k,PARAM.battery.num_batt).*PARAM.battery.discharge_rate);
    
    prob.Constraints.NosimultDchgAndChgbatt = xchg + xdchg >= 0;
    
    prob.Constraints.NosimultDchgAndChgconsbatt1 = xchg + xdchg <= 1;
    
    %--Pnet constraint
    prob.Constraints.powercons = Pnet == PARAM.PV + sum(Pdchg,2) - PARAM.PL - sum(Pchg,2) - Pac_lab - Pac_student;
    
    %preservePnet = Pnet == 0;
    
    
    
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
    sol.dataset_name = dataset_name;
    sol.PARAM = PARAM;
    if is_save == 1
        % in save_path should contain folder with name nbatt i.e. 1batt 2batt
        save(strcat(save_path,'/EMS3/',num2str(PARAM.battery.num_batt),'batt/',PARAM.TOU_CHOICE,'_',dataset_name,'.mat'),'-struct','sol')

    end
end

function schedule = getSchedule(start,stop,Resolution,Horizon)
    schedule = zeros(24/Resolution,1);
    schedule(start*(1/Resolution)+1:stop*(1/Resolution)+1) = 1;
    schedule = kron(ones(Horizon,1),schedule);
end
