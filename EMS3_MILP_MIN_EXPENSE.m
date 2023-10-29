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
schedule_start = 8; %schedule start @ 13:00
schedule_stop = 16;  %schedule end @ 16:00
ACschedule = getSchedule(schedule_start,schedule_stop,Resolution,Horizon);
%get schedule for AC

nc = 0.95; %bes charge eff
nd = 0.95*0.93; %  bes discharge eff note inverter eff 0.93-0.96
dr = 1.5; % kW max discharge rate
cr = 2.5; % kW max charge rate
soc_capacity = 5; % kWh soc_capacity 
initial_soc = 50; % userdefined int 0-100 %
lb_soc = 40; %min soc userdefined int 0-100 %
ub_soc = 70; %max soc userdefined int 0-100 %
lambda = 10; %(THB) weight for encourage ac usage
Pac_rate = 3.59; % (kw) air conditioner input Power
Puload = min(PL) ;% (kW) power of uncontrollable load
% end of parameter part
%%
% optimize var = [Pnet u Pdchg xdchg Pchg xchg soc Pac Xac1 Xac2 Xac3 Xac4]


Pnet =      optimvar('Pnet',k,'LowerBound',-inf,'UpperBound',inf);
u =         optimvar('u',k,'LowerBound',0,'UpperBound',inf);
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
prob =      optimproblem('Objective',sum(u - (ACschedule*lambda).*(Xac1 + Xac2 + Xac3 + Xac4) ));

%constraint part
epicons = -Resolution*Buy_rate.*Pnet  <= u;
Paccons = Pac  == Pac_rate*(Xac1 + 0.5*Xac2 + 0.7*Xac3 + 0.8*Xac4);
ACcons1 = Xac1 + Xac2 + Xac3 + Xac4 <= 1;
ACcons2 = Xac1 + Xac2 + Xac3 + Xac4 >= 0;
chargecons = Pchg  <= xchg*cr;
dischargecons = Pdchg  <= xdchg*dr;
powercons = Pnet  == PV + Pdchg - Puload - Pac - Pchg;
NosimultDchgAndChgcons1 = xchg + xdchg >= 0;
NosimultDchgAndChgcons2 = xchg + xdchg <= 1;

%end of static constraint part

%recursive constraint part
soccons = optimconstr(k+1);
soccons(1) = soc(1)  == initial_soc;
soccons(2:k+1) = (100/soc_capacity)*soc(2:k+1)  == (100/soc_capacity)*soc(1:k) + (nc*100*Resolution/soc_capacity)*Pchg(1:k) - (Resolution*100/(nd*soc_capacity))*Pdchg(1:k);



prob.Constraints.epicons = epicons;
prob.Constraints.Paccons = Paccons;
prob.Constraints.ACcons1 = ACcons1;
prob.Constraints.ACcons2 = ACcons2;
prob.Constraints.chargecons = chargecons;
prob.Constraints.dischargecons = dischargecons;
prob.Constraints.powercons = powercons;
prob.Constraints.NosimultDchgAndChgcons1 = NosimultDchgAndChgcons1;
prob.Constraints.NosimultDchgAndChgcons2 = NosimultDchgAndChgcons2;
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


tiledlayout(5,2);

nexttile

stairs(vect,Buy_rate)
legend('Buy rate')
%set(gca,'YLim',[0 6])
xlabel('Hour') 
title('TOU') 
ylabel('TOU (THB)')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile

stairs(vect,sol.soc(1:k))
ylabel('SoC (%)')
title('State of charge (SoC)')
xlabel('Hour')
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
stairs(vect,PV) 
ylabel('Solar power (kW)')
hold on
yyaxis right

stairs(vect,Pload)
ylabel('Load (kW)')
legend('Solar','load')
title('Solar and load power')
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
stairs(vect,sol.Pnet,'k')
hold on
ylabel('Pnet(kW)')
title('Pnet(kW)') 
legend('P_{net}') 
grid on
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile
stem(vect,sol.xchg)
ylim([0,1])
hold on 
grid on
yyaxis right
stem(vect,sol.xdchg,'k')
legend('x_{chg}','x_{dchg}')
title('xchg  and xdchg')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
ylim([0,2])
hold off

nexttile
stairs(vect,[sol.Xac1+sol.Xac2+sol.Xac3+sol.Xac4,sol.Pac/Pac_rate])
hold on 
grid on
ylim([0 1.5])
legend('x_{ac}','Pac(%)')
title('Air Conditioner state and Power')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')
hold off

nexttile;
stairs(vect,cumsum(-expense)); ylabel('Expense (THB)')
title('Cumulative Expense')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')


nexttile
stairs(vect,PV)

hold on 
grid on
yyaxis right
stairs(vect,Pgen)
legend('PV','Pgen')
title('PV(kW)  and Pgen(kW)')
xlabel('Hour')
xticks(start_date:hours(3):end_date)
datetick('x','HH','keepticks')

hold off

function schedule = getSchedule(start,stop,Resolution,Horizon)
    schedule = zeros(24/Resolution,1);
    schedule(start*(1/Resolution):stop*(1/Resolution)) = 1;
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
    
    range = timerange(start_date,end_date);
    load = table2timetable(readtable('load_archive.csv'));
    load = load(range,10).Pa_kW_; % change name according to col name
    
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
function [sol] =  getPlotableSol(x,n)
    [nrow,ncol] = size(x);
    sol = zeros(n,nrow/n);

    for i = 0:(nrow/n)-1
        sol(:,i+1) = x(n*i+1:n*(i+1),1);
    end  
    sol = sol.';

%     sol2 = reshape(x,4*24*4,6); % need to check but it can only use
%     reshape
end
function [c24,intcon24,Ain24,Bin24,Aeq24,Beq24,lb24,ub24] = getLPConstraint(k,c,intcon,Ain,Bin,Aeq,Beq,lb,ub)
    [neq,nx] = size(Aeq);
    [nin,nx1] = size(Ain);
    [a,nintcon] = size(intcon);
    
    Ain24 = kron(eye(k),Ain);
    Bin24 = kron(ones(k,1),Bin);
    lb24 = kron(ones(k,1),lb);

    ub24 =  kron(ones(k,1),ub);

    Aeq24 = kron(eye(k),Aeq);
    Beq24 = kron(ones(k,1),Beq);
    c24 = kron(ones(1,k),c);
    
    
    intcon24 = zeros(1,nintcon*k);
    
    
    
    for i = 0:k-1 

        %get constraint
        
        
        intcon24(1,nintcon*i+1:nintcon*(i+1)) = nx*i + intcon;
       
    end

end