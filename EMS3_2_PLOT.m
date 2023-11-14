clear;clc;
sol = load('solution/EMS3_2/THcurrent_low_solar high_load_5.mat');
PARAM = sol.PARAM;

% ------------ prepare solution for plotting

Pgen = sol.Pdchg + PARAM.PV; % PV + Battery discharge
Pload = sol.Pchg + sol.Pac_lab + PARAM.Puload + sol.Pac_student; % Load + Battery charge
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
stairs(vect,Pac,'-.k')
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
stairs(vect,cumsum(sol.u)); ylabel('Expense (THB)')
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