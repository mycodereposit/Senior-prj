clear;clc;
filename = 'THcurrent_high_load_high_solar_12'; 
%filename = 'THcurrent_high_load_low_solar_15'; 

sol = load(strcat('solution/EMS2/',filename,'.mat')); 
PARAM = sol.PARAM;

%----------------prepare solution for plotting
k = 384;
Pgen = sum(sol.Pdchg,2) + PARAM.PV; % PV + Battery discharge
Pload = sum(sol.Pchg,2) + PARAM.PL; % Load + Battery charge
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

%%
% 8 plot
f = figure('PaperPosition',[0 0 21 24],'PaperOrientation','portrait','PaperUnits','centimeters');
t = tiledlayout(4,2,'TileSpacing','tight','Padding','tight');

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
yticks(0:10:PARAM.battery.charge_rate+10)
ylim([0 PARAM.battery.charge_rate+10])
legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge 1 (SoC)','FontSize',24)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


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
yticks(0:10:PARAM.battery.charge_rate+10)
ylim([0 PARAM.battery.charge_rate+10])
legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge 2 (SoC)','FontSize',24)
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
title('Excess power = P_{pv} - P_{load} and Battery charge/discharge status')
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
ylim([-60 30])
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



nexttile
stairs(vect,revenue_noems,'-r','LineWidth',1)
hold on
stairs(vect,expense_noems,'-b','LineWidth',1)
ylabel('Expense/Revenue (THB)')
hold on
ylim([-60 30])
yticks(-60:20:40)
yyaxis right
stairs(vect,cumsum(profit_noems),'-k','LineWidth',1.5)
ylabel('Cumulative profit (THB)')
title('Without EMS 2') 
legend('Revenue','Expense','Cumulative profit','Location','northeastoutside') 
grid on
xlabel('Hour')
ylim([-3500 1000])
yticks(-3500:500:1000)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
% fontsize(0.6,'centimeters')
% print(f,strcat('graph/EMS2/png/8_plot_',filename),'-dpng')
% print(f,strcat('graph/EMS2/eps/8_plot_',filename),'-deps')


%%
% 6 plot
f = figure('PaperPosition',[0 0 21 20],'PaperOrientation','portrait','PaperUnits','centimeters');
t = tiledlayout(3,2,'TileSpacing','tight','Padding','tight');

colororder({'k','r','k'})
nexttile
hold all
stairs(vect,sol.soc(1:k),'-k','LineWidth',1.5)
ylabel('SoC (%)')
ylim([35 75])
grid on
stairs(vect,[40*ones(384,1),70*ones(384,1)],'--m','HandleVisibility','off','LineWidth',1.2)
yyaxis right
stairs(vect,sol.Pchg,'-b','LineWidth',1)
stairs(vect,sol.Pdchg,'-r','LineWidth',1)
ylim([0 80])
yticks(0:25:100)
legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge (SoC)')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
hold all
stairs(vect,max(0,sol.Pnet),'-g','LineWidth',1.2)
grid on
stairs(vect,min(0,sol.Pnet),'-r','LineWidth',1.2)
yticks(-100:25:50)
ylim([-100 50])
ylabel('P_{net} (kW)')
yyaxis right
stairs(vect,PARAM.Buy_rate,'-m','LineWidth',1.1)
stairs(vect,PARAM.Sell_rate,'-k','LineWidth',1.1)

ylabel('TOU (THB)')
legend('P_{net} > 0 (sold to grid)','P_{net} < 0 (bought from grid)','Buy rate','Sell rate','Location','northeastoutside')
title('P_{net} = PV + P_{dchg} - P_{chg} - P_{load}')
xlabel('Hour')
ylim([0 20])
yticks(2:2:10)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')





nexttile
stairs(vect,excess_gen,'-k','LineWidth',1.2)
yticks(-30:10:30)
ylim([-30 30])
ylabel('Excess power (kW)')
hold on
grid on
yyaxis right 
stairs(vect,sol.xchg,'-b','LineWidth',1)
hold on 
grid on
stairs(vect,-sol.xdchg,'-r','LineWidth',1)
legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
title('Excess power = P_{pv} - P_{load} and Battery charge/discharge status')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
yticks(-2:1:2)
ylim([-1.5,1.5])
hold off


nexttile
stairs(vect,revenue,'-r','LineWidth',1)
hold on
stairs(vect,expense,'-b','LineWidth',1)
ylabel('Expense/Revenue (THB)')
hold on
ylim([-60 30])
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
hold all
stairs(vect,sol.Pchg,'-b','LineWidth',1.2)
yticks(0:20:80)
grid on
stairs(vect,sol.Pdchg,'-r','LineWidth',1.2)
ylim([0 80])
ylabel('P_{chg}/P_{dchg} (kW)')
yyaxis right
stairs(vect,PARAM.Buy_rate,'-m','LineWidth',1.1)
stairs(vect,PARAM.Sell_rate,'-k','LineWidth',1.1)
ylim([-10 10])
ylabel('TOU (THB)')
legend('P_{chg}','P_{dchg}','Buy rate','Sell rate','Location','northeastoutside')
title('TOU and battery charge/discharge power')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
yticks(2:2:10)
datetick('x','HH','keepticks')




nexttile
stairs(vect,revenue_noems,'-r','LineWidth',1)
hold on
stairs(vect,expense_noems,'-b','LineWidth',1)
ylabel('Expense/Revenue (THB)')
hold on
ylim([-60 30])
yticks(-60:20:40)
yyaxis right
stairs(vect,cumsum(profit_noems),'-k','LineWidth',1.5)
ylabel('Cumulative profit (THB)')
title('Without EMS 2') 
legend('Revenue','Expense','Cumulative profit','Location','northeastoutside') 
grid on
xlabel('Hour')
ylim([-3500 1000])
yticks(-3500:500:1000)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off
% fontsize(0.6,'centimeters')
% print(f,strcat('graph/EMS2/png/6_plot_',filename),'-dpng')
% print(f,strcat('graph/EMS2/eps/6_plot_',filename),'-deps')









%%
%battery
f = figure('PaperPosition',[0 0 21 24],'PaperOrientation','portrait','PaperUnits','centimeters');
t = tiledlayout(4,1,'TileSpacing','tight','Padding','tight');

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
yticks(0:10:PARAM.battery.charge_rate+10)
ylim([0 PARAM.battery.charge_rate+10])
legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge 1 (SoC)','FontSize',24)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


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
yticks(0:10:PARAM.battery.charge_rate+10)
ylim([0 PARAM.battery.charge_rate+10])
legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
ylabel('Power (kW)')
title('State of charge 2 (SoC)','FontSize',24)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,sol.Pchg(:,1) - sol.Pchg(:,2),'-k','LineWidth',1.5)
ylabel('P_{chg,1} - P_{chg,2} (kW)')
grid on
yticks(-(PARAM.battery.charge_rate+10):10:PARAM.battery.charge_rate+10)
ylim([-(PARAM.battery.charge_rate+10) PARAM.battery.charge_rate+10])
title('P_{chg,1} - P_{chg,2}','FontSize',24)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,sol.Pdchg(:,1) - sol.Pdchg(:,2),'-k','LineWidth',1.5)
ylabel('P_{dchg,1} - P_{dchg,2} (kW)')
grid on
yticks(-(PARAM.battery.discharge_rate+10):10:PARAM.battery.discharge_rate+10)
ylim([-(PARAM.battery.discharge_rate+10) PARAM.battery.discharge_rate+10])
title('P_{dchg,1} - P_{dchg,2}','FontSize',24)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')

% fontsize(0.6,'centimeters')
% 
% print(f,strcat('graph/EMS2/png/battery_',filename),'-dpng')
% print(f,strcat('graph/EMS2/eps/battery_',filename),'-deps')

%%


