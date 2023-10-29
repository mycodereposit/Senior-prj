clear all; clc;
options = optimoptions('intlinprog','MaxTime',40);
% high load case : 2023-04-18 - 2023-04-22
% low  load case : 2023-05-26 - 2023-05-30
% high solar case: 2023-05-12 - 2023-05-16
% low  solar case: 2023-04-24 - 2023-04-28

%--- user-input parameter ----
Horizon = 4;  % horizon to optimize (day)
Resolution = 15; %sampling period(min) use multiple of 15. int 
start_date = '2023-04-24';  

%end of ----- parameter ----

%----max profit
% change unit

h = 24*Horizon; %optimization horizon(hr)

Resolution = Resolution/60; %sampling period(Hr)
fs = 1/Resolution; %sampling freq(1/Hr)

% end of change unit
k = h*fs; %number of iteration int
% yyyy-mm-dd for choose load range
% the range is include start_date but not end_date i.e. [start_date,end_date)
start_date = datetime(start_date);
end_date = start_date + Horizon;

t1 = start_date; t2 = end_date; 
vect = t1:minutes(Resolution*60):t2 ; vect(end) = []; vect = vect';


% %get solar/load profile and buy/sell rate
%TOU_CHOICE = 'smart1' ;
%TOU_CHOICE = 'nosell' ;
TOU_CHOICE = 'THcurrent' ;
[PV,PL,Buy_rate,Sell_rate] = getProfile(fs,h,start_date,end_date,TOU_CHOICE);
%end of solar/load profile and buy/sell rate

%parameter part
%get schedule for AC
schedule_start = 13; %schedule start @ 13:00
schedule_stop = 16;  %schedule end @ 16:00
ACschedule = getSchedule(schedule_start,schedule_stop,Resolution,Horizon);
%get schedule for AC
nc = 0.95; %bes eff
nd = 0.95*0.93; %  bes discharge eff note inverter eff 0.93-0.96
dr = 1.5; % kW max discharge rate
cr = 2.5; % kW max charge rate
soc_capacity = 5; % kWh soc_capacity 
initial_soc = 50; % userdefined int 0-100 %
lb_soc = 40; %min soc userdefined int 0-100 %
ub_soc = 70; %max soc userdefined int 0-100 %
lambda = 5; %(THB) weight for encourage ac usage
Pac_rate = 3.59; % (kw) air conditioner input Power
Puload = min(PL) ;% (kW) power of uncontrollable load
% end of parameter part
%%
% optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]


Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
Pdchg =     optimvar('Pdchg',k,'LowerBound',0,'UpperBound',inf);
xdchg =     optimvar('xdchg',k,'LowerBound',0,'UpperBound',1,'Type','integer');
Pchg =      optimvar('Pchg',k,'LowerBound',0,'UpperBound',inf);
xchg =      optimvar('xchg',k,'LowerBound',0,'UpperBound',1,'Type','integer');
soc =       optimvar('soc',k+1,'LowerBound',lb_soc,'UpperBound',ub_soc);
Pac =       optimvar('Pac',k,'LowerBound',0,'UpperBound',inf);
Xac1 =      optimvar('Xac1',k,'LowerBound',0,'UpperBound',1,'Type','integer');
Xac2 =      optimvar('Xac2',k,'LowerBound',0,'UpperBound',1,'Type','integer');
Xac3 =      optimvar('Xac3',k,'LowerBound',0,'UpperBound',1,'Type','integer');
Xac4 =      optimvar('Xac4',k,'LowerBound',0,'UpperBound',1,'Type','integer');
prob =      optimproblem('Objective',-sum(Xac1 + Xac2 + Xac3 + Xac4 - ACschedule));

%constraint part

Paccons = Pac  == Pac_rate*(Xac1 + 0.5*Xac2 + 0.7*Xac3 + 0.8*Xac4);
ACcons1 = Xac1 + Xac2 + Xac3 + Xac4 <= 1;
ACcons2 = Xac1 + Xac2 + Xac3 + Xac4 >= 0;
chargecons = Pchg  <= xchg*cr;
dischargecons = Pdchg  <= xdchg*dr;
powercons = Pnet  == PV + Pdchg - Puload - Pac - Pchg;
Islandcons = Pnet == 0;
NosimultDchgAndChgcons1 = xchg + xdchg >= 0;
NosimultDchgAndChgcons2 = xchg + xdchg <= 1;


prob.Constraints.Paccons = Paccons;
prob.Constraints.ACcons1 = ACcons1;
prob.Constraints.ACcons2 = ACcons2;
prob.Constraints.chargecons = chargecons;
prob.Constraints.dischargecons = dischargecons;
prob.Constraints.powercons = powercons;
prob.Constraints.Islandcons = Islandcons;
prob.Constraints.NosimultDchgAndChgcons1 = NosimultDchgAndChgcons1;
prob.Constraints.NosimultDchgAndChgcons2 = NosimultDchgAndChgcons2;
%end of static constraint part

%recursive constraint part
soccons = optimconstr(k);
soccons(1) = soc(1)  == initial_soc;
soccons(2:k+1) = (100/soc_capacity)*soc(2:k+1)  == (100/soc_capacity)*soc(1:k) + (nc*100*Resolution/soc_capacity)*Pchg(1:k) - (Resolution*100/(nd*soc_capacity))*Pdchg(1:k);






prob.Constraints.soccons = soccons;
%problem = prob2struct(prob);
% get solution
sol = solve(prob,'Options',options);
%opt24 = getPlotableSol(x,12);
%%
%prepare solution for plotting

Pgen = sol.Pdchg + PV; % PV + Battery discharge
Pload = sol.Pchg + sol.Pac + Puload; % Load + Battery charge
Pnet_check = Pgen  - Pload;
%end of prepare for solution for plotting
[profit,expense,revenue] = GetExpense(sol.Pnet,Buy_rate,Sell_rate,Resolution);
%disp([Pnet_check,Pnet])
%plotting part
t = Resolution:Resolution:h;


tiledlayout(4,2);




nexttile

stairs(vect,sol.soc(1:k))
ylabel('SoC (%)')
title('State of charge (SoC)')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')

nexttile

stairs(vect,PV)
hold on
grid on
stairs(vect,sol.Pac)
legend('PV','P_{ac}')

xlabel('Hour') 
title('PV(kW) and Pac(kW)') 
ylabel('P(kW)')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')



nexttile
stairs(vect,sol.Pchg)
ylim([0,1.2*cr])
hold on 
grid on
yyaxis right
stairs(vect,cr*sol.xchg,'-.r')
legend('P_{chg}','x_{chg}')
title('Pchg (kW) and xchg')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0,1.2*cr])
hold off

nexttile
stairs(vect,PV,'b') 
ylabel('PV(kW)')
hold on
yyaxis right

stairs(vect,Pload,'r')

ylabel('PLoad(kW)')
legend('PV','Pload')
title('PV(kW) and Pload(kW)')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off


nexttile
stairs(vect,sol.Pdchg) 
ylim([0,1.2*dr])
hold on
grid on
yyaxis right 
stairs(vect,dr*sol.xdchg,'-.r')
legend('P_{dchg}','x_{dchg}')
title('Pdchg (kW) and xdchg')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0,1.2*dr])
hold off


nexttile
stairs(vect,[Pgen,sol.Pchg])
hold on
ylabel('P(kW)')
title('Pgen(kW) and Pchg(kW)') 
legend('P_{gen}','P_{chg}') 
grid on
xlabel('Hour')
datetick('x','HH','keepticks')
hold off

nexttile
stem(vect,sol.xchg)
ylim([0,1])
hold on 
grid on
yyaxis right
stem(vect,sol.xdchg,'r')
legend('x_{chg}','x_{dchg}')
title('xchg  and xdchg')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0,2])
hold off

nexttile
stairs(vect,[sol.Xac1+sol.Xac2+sol.Xac3+sol.Xac4,sol.Pac/Pac_rate])
colororder(['#0000FF';'#FF0000';])
ylim([0 2])
hold on 
grid on
yyaxis right
stairs(vect,ACschedule,'-.')
ylim([0 1.5])
legend('x_{ac}','Pac(%)','ACschedule')
title('Air Conditioner state and Power')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off




function schedule = getSchedule(start,stop,Resolution,Horizon)
    schedule = zeros(24/Resolution,1);
    schedule(start*(1/Resolution)+1:stop*(1/Resolution)+1) = 1;
    schedule = kron(ones(Horizon,1),schedule);
end
function [profit,expense,revenue] = GetExpense(Pnet,Buy_rate,Sell_rate,Resolution)
 expense = min(0,Pnet).*Buy_rate*Resolution ; % (minus sign)
 revenue = max(0,Pnet).*Sell_rate*Resolution ; % positive sign
 profit = revenue + expense ; 
end
function [PV,PL,Buy_rate,Sell_rate] = getProfile(fs,h,start_date,end_date,TOU_CHOICE)
    %k = h*fs; 
    PV_scale_factor = 1; % scale up from 8kW to 4*8
    moving_avg = kron(eye(h*fs),(1/(4/fs))*ones(1,4/fs));
    p = readmatrix('buy_sell_rate.xlsx');
    p = p(:,3:1:4);
    range = timerange(start_date,end_date);
    load = table2timetable(readtable('load_archive.csv'));
    load = load(range,13).Ptot_kW_; % change name according to col name
    
    solar = table2timetable(readtable('pv_archive.csv'));
    solar = PV_scale_factor*solar(range,7).Ptot_kW_; % change name according to col name

    PV = moving_avg*solar;
    PL = moving_avg*load;
%     Buy_rate = moving_avg*kron(ones(h/24,1) ,p(:,1));
%     Sell_rate = moving_avg*kron(ones(h/24,1) ,p(:,2));

    t1 = datetime(start_date); t2 = datetime(end_date); 
    vect = t1:minutes(60/fs):t2 ; vect(end) = []; vect = vect';
    vechour = hour(vect);

    switch TOU_CHOICE
        case 'smart1'
    % buy_rate = [0-10:00) 2THB, [10:00-14:00] 3THB (14:00-18:00) 5THB
    % [18:00-22:00] 7THB (22:00-24:00) 2THB
    % sell_rate = [18:00-22:00] 2.5THB and 2THB all other
    % times

    Buy_rate = 2*(vechour >= 0 & vechour < 10)+3*( vechour >= 10 & vechour <= 14 ) ...
        + 5*( vechour > 14 & vechour < 18) + 7*( vechour >= 18 & vechour <= 22) + 2*(vechour > 22 & vechour <= 23);
    Sell_rate = 2*ones(length(vechour),1); Sell_rate( vechour >= 18 & vechour <= 22) = 2.5 ;

        case 'nosell'
%             buyrate is just like case 'smart1' but customers cannot sell the power
        Buy_rate = 2*(vechour >= 0 & vechour < 10)+3*( vechour >= 10 & vechour <= 14 ) ...
        + 5*( vechour > 14 & vechour < 18) + 7*( vechour >= 18 & vechour <= 22) + 2*(vechour > 22 & vechour <= 23);
    Sell_rate = zeros(length(vechour),1); 

        case 'THcurrent'
    % Current rate  (not smart), sell_rate = 2 THB flat, 
    % buy_rate = 5.8 THB during [9:00-23:00] and 2.6 THB otherwise

    Buy_rate = 5.8*(vechour >= 9 & vechour <= 23) + 2.6*(vechour >= 0 & vechour < 9);
    Sell_rate = 2*ones(length(vechour),1);
    end
end

