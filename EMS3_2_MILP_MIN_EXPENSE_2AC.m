clear; clc;
options = optimoptions('intlinprog','MaxTime',120);


%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (day)
PARAM.Resolution = 15; %sampling period(min) use multiple of 15. int 
%--- four extreme cases

name = 'low_load_low_solar_9.csv';


TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
%TOU_CHOICE = 'THcurrent' ;
PARAM.PV_capacity = 16; % (kw) PV sizing for this EMS
%end of ----- parameter ----


% change unit

h = 24*PARAM.Horizon; %optimization horizon(hr)
PARAM.Resolution = PARAM.Resolution/60; %sampling period(Hr)
fs = 1/PARAM.Resolution; %sampling freq(1/Hr)
Horizon = PARAM.Horizon;
% end of change unit

k = h*fs; %length of variable

%get solar/load profile and buy/sell rate
[PARAM.PV,PARAM.PL] = loadPVandPLcsv(PARAM.Resolution,name);
PARAM.PV = PARAM.PV*(PARAM.PV_capacity/48); % divide by 8 kW * 6 (scaling factor) = 48 
[PARAM.Buy_rate,PARAM.Sell_rate] = getBuySellrate(fs,Horizon,TOU_CHOICE);
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

PARAM.battery.deviation_penalty_weight = 0.1; 
PARAM.AClab.encourage_weight = 2; %(THB) weight for encourage lab ac usage
PARAM.ACstudent.encourage_weight = 1; %(THB) weight for encourage student ac usage
PARAM.AClab.Paclab_rate = 3.71*3; % (kw) air conditioner input Power for lab
PARAM.ACstudent.Pacstudent_rate = 1.49*2 + 1.82*2; % (kw) air conditioner input Power for lab
PARAM.Puload = min(PARAM.PL) ;% (kW) power of uncontrollable load
% end of parameter part
%%
% optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]


Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
u =         optimvar('u',k,'LowerBound',0,'UpperBound',inf);
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
                     + PARAM.battery.deviation_penalty_weight*sum( sum( (PARAM.battery.max.*(ones(k+1,PARAM.battery.num_batt)) - soc)./(ones(k+1,PARAM.battery.num_batt).*(PARAM.battery.max - PARAM.battery.min)),2) );


% obj_fcn =           sum(u) ...
%                  - PARAM.AClab.encourage_weight*sum( PARAM.ACschedule.*sum(Xac_lab,2))... 
%                  - PARAM.ACstudent.encourage_weight*sum(PARAM.ACschedule.*sum(Xac_student,2) )...
%                  + PARAM.battery.deviation_penalty_weight*sum((PARAM.battery.max(:,1) - soc(:,1))/(PARAM.battery.max(:,1) - PARAM.battery.min(:,1)))...
%                  + PARAM.battery.deviation_penalty_weight*sum((PARAM.battery.max(:,2) - soc(:,2))/(PARAM.battery.max(:,2) - PARAM.battery.min(:,2)));

prob =      optimproblem('Objective',obj_fcn);

%constraint part

%---------- epigraph constraint for buying electricity
prob.Constraints.epicons1 = - PARAM.Resolution*PARAM.Buy_rate.*Pnet  <= u;


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

%assign constraint and solve

sol = solve(prob,'Options',options);

%%
% ------------ prepare solution for plotting

Pgen = sum(sol.Pdchg,2) + PARAM.PV; % PV + Battery discharge
Pload = sol.Pac_lab + PARAM.Puload + sol.Pac_student; % Load + Battery charge
Pac = sol.Pac_lab + sol.Pac_student;
excess_gen = PARAM.PV - Pload;
%Pnet_check = Pgen  - Pload;

[profit,expense,revenue] = GetExpense(sol.Pnet,PARAM.Buy_rate,PARAM.Sell_rate,PARAM.Resolution);

start_date = '2023-04-24';  %a start date for plotting graph
start_date = datetime(start_date);
end_date = start_date + Horizon;

t1 = start_date; t2 = end_date; 
vect = t1:minutes(PARAM.Resolution*60):t2 ; vect(end) = []; vect = vect';



f = figure('PaperPosition',[0 0 21 20],'PaperOrientation','portrait','PaperUnits','centimeters');
t = tiledlayout(4,2,'TileSpacing','tight','Padding','tight');

colororder({'r','r','r','r'})
nexttile
stairs(vect,PARAM.PV,'-b','LineWidth',1.2) 
ylabel('Solar power (kW)')
ylim([0 20])
yticks(0:5:20)
grid on
hold on
yyaxis right
stairs(vect,Pload,'-r','LineWidth',1.2)
ylim([0 20])
yticks(0:5:20)
ylabel('Load (kW)')
legend('Solar','load','Location','northeastoutside')
title('Solar generation and load consumption (P_{load} = P_{uload} + P_{ac,s} + P_{ac,m})')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
hold all
stairs(vect,excess_gen,'-k','LineWidth',1.2) 
grid on
ylim([-20 20])
yticks(-20:5:20)
ylabel('Excess power (kW)')
yyaxis right 
stairs(vect,sol.xchg(:,1),'-b','LineWidth',1)
stairs(vect,-sol.xdchg(:,1),'-r','LineWidth',1)
legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
title('Excess power = P_{pv} - P_{load} and Battery #1 charge/discharge status')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
yticks(-2:1:2)
ylim([-1.5,1.5])
hold off

nexttile
hold all
stairs(vect,excess_gen,'-k','LineWidth',1.2) 
grid on
ylim([-20 20])
yticks(-20:5:20)
ylabel('Excess power (kW)')
yyaxis right 
stairs(vect,sol.xchg(:,2),'-b','LineWidth',1)
stairs(vect,-sol.xdchg(:,2),'-r','LineWidth',1)
legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
title('Excess power = P_{pv} - P_{load} and Battery #2 charge/discharge status')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
yticks(-2:1:2)
ylim([-1.5,1.5])
hold off


nexttile
stairs(vect,sol.soc(1:k,1),'k','LineWidth',1.5) 
ylabel('SoC (%)')
ylim([PARAM.battery.min(:,1)-5 PARAM.battery.max(:,1)+5])
yticks(PARAM.battery.min(:,1):10:PARAM.battery.max(:,1))
hold on
stairs(vect,[PARAM.battery.min(:,1)*ones(k,1),PARAM.battery.max(:,1)*ones(k,1)],'--m','LineWidth',1.5,'HandleVisibility','off') 
grid on
hold on
yyaxis right
stairs(vect,Pload,'-r','LineWidth',1.2)
ylim([0 20])
yticks(0:5:20)
ylabel('Load (kW)')
legend('SoC','Load','Location','northeastoutside')
title('State of charge 1 and load consumption (P_{uload} + P_{ac,s} + P_{ac,m})')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,sol.soc(1:k,2),'k','LineWidth',1.5) 
ylabel('SoC (%)')
ylim([PARAM.battery.min(:,2)-5 PARAM.battery.max(:,2)+5])
yticks(PARAM.battery.min(:,2):10:PARAM.battery.max(:,2))
hold on
stairs(vect,[PARAM.battery.min(:,2)*ones(k,1),PARAM.battery.max(:,2)*ones(k,1)],'--m','LineWidth',1.5,'HandleVisibility','off') 
grid on
hold on
yyaxis right
stairs(vect,Pload,'-r','LineWidth',1.2)
ylim([0 20])
yticks(0:5:20)
ylabel('Load (kW)')
legend('SoC','Load','Location','northeastoutside')
title('State of charge 2 and load consumption (P_{uload} + P_{ac,s} + P_{ac,m})')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off



nexttile
stairs(vect,sol.Pac_lab*100/PARAM.AClab.Paclab_rate,'-r','LineWidth',1.2)
ylim([0 100])
ylabel('AC level (%)')
yticks([0 50 70 80 100])
hold on 
grid on
yyaxis right
stairs(vect,PARAM.ACschedule,'-.k','LineWidth',1.2)
ylim([0 1.2])
yticks([0 1])
legend('AC level','ACschedule')
title('Lab AC level')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,max(0,sol.Pnet),'-r','LineWidth',1.2)
hold on 
grid on
stairs(vect,min(0,sol.Pnet),'-b','LineWidth',1.2)
legend('P_{net} > 0 (curtail)','P_{net} < 0 (bought from grid)','Location','northeastoutside')
title('P_{net} = PV + P_{dchg} - P_{chg} - P_{load}')
xlabel('Hour')
ylim([-100 50])
yticks(-100:10:50)
ylabel('P_{net} (kW)')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off


nexttile
stairs(vect,sol.Pac_student*100/PARAM.ACstudent.Pacstudent_rate,'-r','LineWidth',1.2)
ylim([0 100])
yticks([0 50 70 80 100])
ylabel('AC level (%)')
hold on 
grid on
yyaxis right
stairs(vect,PARAM.ACschedule,'-.k','LineWidth',1.2)
yticks([0 1])
ylim([0 1.2])
legend('AC level','ACschedule')
title('Student AC level')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off



function schedule = getSchedule(start,stop,Resolution,Horizon)
    schedule = zeros(24/Resolution,1);
    schedule(start*(1/Resolution)+1:stop*(1/Resolution)+1) = 1;
    schedule = kron(ones(Horizon,1),schedule);
end



