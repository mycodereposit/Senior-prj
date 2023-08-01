%----max profit
Ts = 60; %sampling period(min) use 60 divisible number ie. 1 2 3 4 15 20 etc. int 1-60
h = 48; %optimization horizon(hr) int

Ts = Ts/60; %sampling period(Hr)
fs = 1/Ts; %sampling freq(1/Hr)

k = h*fs; %number of iteration int


%get solar/load profile and buy/sell rate
[PV,PL,Buy_rate,Sell_rate] = getProfile(fs,h);
%end of solar/load profile and buy/sell rate

%parameter part
nc = 0.95; %bes eff
nd = 0.95*0.93; % inverter eff 0.93-0.96
soc = 60; % 0-100 %
dr = 45; % kW max discharge rate
cr = 75; % kW max charge rate
max_soc = 150; % kWh soc_capacity 
initial_soc = 10; % userdefined int 0-100
lb_soc = 5; %min soc userdefined int 0-100
ub_soc = 70; %max soc userdefined int 0-100
% end of parameter part

%constraint part
c = [0 0 0 0 0 1];

Ain = [1 0  0 -cr  0  0;
       0 1  0  0 -dr 0;
       0 0  0 -1  -1 0;
       0 0  0  1   1 0;
       ];
Bin = [ 0; 
        0; 
        0; 
        1;
        
        ];

Aeq = [nc*Ts*100/max_soc -(Ts*100/max_soc)/nd 100/max_soc 0 0 0 ; ];
Beq = [0;];

lb = [0; 0; lb_soc; 0;0;-inf];
ub = [inf;inf;ub_soc;1;1;inf;];

intcon = [4 5];

[c24,intcon24,Ain24,Bin24,Aeq24,Beq24,lb24,ub24] = getLPConstraint(k,c,intcon,Ain,Bin,Aeq,Beq,lb,ub);

%end of static constraint part

%recursive constraint part
for i = 0:k-1 
    Aincom24(2*i+1:2*(i+1),6*i+1:6*(i+1) ) = [Buy_rate(i+1) Buy_rate(i+1)   0 0 0 -1;
                                              Sell_rate(i+1) -Sell_rate(i+1) 0 0 0 -1; ];
    Bincom24(2*i+1:2*(i+1),1) = [Sell_rate(i+1)*(PV(i+1)-PL(i+1)); 
                                 Buy_rate(i+1)*(PV(i+1)-PL(i+1));   ];
    Aeq24(i+1,6*(i+1)+3) = -100/max_soc;
    


end
Ain24 = [Ain24;
          Aincom24;  ];
Bin24 = [Bin24;
          Bincom24;  ];
% end of recursive constraint part  

% soc initial value
lb24(3) = initial_soc;
ub24(3) = initial_soc;
%end of soc initial value
% get solution
x = intlinprog(c24,intcon24,Ain24,Bin24,Aeq24(1:(k-1),1:6*k),Beq24(1:k-1),lb24,ub24);

%prepare for solution for plotting
opt24 = getPlotableSol(x,6);
%end of prepare for solution for plotting

%plotting part
t = Ts:Ts:h;
Pgen = opt24(:,2) + PV;
Pload = opt24(:,1) + PL;
Pnet = Pgen - Pload;
Expense = GetExpense(Pnet,Buy_rate,Sell_rate);



tiledlayout(4,2);
nexttile;
stairs(t,PV)
hold on
%--yyaxis right;
stairs(t,PL)
legend('Solar','load')

title('solar and load power')

nexttile;
stem(t,Buy_rate)
hold on
stem(t,Sell_rate)
legend('Buy rate','Sell rate')

nexttile;
stairs(t,opt24(:,1))
hold on
stairs(t,opt24(:,2))
legend('Pchg','Pdchg')
title('Pchg and Pdchg')
nexttile;
stem(t,opt24(:,3))
title('Soc(t)')
nexttile;

stem(t,opt24(:,4))
hold on
stem(t,opt24(:,5))
legend('xchg','xdchg')
title('xchg and xdchg')
nexttile;
stairs(t,Pnet)
title('Pnet=Pdchg + PV - PL -Pchg')

nexttile;

stairs(t,Pnet)

hold on 
stairs(t,Buy_rate)
hold on 
stairs(t,Sell_rate)

legend('Pnet' ,'Pgen' ,'Pload')
title('Pnet ,Pgen and Pload over time')

nexttile;
stairs(t,Pnet)

hold on 
stairs(t,Buy_rate)
hold on 
stairs(t,Sell_rate)
hold on 
stairs(t,Expense)
legend('Pnet' ,'Buy rate' ,'Sell rate', 'Expense')
title('Pnet ,Buy rate ,Sell rate and Expense over time')


% end of plotting part


%opt solution vector
%n number of var without iteration
%fs sampling freq(1/Hr)
%h horizon(Hr)
function expense = GetExpense(Pnet,Buy_rate,Sell_rate)
    [nrow,ncol] = size(Pnet);
    for i = 1:nrow
        if Pnet(i) < 0 
            expense(i) = Pnet(i)*Buy_rate(i);
        else
            expense(i) = Pnet(i)*Sell_rate(i);
        end
    end
end
function [PV,PL,Buy_rate,Sell_rate] = getProfile(fs,h)
    
    p = readmatrix('random load.xlsx');
    p = kron(ones(ceil(h/24),1),p);
    p = p(1:h,:);
    PV = kron( p(:,1) , ones(fs,1));
    PL = kron( p(:,2) , ones(fs,1));
    Buy_rate = kron( p(:,3) , ones(fs,1));
    Sell_rate = kron( p(:,4) ,ones(fs,1));
end
function sol =  getPlotableSol(x,n)
    [nrow,ncol] = size(x);
    sol = zeros(n,nrow/n);

    for i = 0:(nrow/n)-1
        sol(:,i+1) = x(n*i+1:n*(i+1),1);
    end  
    sol = sol.';
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