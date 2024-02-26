function sol = EMS2_opt(PARAM,dataset_name,is_save,save_path) 



    options = optimoptions('intlinprog','MaxTime',40);
    % change unit
    h = 24*PARAM.Horizon; %optimization horizon(hr)
    fs = 1/PARAM.Resolution; %sampling freq(1/Hr)
    % end of change unit
    k = h*fs; %length of variable


    Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
    u =         optimvar('u',k,'LowerBound',-inf,'UpperBound',inf);
    s =         optimvar('s',k,'LowerBound',0,'UpperBound',inf);
    Pdchg =     optimvar('Pdchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
    xdchg =     optimvar('xdchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
    Pchg =      optimvar('Pchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
    xchg =      optimvar('xchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
    soc =       optimvar('soc',k+1,PARAM.battery.num_batt,'LowerBound',ones(k+1,PARAM.battery.num_batt).*PARAM.battery.min,'UpperBound',ones(k+1,PARAM.battery.num_batt).*PARAM.battery.max);
    prob =      optimproblem('Objective',sum(u) + sum(s));
    
    %constraint part
    %--constraint for buy and sell electricity
    prob.Constraints.epicons1 = -PARAM.Resolution*PARAM.Buy_rate.*Pnet - u <= 0;
    prob.Constraints.epicons2 = -PARAM.Resolution*PARAM.Sell_rate.*Pnet - u <= 0 ;
    
    % %--battery should be used equally
    prob.Constraints.battdeviate1 = soc(2:k+1,1) - soc(2:k+1,2) <= s;
    prob.Constraints.battdeviate2 = -s <= soc(2:k+1,1) - soc(2:k+1,2);
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
    for i = 1:PARAM.battery.num_batt
        soccons(2:k+1,i) = soc(2:k+1,i)  == soc(1:k,i) + ...
                                 (PARAM.battery.charge_effiency(:,i)*100*PARAM.Resolution/PARAM.battery.actual_capacity(:,i))*Pchg(1:k,i) ...
                                    - (PARAM.Resolution*100/(PARAM.battery.discharge_effiency(:,i)*PARAM.battery.actual_capacity(:,i)))*Pdchg(1:k,i);
        
    end
    prob.Constraints.soccons = soccons;
    
    
    
    %---solve for optimal sol
    
    sol = solve(prob,'Options',options);
    sol.dataset_name = dataset_name;
    sol.PARAM = PARAM;
    if is_save == 1
        % in save_path should contain folder with name nbatt i.e. 1batt 2batt
        save(strcat(save_path,'/EMS2/',num2str(PARAM.battery.num_batt),'batt/',PARAM.TOU_CHOICE,'_',dataset_name,'.mat'),'-struct','sol')

    end
end