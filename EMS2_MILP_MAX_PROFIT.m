
clear; clc;
options = optimoptions('intlinprog','MaxTime',40);


%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (day)
PARAM.Resolution = 15; %sampling period(min) use multiple of 15. int 
%-----four extreme cases
%name = 'high_solar high_load_9.csv'; % high load
%name = 'low_solar low_load_4.csv';  % low load
name = 'high_solar low_load_5.csv'; % high solar
%name = 'low_solar high_load_5.csv'; % low  solar


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

% %get solar/load profile and buy/sell rate

[PARAM.PV,PARAM.PL] = loadPVandPLcsv(PARAM.Resolution,name);
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
%%
% optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]


Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
u =         optimvar('u',k,'LowerBound',-inf,'UpperBound',inf);
Pdchg =     optimvar('Pdchg',k,'LowerBound',0,'UpperBound',inf);
xdchg =     optimvar('xdchg',k,'LowerBound',0,'UpperBound',1,'Type','integer');
Pchg =      optimvar('Pchg',k,'LowerBound',0,'UpperBound',inf);
xchg =      optimvar('xchg',k,'LowerBound',0,'UpperBound',1,'Type','integer');
soc =       optimvar('soc',k+1,'LowerBound',PARAM.battery.min,'UpperBound',PARAM.battery.max);
prob =      optimproblem('Objective',sum(u));

%constraint part
%--constraint for buy and sell electricity
prob.Constraints.epicons1 = -PARAM.Resolution*PARAM.Buy_rate.*Pnet - u <= 0;
prob.Constraints.epicons2 = -PARAM.Resolution*PARAM.Sell_rate.*Pnet - u <= 0 ;

%--battery constraint
prob.Constraints.chargecons = Pchg  <= xchg*PARAM.battery.charge_rate;
prob.Constraints.dischargecons = Pdchg  <= xdchg*PARAM.battery.discharge_rate;
prob.Constraints.NosimultDchgAndChgcons1 = xchg + xdchg >= 0;
prob.Constraints.NosimultDchgAndChgcons2 = xchg + xdchg <= 1;

%--Pnet constraint
prob.Constraints.powercons = Pnet == PARAM.PV + Pdchg - PARAM.PL - Pchg;

%end of static constraint part

%--soc dynamic constraint 
soccons = optimconstr(k+1);
soccons(1) = soc(1)  == PARAM.battery.initial ;
soccons(2:k+1) = soc(2:k+1)  == soc(1:k) + ...
                         (PARAM.battery.charge_effiency*100*PARAM.Resolution/PARAM.battery.usable_capacity)*Pchg(1:k) - (PARAM.Resolution*100/(PARAM.battery.discharge_effiency*PARAM.battery.usable_capacity))*Pdchg(1:k);
prob.Constraints.soccons = soccons;


%---solve for optimal sol

sol = solve(prob,'Options',options);

%%
%----------------prepare solution for plotting

Pgen = sol.Pdchg + PARAM.PV; % PV + Battery discharge
Pload = sol.Pchg + PARAM.PL; % Load + Battery charge
Pnet_check = Pgen  - Pload;
%end of prepare for solution for plotting
[profit,expense,revenue] = GetExpense(sol.Pnet,PARAM.Buy_rate,PARAM.Sell_rate,PARAM.Resolution);

start_date = '2023-04-24';  %a start date for plotting graph
start_date = datetime(start_date);
end_date = start_date + Horizon;

t1 = start_date; t2 = end_date; 
vect = t1:minutes(PARAM.Resolution*60):t2 ; vect(end) = []; vect = vect';


tiledlayout(4,2);

nexttile

stairs(vect,[PARAM.Buy_rate,PARAM.Sell_rate])
legend('Buy rate','Sell rate','Location','northeastoutside')
%set(gca,'YLim',[0 6])
xlabel('Hour') 
title('TOU') 
ylabel('TOU (THB)')
ylim([0 10])
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile

stairs(vect,sol.soc(1:k))
grid on
ylabel('SoC (%)')
title('State of charge (SoC)')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,sol.Pchg)
ylim([0,80])
hold on 
grid on
yyaxis right
stairs(vect,PARAM.battery.charge_rate*sol.xchg,'-.k')
legend('P_{chg}','x_{chg}','Location','northeastoutside')
title('Pchg (kW) and xchg')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0,80])
hold off


nexttile
stairs(vect,PARAM.PV) 
ylabel('Solar power (kW)')
hold on
yyaxis right

stairs(vect,PARAM.PL)
ylabel('Load (kW)')
legend('Solar','load','Location','northeastoutside')
title('Solar and load power')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off



nexttile
stairs(vect,sol.Pdchg) 
ylim([0,60])
hold on
grid on
yyaxis right 
stairs(vect,PARAM.battery.discharge_rate*sol.xdchg,'-.k')
legend('P_{dchg}','x_{dchg}','Location','northeastoutside')
title('Pdchg (kW) and xdchg')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0,60])
hold off


nexttile
stairs(vect,PARAM.PV-PARAM.PL)
ylim([0 40])
hold on
yyaxis right
stairs(vect,sol.Pchg)
ylabel('P(kW)')
title('Excess gen(kW) and Pchg(kW)') 
legend('Excess gen(kW)','P_{chg}','Location','northeastoutside') 
grid on
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stem(vect,sol.xchg)
ylim([-2,2])
hold on 
grid on
yyaxis right
stem(vect,-sol.xdchg,'k')
legend('x_{chg}','x_{dchg}','Location','northeastoutside')
title('xchg  and xdchg')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([-2,2])
hold off



nexttile;
stairs(vect,[cumsum(-sol.u)]); 
ylabel('Profit (THB)')
hold on 
grid on 
yyaxis right
stairs(vect,sol.Pnet);
title('Profit over time')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')







