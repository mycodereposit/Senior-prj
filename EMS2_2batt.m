clear; clc;
options = optimoptions('intlinprog','MaxTime',40);


%--- user-input parameter ----
PARAM.Horizon = 4;  % horizon to optimize (day)
PARAM.Resolution = 15; %sampling period(min) use multiple of 15. int 
%-----four extreme cases

name = 'high_load_low_solar_5.csv'; % high solar


TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
%TOU_CHOICE = 'THcurrent' ;
PARAM.PV_capacity = 70; % (kw) PV sizing for this EMS
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
PARAM.PV = PARAM.PV*(PARAM.PV_capacity/48); % divide by 8 kW * 6 (scaling factor) = 48 
[PARAM.Buy_rate,PARAM.Sell_rate] = getBuySellrate(fs,Horizon,TOU_CHOICE);



%end of solar/load profile and buy/sell rate

%parameter part


PARAM.battery.charge_effiency = [0.95 0.95]; %bes charge eff
PARAM.battery.discharge_effiency = [0.95*0.93 0.95*0.93]; %  bes discharge eff note inverter eff 0.93-0.96
PARAM.battery.discharge_rate = [50 50]; % kW max discharge rate
PARAM.battery.charge_rate = [50 50]; % kW max charge rate
PARAM.battery.actual_capacity = [200 200]; % kWh soc_capacity 
PARAM.battery.initial = [50 50]; % userdefined int 0-100 %
PARAM.battery.min = [50 50]; %min soc userdefined int 0-100 %
PARAM.battery.max = [100 100]; %max soc userdefined int 0-100 %
PARAM.battery.num_batt = length(PARAM.battery.actual_capacity);
% end of parameter part

%%
% optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]


Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
u =         optimvar('u',k,'LowerBound',-inf,'UpperBound',inf);
s =         optimvar('s',k,'LowerBound',0,'UpperBound',inf);
Pdchg =     optimvar('Pdchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
xdchg =     optimvar('xdchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
Pchg =      optimvar('Pchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
xchg =      optimvar('xchg',k,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
soc =       optimvar('soc',k+1,PARAM.battery.num_batt,'LowerBound',ones(k+1,PARAM.battery.num_batt).*PARAM.battery.min,'UpperBound',ones(k+1,PARAM.battery.num_batt).*PARAM.battery.max);
prob =      optimproblem('Objective',sum(u) );

%constraint part
%--constraint for buy and sell electricity
prob.Constraints.epicons1 = -PARAM.Resolution*PARAM.Buy_rate.*Pnet - u <= 0;
prob.Constraints.epicons2 = -PARAM.Resolution*PARAM.Sell_rate.*Pnet - u <= 0 ;

% %--battery should be used equally
% prob.Constraints.battdeviate1 = soc(2:k+1,1) - soc(2:k+1,2) <= s;
% prob.Constraints.battdeviate2 = -s <= soc(2:k+1,1) - soc(2:k+1,2);
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
%%
%----------------prepare solution for plotting

Pgen = sum(sol.Pdchg,2) + PARAM.PV; % PV + Battery discharge
Pload = sum(sol.Pchg,2) + PARAM.PL; % Load + Battery charge
Pnet_check = Pgen  - Pload;
excess_gen = PARAM.PV - PARAM.PL;
%end of prepare for solution for plotting
[profit,expense,revenue] = GetExpense(sol.Pnet,PARAM.Buy_rate,PARAM.Sell_rate,PARAM.Resolution);
[profit_noems,expense_noems,revenue_noems] = GetExpense(PARAM.PV-PARAM.PL,PARAM.Buy_rate,PARAM.Sell_rate,PARAM.Resolution);
start_date = '2023-04-24';  %a start date for plotting graph
start_date = datetime(start_date);
end_date = start_date + Horizon;

t1 = start_date; t2 = end_date; 
vect = t1:minutes(PARAM.Resolution*60):t2 ; vect(end) = []; vect = vect';
%%
% 1 batt
%f = figure('PaperPosition',[0 0 21 24],'PaperOrientation','portrait','PaperUnits','centimeters');
t = tiledlayout(4,2,'TileSpacing','tight','Padding','tight');


colororder({'k','k','k','k'})
nexttile
stairs(vect,sol.soc(1:k),'-k','LineWidth',1.5)
ylabel('SoC (%)')
ylim([PARAM.battery.min-5 PARAM.battery.max+5])
yticks(PARAM.battery.min:10:PARAM.battery.max)
grid on
hold on
stairs(vect,[PARAM.battery.min(:,1)*ones(384,1),PARAM.battery.max(:,1)*ones(384,1)],'--m','HandleVisibility','off','LineWidth',1.2)
hold on
yyaxis right
stairs(vect,sol.Pchg,'-b','LineWidth',1)
hold on 
stairs(vect,sol.Pdchg,'-r','LineWidth',1)
yticks(0:10:PARAM.battery.charge_rate+10)
ylim([0 PARAM.battery.charge_rate+10])
legend('Soc1','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge (SoC) for battery 1')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')





nexttile
stairs(vect,PARAM.PV,'-b','LineWidth',1.2) 
ylabel('Solar power (kW)')
ylim([0 40])
yticks(0:10:40)
grid on
hold on
yyaxis right
stairs(vect,PARAM.PL,'-r','LineWidth',1.2)
ylim([0 40])
yticks(0:10:40)
ylabel('Load (kW)')
legend('Solar','load','Location','northeastoutside')
title('Solar generation and load consumption')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off


nexttile
stairs(vect,max(0,sol.Pnet),'-g','LineWidth',1)
hold on 
grid on
stairs(vect,min(0,sol.Pnet),'-r','LineWidth',1)
legend('P_{net} > 0 (sold to grid)','P_{net} < 0 (bought from grid)','Location','northeastoutside')
title('P_{net} = PV + P_{dchg} - P_{chg} - P_{load}')
xlabel('Hour')
yticks(-100:25:100)
ylim([-100 100])
ylabel('P_{net} (kW)')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,excess_gen,'-k','LineWidth',1.2) 
ylabel('Excess power (kW)')
yticks(-30:10:30)
ylim([-30 30])
hold on
grid on
yyaxis right 
stairs(vect,sol.xchg,'-b','LineWidth',1)
hold on 
grid on
stairs(vect,-sol.xdchg,'-r','LineWidth',1)
legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
title('Excess power = P_{pv} - P_{load} and Battery No.1 charge/discharge status')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
yticks(-1:1)
ylim([-1.5,1.5])
hold off


nexttile
stairs(vect,revenue,'-r','LineWidth',1)
hold on
stairs(vect,expense,'-b','LineWidth',1)
ylabel('Expense/Revenue (THB)')
hold on
ylim([-60 40])
yticks(-60:20:40)
yyaxis right
stairs(vect,cumsum(profit),'-k','LineWidth',1.5)
ylabel('Cumulative profit (THB)')
title('With EMS 2') 
legend('Revenue','Expense','Cumulative profit','Location','northeastoutside') 
grid on
xlabel('Hour')
ylim([-3500 1000])
yticks(-3500:500:1000)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,excess_gen,'-k','LineWidth',1.2) 
ylabel('Excess power (kW)')
yticks(-30:10:30)
ylim([-30 30])
hold on
grid on
yyaxis right 
stairs(vect,sol.xchg(:,2),'-b','LineWidth',1)
hold on 
grid on
stairs(vect,-sol.xdchg(:,2),'-r','LineWidth',1)
legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
title('Excess power = P_{pv} - P_{load} and Battery No.2 charge/discharge status')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
yticks(-1:1)
ylim([-1.5,1.5])
hold off


nexttile
stairs(vect,PARAM.Buy_rate,'-m','LineWidth',1.2) 
ylim([0 8])
yticks(0:2:8)
ylabel('TOU (THB)')
hold on 
stairs(vect,PARAM.Sell_rate,'-k','LineWidth',1.2) 
hold on
grid on
yyaxis right 
stairs(vect,sol.Pchg,'-b','LineWidth',1)
hold on 
stairs(vect,sol.Pdchg,'-r','LineWidth',1)
ylabel('Power (kW)')
legend('Buy rate','Sell rate','P_{chg}','P_{dchg}','Location','northeastoutside')
title('P_{chg},P_{dchg} and TOU')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0 80])
hold off
%%
% 2 batt
%f = figure('PaperPosition',[0 0 21 24],'PaperOrientation','portrait','PaperUnits','centimeters');
t = tiledlayout(4,2,'TileSpacing','tight','Padding','tight');


colororder({'k','k','k','k'})
nexttile
stairs(vect,sol.soc(1:k,1),'-k','LineWidth',1.5)
ylabel('SoC (%)')
ylim([40 110])
grid on
hold on
stairs(vect,[PARAM.battery.min(:,1)*ones(384,1),PARAM.battery.max(:,1)*ones(384,1)],'--m','HandleVisibility','off','LineWidth',1.2)
hold on
yyaxis right
stairs(vect,sol.Pchg(:,1),'-b','LineWidth',1)
hold on 
stairs(vect,sol.Pdchg(:,1),'-r','LineWidth',1)
ylim([0 40])
legend('Soc1','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge (SoC) for battery 1')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,sol.soc(1:k,2),'-k','LineWidth',1.5)
ylabel('SoC (%)')
ylim([40 110])
grid on
hold on
stairs(vect,[PARAM.battery.min(:,2)*ones(384,1),PARAM.battery.max(:,2)*ones(384,1)],'--m','HandleVisibility','off','LineWidth',1.2)
hold on
yyaxis right
ylim([0 40])
stairs(vect,sol.Pchg(:,2),'-b','LineWidth',1)
hold on 
stairs(vect,sol.Pdchg(:,2),'-r','LineWidth',1)
legend('Soc2','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge (SoC) for battery 2')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,PARAM.PV,'-b','LineWidth',1.2) 
ylabel('Solar power (kW)')
ylim([0 40])
yticks(0:10:40)
grid on
hold on
yyaxis right
stairs(vect,PARAM.PL,'-r','LineWidth',1.2)
ylim([0 40])
yticks(0:10:40)
ylabel('Load (kW)')
legend('Solar','load','Location','northeastoutside')
title('Solar generation and load consumption')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off


nexttile
stairs(vect,max(0,sol.Pnet),'-g','LineWidth',1)
hold on 
grid on
stairs(vect,min(0,sol.Pnet),'-r','LineWidth',1)
legend('P_{net} > 0 (sold to grid)','P_{net} < 0 (bought from grid)','Location','northeastoutside')
title('P_{net} = PV + P_{dchg} - P_{chg} - P_{load}')
xlabel('Hour')
yticks(-100:25:100)
ylim([-100 100])
ylabel('P_{net} (kW)')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,excess_gen,'-k','LineWidth',1.2) 
ylabel('Excess power (kW)')
yticks(-30:10:30)
ylim([-30 30])
hold on
grid on
yyaxis right 
stairs(vect,sol.xchg(:,1),'-b','LineWidth',1)
hold on 
grid on
stairs(vect,-sol.xdchg(:,1),'-r','LineWidth',1)
legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
title('Excess power = P_{pv} - P_{load} and Battery No.1 charge/discharge status')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
yticks(-1:1)
ylim([-1.5,1.5])
hold off


nexttile
stairs(vect,revenue,'-r','LineWidth',1)
hold on
stairs(vect,expense,'-b','LineWidth',1)
ylabel('Expense/Revenue (THB)')
hold on
ylim([-60 40])
yticks(-60:20:40)
yyaxis right
stairs(vect,cumsum(profit),'-k','LineWidth',1.5)
ylabel('Cumulative profit (THB)')
title('With EMS 2') 
legend('Revenue','Expense','Cumulative profit','Location','northeastoutside') 
grid on
xlabel('Hour')
ylim([-3500 1000])
yticks(-3500:500:1000)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,excess_gen,'-k','LineWidth',1.2) 
ylabel('Excess power (kW)')
yticks(-30:10:30)
ylim([-30 30])
hold on
grid on
yyaxis right 
stairs(vect,sol.xchg(:,2),'-b','LineWidth',1)
hold on 
grid on
stairs(vect,-sol.xdchg(:,2),'-r','LineWidth',1)
legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
title('Excess power = P_{pv} - P_{load} and Battery No.2 charge/discharge status')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
yticks(-1:1)
ylim([-1.5,1.5])
hold off


nexttile
stairs(vect,PARAM.Buy_rate,'-m','LineWidth',1.2) 
ylim([0 8])
yticks(0:2:8)
ylabel('TOU (THB)')
hold on 
stairs(vect,PARAM.Sell_rate,'-k','LineWidth',1.2) 
hold on
grid on
yyaxis right 
stairs(vect,sol.Pchg,'-b','LineWidth',1)
hold on 
stairs(vect,sol.Pdchg,'-r','LineWidth',1)
ylabel('Power (kW)')
legend('Buy rate','Sell rate','P_{chg}','P_{dchg}','Location','northeastoutside')
title('P_{chg},P_{dchg} and TOU')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0 80])
hold off




%fontsize(0.6,'centimeters')

