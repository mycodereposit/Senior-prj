clear; clc;
options = optimoptions('intlinprog','MaxTime',120);


%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (day)
PARAM.Resolution = 15; %sampling period(min) use multiple of 15. int 
%--- four extreme cases

name = 'low_load_low_solar_9.csv';




PARAM.PV.installed_capacity = 16; % (kw) PV sizing for this EMS
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
PARAM.PV = PARAM.PV*2/6; %scale pv size to 16 kW


%parameter part
%get schedule for AC
PARAM.schedule_start = 13; %schedule start @ 13:00
PARAM.schedule_stop = 16;  %schedule end @ 16:00
PARAM.ACschedule = getSchedule(PARAM.schedule_start,PARAM.schedule_stop,PARAM.Resolution,PARAM.Horizon);
%get schedule for AC


PARAM.battery.charge_effiency = 0.95; %bes charge eff
PARAM.battery.discharge_effiency = 0.95*0.93; %  bes discharge eff note inverter eff 0.93-0.96
PARAM.battery.discharge_rate = 30; % kW max discharge rate
PARAM.battery.charge_rate = 30; % kW max charge rate
PARAM.battery.actual_capacity = 125; % kWh soc_actual_capacity 
PARAM.battery.initial = 50; % userdefined int 0-100 %
PARAM.battery.min = 20; %min soc userdefined int 0-100 %
PARAM.battery.max = 80; %max soc userdefined int 0-100 %

PARAM.battery.deviation_penalty_weight = 0.05; %max soc userdefined int 0-100 %
PARAM.AClab.encourage_weight = 1; %(THB) weight for encourage lab ac usage
PARAM.ACstudent.encourage_weight = 0.5; %(THB) weight for encourage student ac usage
PARAM.AClab.Paclab_rate = 3.71*3; % (kw) air conditioner input Power for lab
PARAM.ACstudent.Pacstudent_rate = 1.49*2 + 1.82*2; % (kw) air conditioner input Power for lab
PARAM.Puload = min(PARAM.PL) ;% (kW) power of uncontrollable load
% end of parameter part

%%
% optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]


Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
PV =     optimvar('PV',k,'LowerBound',0,'UpperBound',inf);
u =         optimvar('u',k,'LowerBound',0,'UpperBound',inf);
s =         optimvar('s',k,'LowerBound',0,'UpperBound',inf);
Pdchg =     optimvar('Pdchg',k,2,'LowerBound',0,'UpperBound',inf);
xdchg =     optimvar('xdchg',k,2,'LowerBound',0,'UpperBound',1,'Type','integer');
Pchg =      optimvar('Pchg',k,2,'LowerBound',0,'UpperBound',inf);
xchg =      optimvar('xchg',k,2,'LowerBound',0,'UpperBound',1,'Type','integer');
soc =       optimvar('soc',k+1,2,'LowerBound',PARAM.battery.min,'UpperBound',PARAM.battery.max);
Pac_lab =       optimvar('Pac_lab',k,'LowerBound',0,'UpperBound',inf);
Pac_student =       optimvar('Pac_student',k,'LowerBound',0,'UpperBound',inf);
Xac_lab =      optimvar('Xac_lab',k,4,'LowerBound',0,'UpperBound',1,'Type','integer');
Xac_student =      optimvar('Xac_student',k,4,'LowerBound',0,'UpperBound',1,'Type','integer');
obj_fcn =           sum(u) ...
                 - PARAM.AClab.encourage_weight*sum( PARAM.ACschedule.*sum(Xac_lab,2))... 
                 - PARAM.ACstudent.encourage_weight*sum(PARAM.ACschedule.*sum(Xac_student,2) )...
                 + PARAM.battery.deviation_penalty_weight*sum((PARAM.battery.max - soc(:,1))/(PARAM.battery.max - PARAM.battery.min))...
                 + PARAM.battery.deviation_penalty_weight*sum((PARAM.battery.max - soc(:,2))/(PARAM.battery.max - PARAM.battery.min))...
                 + sum(s);
prob =      optimproblem('Objective',obj_fcn);
%prob =      optimproblem('Objective',sum(u + v - (ACschedule*lambda_lab).*sum(Xac_lab,2) - (ACschedule*lambda_student).*sum(Xac_student,2) ));
%constraint part

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
prob.Constraints.chargeconsbatt1 = Pchg(:,1)  <= xchg(:,1)*PARAM.battery.charge_rate;
prob.Constraints.chargeconsbatt2 = Pchg(:,2)  <= xchg(:,2)*PARAM.battery.charge_rate;

prob.Constraints.dischargeconsbatt1 = Pdchg(:,1)   <= xdchg(:,1) *PARAM.battery.discharge_rate;
prob.Constraints.dischargeconsbatt2 = Pdchg(:,2)   <= xdchg(:,2) *PARAM.battery.discharge_rate;

prob.Constraints.NosimultDchgAndChgbatt1 = xchg(:,1) + xdchg(:,1) >= 0;
prob.Constraints.NosimultDchgAndChgbatt2 = xchg(:,2) + xdchg(:,2) >= 0;

prob.Constraints.NosimultDchgAndChgconsbatt1 = xchg(:,1) + xdchg(:,1) <= 1;
prob.Constraints.NosimultDchgAndChgconsbatt2 = xchg(:,2) + xdchg(:,2) <= 1;

%------------ Pnet constraint ----------

prob.Constraints.powercons = Pnet == PV + Pdchg(:,1) + Pdchg(:,2) - PARAM.Puload - Pchg(:,1) - Pchg(:,2) - Pac_lab - Pac_student;

prob.Constraints.PreservePnet = Pnet == 0;



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

%assign constraint and solve

sol = solve(prob,'Options',options);


%%
% ------------ prepare solution for plotting

Pgen = sum(sol.Pdchg,2) + PARAM.PV; % PV + Battery discharge
Pload = sol.Pac_lab + PARAM.Puload + sol.Pac_student; % unconLoad + AC
Pac = sol.Pac_lab + sol.Pac_student;
excess_gen = PARAM.PV - Pload;
%Pnet_check = Pgen  - Pload;


start_date = '2023-04-24';  %a start date for plotting graph
start_date = datetime(start_date);
end_date = start_date + Horizon;

t1 = start_date; t2 = end_date; 
vect = t1:minutes(PARAM.Resolution*60):t2 ; vect(end) = []; vect = vect';




t = tiledlayout(3,2,'TileSpacing','tight','Padding','tight');

colororder({'r','r','r','r'})
nexttile
stairs(vect,PARAM.PV,'-b','LineWidth',1.2) 
ylabel('Solar power (kW)')
ylim([0 10])
yticks(0:2.5:10)
grid on
hold on
yyaxis right
stairs(vect,Pload,'-r','LineWidth',1.2)
ylim([0 15])
yticks(0:2.5:15)
ylabel('Load (kW)')
legend('Solar','load','Location','northeastoutside')
title('Solar generation and load consumption (P_{load} = P_{uload} + P_{ac,s} + P_{ac,m})')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,sol.soc(1:k,1),'-k','LineWidth',1.5)
ylabel('SoC (%)')
ylim([PARAM.battery.min-5 PARAM.battery.max+5])
yticks(PARAM.battery.min:10:PARAM.battery.max)
grid on
hold on
stairs(vect,[PARAM.battery.min*ones(384,1),PARAM.battery.max*ones(384,1)],'--m','HandleVisibility','off','LineWidth',1.2)
hold on
yyaxis right
stairs(vect,sol.Pchg(:,1),'-b','LineWidth',1)
hold on 
stairs(vect,sol.Pdchg(:,1),'-r','LineWidth',1)
yticks(0:10:40)
ylim([0 40])
legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge (SoC)','FontSize',24)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')

% nexttile
% hold all
% stairs(vect,excess_gen,'-k','LineWidth',1.2) 
% grid on
% ylim([-10 10])
% yticks(-10:5:10)
% ylabel('Excess power (kW)')
% yyaxis right 
% stairs(vect,sol.xchg,'-b','LineWidth',1)
% stairs(vect,-sol.xdchg,'-r','LineWidth',1)
% legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
% title('Excess power = P_{pv} - P_{load} and Battery charge/discharge status')
% xlabel('Hour')
% xticks(start_date:hours(3):end_date)
% datetick('x','HH','keepticks')
% yticks(-2:1:2)
% ylim([-1.5,1.5])
% hold off


nexttile
stairs(vect,sol.soc(1:k,2),'-k','LineWidth',1.5)
ylabel('SoC (%)')
ylim([PARAM.battery.min-5 PARAM.battery.max+5])
yticks(PARAM.battery.min:10:PARAM.battery.max)
grid on
hold on
stairs(vect,[PARAM.battery.min*ones(384,1),PARAM.battery.max*ones(384,1)],'--m','HandleVisibility','off','LineWidth',1.2)
hold on
yyaxis right
stairs(vect,sol.Pchg(:,2),'-b','LineWidth',1)
hold on 
stairs(vect,sol.Pdchg(:,2),'-r','LineWidth',1)
yticks(0:10:40)
ylim([0 40])
legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge (SoC)','FontSize',24)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,sol.Pac_lab*100/PARAM.AClab.Paclab_rate,'-r','LineWidth',1.2)
ylim([0 100])
ylabel('AC level (%)')
yticks([0 50 70 80 100])
hold on 
grid on
yyaxis right
stairs(vect,PARAM.ACschedule,'-.k','LineWidth',1.2)
ylim([0 1.5])
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
ylim([-20 10])
yticks(-25:5:10)
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
ylim([0 1.5])
legend('AC level','ACschedule')
title('Student AC level')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

%fontsize(0.6,'centimeters')


%%
function schedule = getSchedule(start,stop,Resolution,Horizon)
    schedule = zeros(24/Resolution,1);
    schedule(start*(1/Resolution)+1:stop*(1/Resolution)+1) = 1;
    schedule = kron(ones(Horizon,1),schedule);
end
