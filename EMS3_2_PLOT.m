clear;clc;
filename = 'THcurrent_high_solar low_load_5'; %high solar
%filename = 'THcurrent_low_solar high_load_5'; %low solar
%filename = 'smart1_low_solar low_load_9'; %expense
%filename = 'THcurrent_high_solar high_load_5';

sol = load(strcat('solution/EMS3_2/',filename,'.mat')); 
PARAM = sol.PARAM;

% ------------ prepare solution for plotting

Pgen = sol.Pdchg + PARAM.PV; % PV + Battery discharge
Pload = sol.Pac_lab + PARAM.Puload + sol.Pac_student; % Load + Battery charge
Pac = sol.Pac_lab + sol.Pac_student;
%Pnet_check = Pgen  - Pload;

[profit,expense,revenue] = GetExpense(sol.Pnet,PARAM.Buy_rate,PARAM.Sell_rate,PARAM.Resolution);

start_date = '2023-04-24';  %a start date for plotting graph
start_date = datetime(start_date);
end_date = start_date + PARAM.Horizon;

t1 = start_date; t2 = end_date; 
vect = t1:minutes(PARAM.Resolution*60):t2 ; vect(end) = []; vect = vect';




%%
% 6 plot
excess_gen = PARAM.PV - Pload;

f = figure('PaperPosition',[0 0 21 20],'PaperOrientation','portrait','PaperUnits','centimeters');
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
ylim([0 10])
yticks(0:2.5:10)
ylabel('Load (kW)')
legend('Solar','load','Location','northeastoutside')
title('Solar generation and load consumption (P_{load} = P_{uload} + P_{ac,s} + P_{ac,m})')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,sol.soc(1:384),'k','LineWidth',1.5) 
ylabel('SoC (%)')
ylim([35 75])
hold on
stairs(vect,[40*ones(384,1),70*ones(384,1)],'--m','LineWidth',1.5,'HandleVisibility','off') 
grid on
hold on
yyaxis right
stairs(vect,Pload,'-r','LineWidth',1.2)
ylim([0 10])

yticks(0:2.5:10)
ylabel('Load (kW)')
legend('SoC','Load','Location','northeastoutside')
title('State of charge (SoC) and load consumption (P_{uload} + P_{ac,s} + P_{ac,m})')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
hold all
stairs(vect,excess_gen,'-k','LineWidth',1.2) 
grid on
ylim([-10 10])
yticks(-10:5:10)
ylabel('Excess power (kW)')
yyaxis right 
stairs(vect,sol.xchg,'-b','LineWidth',1)
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

fontsize(0.6,'centimeters')
print(f,strcat('graph/EMS3_2/png/6_plot_',filename),'-dpng')
print(f,strcat('graph/EMS3_2/eps/6_plot_',filename),'-deps')





%%

expense = sol.u;
expense_noems = -min(0,PARAM.PV-Pload)*PARAM.Resolution.*PARAM.Buy_rate; % thcurr

if filename(1) == 'T' | filename(1) == 't'
    tou = ' TOU 0';
else
    tou = ' TOU 1';
end
f = figure('PaperPosition',[0 0 10 7.5],'PaperOrientation','portrait','PaperUnits','centimeters');

stairs(vect,cumsum(expense),'-k','LineWidth',1.5)
ylabel('Cumulative expense (THB)','Fontsize',16)
hold on
stairs(vect,cumsum(expense_noems),'-r','LineWidth',1)
title(strcat('Cumulative expense when using',tou),'Fontsize',16) 
legend('With EMS 3','Without EMS 3','Location','northwest','Fontsize',12) 
grid on
xlabel('Hour')
ylim([-100 700])
yticks(-100:100:700)
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off
fontsize(0.6,'centimeters')
print(f,strcat('graph/EMS3_2/png/expense_',filename),'-dpng')
print(f,strcat('graph/EMS3_2/eps/expense_',filename),'-deps')
