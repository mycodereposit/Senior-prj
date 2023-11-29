clear;clc;
sol = load('solution/EMS2/THcurrent_high_solar low_load_11.mat');
PARAM = sol.PARAM;

%----------------prepare solution for plotting
k = 384;
Pgen = sol.Pdchg + PARAM.PV; % PV + Battery discharge
Pload = sol.Pchg + PARAM.PL; % Load + Battery charge
Pnet_check = Pgen  - Pload;
%end of prepare for solution for plotting
[profit,expense,revenue] = GetExpense(sol.Pnet,PARAM.Buy_rate,PARAM.Sell_rate,PARAM.Resolution);
[profit_noems,expense_noems,revenue_noems] = GetExpense(PARAM.PV-PARAM.PL,PARAM.Buy_rate,PARAM.Sell_rate,PARAM.Resolution);
start_date = '2023-04-24';  %a start date for plotting graph
start_date = datetime(start_date);
excess_gen = PARAM.PV - PARAM.PL;
end_date = start_date + PARAM.Horizon;

t1 = start_date; t2 = end_date; 
vect = t1:minutes(PARAM.Resolution*60):t2 ; vect(end) = []; vect = vect';


tiledlayout(4,2);

nexttile

stairs(vect,[PARAM.Buy_rate,PARAM.Sell_rate],'LineWidth',1.2)
hold on
grid on
legend('Buy rate','Sell rate','Location','northeastoutside')

xlabel('Hour') 
title('TOU') 
ylabel('TOU (THB)')
ylim([0 8])
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile

stairs(vect,sol.soc(1:k),'-k','LineWidth',1.5)
ylabel('SoC (%)')
ylim([35 75])
grid on
hold on
yyaxis right
stairs(vect,sol.Pchg,'-r')
hold on 
stairs(vect,sol.Pdchg,'-b')
ylim([0 50])
legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge (SoC)')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')

nexttile
stairs(vect,PARAM.PV,'LineWidth',1.2) 
ylabel('Solar power (kW)')
ylim([0 30])
grid on
hold on
yyaxis right
stairs(vect,PARAM.PL,'LineWidth',1.2)
ylim([0 30])
ylabel('Load (kW)')
legend('Solar','load','Location','northeastoutside')
title('Solar and load power')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off


nexttile
stairs(vect,max(0,sol.Pnet),'-r')
hold on 
grid on

stairs(vect,min(0,sol.Pnet),'-b')
legend('P_{net} > 0 (sold to grid)','P_{net} < 0 (bought from grid)','Location','northeastoutside')
title('P_{net} = PV + P_{dchg} - P_{chg} - P_{load}')
xlabel('Hour')
yticks(-50:25:50)
ylim([-50 50])
ylabel('P_{net} (kW)')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')

hold off






nexttile
stairs(vect,excess_gen,'-k','LineWidth',1.2) 
ylabel('Excess power (kW)')
hold on
grid on
yyaxis right 
stairs(vect,sol.xchg,'-b')
hold on 
grid on
stairs(vect,-sol.xdchg,'-r')

legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
title('Excess power = P_{pv} - P_{load} and Battery charge/discharge status')

xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
yticks(-2:1:2)
ylim([-1.5,1.5])
hold off


nexttile
stairs(vect,revenue,'-r')
hold on
stairs(vect,expense,'-b')
ylabel('Expense/Revenue (THB)')
hold on
ylim([-20 30])

yyaxis right

stairs(vect,cumsum(profit),'-k','LineWidth',1.5)
ylabel('Cumulative profit (THB)')
title('Cumulative profit when using EMS 2') 
legend('Revenue','Expense','Cumulative profit','Location','northeastoutside') 
grid on
xlabel('Hour')
ylim([-800 1200])
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,[PARAM.Buy_rate,PARAM.Sell_rate],'LineWidth',1.2) 
ylim([0 8])
ylabel('TOU (THB)')
hold on
grid on
yyaxis right 
stairs(vect,sol.Pchg,'-r')
hold on 
stairs(vect,sol.Pdchg,'-b')
ylabel('Power (kW)')

legend('Buy rate','Sell rate','P_{chg}','P_{dchg}','Location','northeastoutside')
title('P_{chg},P_{dchg} and TOU')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')

ylim([0 80])
hold off



nexttile
stairs(vect,revenue_noems,'-r')
hold on
stairs(vect,expense_noems,'-b')
ylabel('Expense/Revenue (THB)')
hold on
ylim([-20 30])
yyaxis right

stairs(vect,cumsum(profit_noems),'-k','LineWidth',1.5)
ylabel('Cumulative profit (THB)')
title('Cumulative profit without EMS 2') 
legend('Revenue','Expense','Cumulative profit','Location','northeastoutside') 
grid on
xlabel('Hour')
ylim([-800 1200])
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

%%
tiledlayout(1,2);

% nexttile
% stairs(vect,PARAM.PV,'-b') 
% ylabel('Solar power (kW)','Fontsize',16)
% grid on
% hold on
% yyaxis right
% stairs(vect,PARAM.PL,'-r')
% ylabel('Load (kW)','Fontsize',16)
% legend('Solar','Uncontrallable load','Location','northeastoutside','Fontsize',12)
% title('Solar and uncontrollable load power','Fontsize',16)
% xlabel('Hour','Fontsize',16)
% xticks(start_date:hours(3):end_date)
% datetick('x','HH','keepticks')
% hold off



nexttile
colororder({'k','k'})
stairs(vect,expense,'-r')
hold on
stairs(vect,revenue,'-b')
ylabel('Revenue/Expense (THB)','Fontsize',16)
ylim([-55 10])
hold on
yyaxis right

stairs(vect,cumsum(profit),'-k','LineWidth',1.5)
ylim([-4000 0])
ylabel('Cumulative profit (THB)','Fontsize',16)
title('Cumulative profit when using EMS 2','Fontsize',16) 
legend('Expense','Revenue','Cumulative profit','Location','northeastoutside','Fontsize',12) 
grid on
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off





nexttile
colororder({'k','k'})

stairs(vect,expense_noems,'-r')
hold on
stairs(vect,revenue_noems,'-b')
ylabel('Revenue/Expense (THB)','Fontsize',16)
ylim([-55 10])
hold on
yyaxis right

stairs(vect,cumsum(profit_noems),'-k','LineWidth',1.5)
ylim([-4000 0])
ylabel('Cumulative profit (THB)','Fontsize',16)
title('Cumulative profit without EMS 2','Fontsize',16) 
legend('Expense','Revenue','Cumulative profit','Location','northeastoutside','Fontsize',12) 
grid on
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off
%%
%battery
tiledlayout(2,2);

nexttile
stairs(vect,PARAM.PV,'-b')
ylim([0 35])
ylabel('Solar power (kW)','Fontsize',16)
grid on
hold on
yyaxis right
stairs(vect,PARAM.PL,'-r')
ylim([0 35])
ylabel('Load (kW)','Fontsize',16)
legend('Solar','Uncontrollable load','Location','northeastoutside','Fontsize',12)
title('Solar and uncontrollable load power','Fontsize',16)
xlabel('Hour','Fontsize',16)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,excess_gen,'-k') 
ylabel('Excess power (kW)','Fontsize',16)
ylim([-30 30])
hold on
grid on
yyaxis right 
stairs(vect,sol.xchg,'-b')
ylim([-1.5 1.5])
legend('Excess power','x_{chg}','Location','northeastoutside','Fontsize',12)
title('Excess power = P_{pv} - P_{load} and Battery charge status','Fontsize',16)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
xlabel('Hour','Fontsize',16)

nexttile
stairs(vect,sol.soc(1:k),'-k','LineWidth',1.5)
ylabel('SoC (%)','Fontsize',16)
grid on
hold on
yyaxis right
stairs(vect,sol.Pchg,'-b')
hold on 
stairs(vect,sol.Pdchg,'-r')
legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside','Fontsize',12)
ylabel('Power (kW)','Fontsize',16)
title('State of charge (SoC)','Fontsize',16)
xlabel('Hour','Fontsize',16)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')



nexttile
stairs(vect,excess_gen,'-k') 
ylim([-30 30])
ylabel('Excess power (kW)','Fontsize',16)
hold on
grid on
yyaxis right 
stairs(vect,-sol.xdchg,'-r')
xlabel('Hour','Fontsize',16)
ylim([-1.5 1.5])
legend('Excess power','x_{dchg}','Location','northeastoutside','Fontsize',12)
title('Excess power = P_{pv} - P_{load} and Battery discharge status','Fontsize',16)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
%%


