clear;clc;
sol = load('solution/EMS2/THcurrent_low_solar high_load_5.mat');
PARAM = sol.PARAM;

%----------------prepare solution for plotting

Pgen = sol.Pdchg + PARAM.PV; % PV + Battery discharge
Pload = sol.Pchg + PARAM.PL; % Load + Battery charge
Pnet_check = Pgen  - Pload;
%end of prepare for solution for plotting
[profit,expense,revenue] = GetExpense(sol.Pnet,PARAM.Buy_rate,PARAM.Sell_rate,PARAM.Resolution);

start_date = '2023-04-24';  %a start date for plotting graph
start_date = datetime(start_date);
end_date = start_date + PARAM.Horizon;

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

stairs(vect,sol.soc(1:end-1))
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