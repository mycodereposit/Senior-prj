clear;clc;
%filename = 'high_solar low_load_5'; %high solar
%filename = 'low_solar high_load_5'; %low solar
%filename = 'low_solar low_load_9'; %expense
filename = 'low_solar low_load_6';

sol = load(strcat('solution/EMS4_2/',filename,'.mat')); 
PARAM = sol.PARAM;

% ------------ prepare solution for plotting

Pgen = sol.Pdchg + PARAM.PV; % PV + Battery discharge
Pload = sol.Pac_lab + PARAM.Puload + sol.Pac_student; % Load 
Pac = sol.Pac_lab + sol.Pac_student;
excess_gen = PARAM.PV - Pload;
%Pnet_check = Pgen  - Pload;

%[profit,expense,revenue] = GetExpense(sol.Pnet,PARAM.Buy_rate,PARAM.Sell_rate,PARAM.Resolution);

start_date = '2023-04-24';  %a start date for plotting graph
start_date = datetime(start_date);
end_date = start_date + PARAM.Horizon;

t1 = start_date; t2 = end_date; 
vect = t1:minutes(PARAM.Resolution*60):t2 ; vect(end) = []; vect = vect';

%%
% 6 plot
f = figure('PaperPosition',[0 0 21 20],'PaperOrientation','portrait','PaperUnits','centimeters');
t = tiledlayout(3,2,'TileSpacing','tight','Padding','tight');

colororder({'r','r','r','r'})

nexttile
hold all
stairs(vect,PARAM.PV,'-b','LineWidth',1.2) 
stairs(vect,sol.PV,'-g','LineWidth',1.2) 
ylim([0 10])
yticks(0:2:10)
ylabel('P_{pv} (kW)')
grid on
yyaxis right
stairs(vect,Pload,'-r','LineWidth',1.2)
ylim([0 10])
yticks(0:2:10)
ylabel('Load (kW)')
legend('P_{pv}^{max}','P_{pv}','load','Location','northeastoutside')
title('Solar generation (P_{pv}^{max}) and load consumption (P_{load} = P_{uload} + P_{ac,s} + P_{ac,m})')
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
yticks(0:2:10)
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
hold all
stairs(vect,PARAM.PV,'-b','LineWidth',1.2) 
stairs(vect,sol.PV,'-g','LineWidth',1.2)
stairs(vect,sol.Pnet,'--k','LineWidth',1.2)
grid on
legend('P_{pv}^{max}','P_{pv}','P_{net} = 0','Location','northeastoutside')
title('Solar generation (P_{pv}^{max}) and P_{pv}')
xlabel('Hour')
ylim([-10 10])
yticks(-10:5:10)
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
print(f,strcat('graph/EMS4_2/png/6_plot_',filename),'-dpng')
print(f,strcat('graph/EMS4_2/eps/6_plot_',filename),'-deps')