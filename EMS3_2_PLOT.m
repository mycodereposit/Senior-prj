clear;clc;
sol = load('solution/EMS3_2/THcurrent_high_solar low_load_5.mat'); %expense case
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



tiledlayout(5,2);

nexttile

stairs(vect,PARAM.Buy_rate)
grid on
legend('Buy rate','Location','northeastoutside')
%set(gca,'YLim',[0 6])
xlabel('Hour') 
title('TOU') 
ylabel('TOU (THB)')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile

stairs(vect,sol.soc(1:end-1))
grid on
ylabel('SoC (%)')
title('State of charge (SoC)')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,sol.Pchg)
ylim([0,15])
hold on 
grid on
yyaxis right
stairs(vect,10*sol.xchg,'-.r')
legend('P_{chg}','x_{chg}','Location','northeastoutside')
title('Pchg (kW) and xchg')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0,15])
hold off


nexttile
stairs(vect,PARAM.PV) 
ylabel('Solar power (kW)')
grid on
hold on
yyaxis right

stairs(vect,Pload)
ylabel('Load (kW)')
legend('Solar','load','Location','northeastoutside')
title('Solar and load power')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off



nexttile
stairs(vect,sol.Pdchg) 
ylim([0,15])
hold on
grid on
yyaxis right 
stairs(vect,10*sol.xdchg,'-.r')
legend('P_{dchg}','x_{dchg}','Location','northeastoutside')
title('Pdchg (kW) and xdchg')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0,15])
hold off


nexttile
stairs(vect,sol.Pnet,'r')
ylim([-10 10])

hold on

grid on
yyaxis right 
stairs(vect,PARAM.Buy_rate,'-.k')
ylim([-10 10])
ylabel('Pnet(kW)')
title('Pnet(kW)') 
legend('P_{net}(kW)','P_{ac}(kW)','Location','northeastoutside') 
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

nexttile
stairs(vect,[sum(sol.Xac_lab,2),sol.Pac_lab/PARAM.AClab.Paclab_rate])
hold on 
grid on
ylim([0 1.5])
stairs(vect,1.25*PARAM.ACschedule,'-.k')
legend('x_{ac}','Pac(%)','ACschedule','Location','northeastoutside')
title('Lab Air Conditioner state and Power')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile;
stairs(vect,[cumsum(sol.u),sol.Pchg]); ylabel('Expense (THB)')
title('Cumulative Expense')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,[sum(sol.Xac_student,2),sol.Pac_student/PARAM.ACstudent.Pacstudent_rate])
hold on 
grid on
ylim([0 1.5])
stairs(vect,1.25*PARAM.ACschedule,'-.k')
legend('x_{ac}','Pac(%)','Acschedule','Location','northeastoutside')
title('Student Air Conditioner state and Power')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

% nexttile
% stairs(vect,PV)
% 
% hold on 
% grid on
% yyaxis right
% stairs(vect,Pgen)
% legend('PV','Pgen')
% title('PV(kW)  and Pgen(kW)')
% xlabel('Hour')
% xticks(start_date:hours(3):end_date)
% datetick('x','HH','keepticks')
% 
% hold off
%%
excess_gen = PARAM.PV - PARAM.Puload - sol.Pchg;
tiledlayout(2,2);

nexttile
stairs(vect,PARAM.PV,'-b') 
ylabel('Solar power (kW)','Fontsize',16)
grid on
hold on
yyaxis right
stairs(vect,Pload,'-r')
ylim([0 10])
ylabel('Load (kW)','Fontsize',16)
legend('Solar','load','Location','northeastoutside','Fontsize',12)
title('Solar and load (Uncontrollable load + controllable load)','Fontsize',16)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,[sum(sol.Xac_lab,2),sol.Pac_lab/PARAM.AClab.Paclab_rate],'LineWidth',1.2)
hold on 
grid on
ylim([0 1.5])
stairs(vect,1.25*PARAM.ACschedule,'-.k','LineWidth',1.2)
legend('x_{ac,m}','AC level','ACschedule','Location','northeastoutside','Fontsize',12)
title('Lab Air Conditioner state and AC level','Fontsize',16)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off


nexttile
stairs(vect,sol.soc(1:384),'k','LineWidth',1.5) 
ylabel('SoC (%)')
grid on
hold on
yyaxis right
stairs(vect,Pload)
ylim([0 10])
ylabel('Load (kW)')
legend('SoC','Load','Location','northeastoutside','Fontsize',12)
title('State of charge (SoC) and load power','Fontsize',16)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stairs(vect,[sum(sol.Xac_student,2),sol.Pac_student/PARAM.ACstudent.Pacstudent_rate],'LineWidth',1.2)
hold on 
grid on
ylim([0 1.5])
stairs(vect,1.25*PARAM.ACschedule,'-.k','LineWidth',1.2)
legend('x_{ac,s}','AC level','Acschedule','Location','northeastoutside','Fontsize',12)
title('Student Air Conditioner state and AC level','Fontsize',16)
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

%%
expense = sol.u;
expense_noems = min(0,PARAM.PV-Pload)*PARAM.Resolution.*PARAM.Buy_rate; % thcurr



stairs(vect,expense,'-k','LineWidth',1.5)
ylabel('Cumulative expense(THB)','Fontsize',16)
hold on


stairs(vect,cumsum(expense_noems),'-r')

title('Cumulative expense when using TOU 0 ','Fontsize',16) 
legend('With EMS 3','Without EMS 3','Location','northeastoutside','Fontsize',12) 
grid on
xlabel('Hour')
ylim([-500 100])
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off
