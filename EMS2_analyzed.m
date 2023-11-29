clear;clc;
%%for THcurrent
dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
pv_type = dataset_detail.pv_type;
load_type = dataset_detail.load_type;
dataset_startdate = dataset_detail.start_date;

%TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
%TOU_CHOICE = 'THcurrent' 
for i = 1:48
    sol_thcurrent = load(strcat('solution/EMS2/','THcurrent','_',dataset_name{i},'.mat'));
    sol_smart = load(strcat('solution/EMS2/','smart1','_',dataset_name{i},'.mat'));
    
    networth_with_ems_thcurrent(i,1) = sum(-sol_thcurrent.u);
    networth_with_ems_smart(i,1) = sum(-sol_smart.u);
    networth_without_ems_thcurrent(i,1) = sum(GetExpense(sol_thcurrent.PARAM.PV-sol_thcurrent.PARAM.PL,...
                                        sol_thcurrent.PARAM.Buy_rate, ...
                                        sol_thcurrent.PARAM.Sell_rate, ...
                                        sol_thcurrent.PARAM.Resolution));  
    networth_without_ems_smart(i,1) = sum(GetExpense(sol_smart.PARAM.PV-sol_smart.PARAM.PL, ...
                                      sol_smart.PARAM.Buy_rate, ...
                                      sol_smart.PARAM.Sell_rate, ...
                                      sol_smart.PARAM.Resolution));  
    
end
%%
expense_save_thcurrent = networth_with_ems_thcurrent - networth_without_ems_thcurrent;
expense_save_smart = networth_with_ems_smart - networth_without_ems_smart;
percent_save_thcurrent = expense_save_thcurrent./networth_without_ems_thcurrent;
percent_save_smart = expense_save_smart./networth_without_ems_smart;
a = table(percent_save_thcurrent,...
            percent_save_smart,...
            networth_with_ems_thcurrent,...
            networth_with_ems_smart,...
            networth_without_ems_thcurrent,...
            networth_without_ems_smart,...
            expense_save_thcurrent,...
            expense_save_smart,...
            pv_type,...
            load_type);

low_solar_high_load = a(strcmp(a.pv_type,'low_solar') & strcmp(a.load_type,'high_load'),:);
low_solar_low_load = a(strcmp(a.pv_type,'low_solar') & strcmp(a.load_type,'low_load') ,:);
high_solar_high_load = a(strcmp(a.pv_type,'high_solar') & strcmp(a.load_type,'high_load') ,:);
high_solar_low_load = a(strcmp(a.pv_type,'high_solar') & strcmp(a.load_type,'low_load') ,:);

plot_case = a;
%plot_case = low_load;
%plot_case = high_solar;
%plot_case = low_solar;


tiledlayout(2,3);

nexttile;
bar(dataset_startdate,[plot_case.networth_with_ems_thcurrent,plot_case.networth_without_ems_thcurrent])
grid on
legend('with EMS2(THB)','without EMS2(THB)','Location','northeastoutside')
title('profit when TOU0 is used (+ profit - expense)')
ylabel('profit(THB)')
%xticks(start_date:3:end_date)

nexttile;
histogram(plot_case.networth_with_ems_thcurrent,10)
title('histogram of profit by EMS2 when TOU0 is used')
xlabel('profit(THB)')
ylabel('count')
nexttile;
histogram(plot_case.expense_save_thcurrent,10)
title('histogram of expense save by EMS2 when TOU0 is used')
xlabel('expense save(THB)')
ylabel('count')

nexttile;
bar(1:length(plot_case.pv_type),[plot_case.networth_with_ems_smart,plot_case.networth_without_ems_smart])
grid on
legend('with EMS2(THB)','without EMS2(THB)','Location','northeastoutside')
title('profit when TOU1 is used (+ profit - expense)')
ylabel('profit(THB)')
%xticks(start_date:3:end_date)

nexttile;
histogram(plot_case.networth_with_ems_smart,10)
title('histogram of profit by EMS2 when TOU1 is used')
xlabel('profit(THB)')
ylabel('count')

nexttile;
histogram(plot_case.expense_save_smart,10)
title('histogram of expense save by EMS2 when TOU1 is used')
xlabel('expense save(THB)')
ylabel('count')
%%


pv_list = {'low_solar','low_solar','high_solar','high_solar'};
load_list  = {'high_load','low_load','high_load','low_load'};
for i = 1:4
    plot_case = a(strcmp(a.pv_type,pv_list{i}) & strcmp(a.load_type,load_list{i}),:);
    f = figure('Position', [0 0 1920 1080]);

    t = tiledlayout(2,2);

    nexttile;
    bar([plot_case.networth_with_ems_thcurrent, plot_case.networth_without_ems_thcurrent])
    grid on
    legend('with EMS 2','without EMS 2','Location','northeastoutside','FontSize',16)
    title('Profit when TOU 0 is used (profit + expense -)','FontSize',16)
    ylabel('Profit (THB)','FontSize',16)
    xlabel('Data set index','FontSize',16)

    nexttile;
    histogram(plot_case.expense_save_thcurrent,10,'BinWidth',50)
    grid on
    title('Histogram of expense save by EMS 2 when TOU 0 is used','FontSize',16)
    xlabel('Expense save (THB)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(75:50:1250)
    ylim([0 12])
    yticks(0:2:24)
    xlim([200 900])


    nexttile;
    bar([plot_case.networth_with_ems_smart, plot_case.networth_without_ems_smart])
    grid on
    legend('with EMS 2','without EMS 2','Location','northeastoutside','FontSize',16)
    title('Profit when TOU 1 is used (profit + expense -)','FontSize',16)
    ylabel('Profit (THB)','FontSize',16)
    xlabel('Data set index','FontSize',16)


    nexttile;
    histogram(plot_case.expense_save_smart,10,'BinWidth',50)
    grid on
    title('Histogram of expense save by EMS 2 when TOU 1 is used','FontSize',16)
    xlabel('Expense save (THB)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(75:50:1250)
    yticks(0:2:24)
    ylim([0 12])
    xlim([200 900])
    %exportgraphics(t,'graph/EMS2/low_solar_high_load_bar_hist.png')
end
%%
% percentage histogram
pv_list = {'low_solar','low_solar','high_solar','high_solar'};
load_list  = {'high_load','low_load','high_load','low_load'};

for i = 1:4
    
    plot_case = a(strcmp(a.pv_type,pv_list{i}) & strcmp(a.load_type,load_list{i}),:);

    f = figure('Position', [0 0 1920 1080]);
    t = tiledlayout(2,3);
    
    nexttile;
    bar([plot_case.networth_with_ems_thcurrent, plot_case.networth_without_ems_thcurrent])
    grid on
    legend('with EMS 2','without EMS 2','Location','best','FontSize',16)
    title('Profit when TOU 0 is used (profit + expense -)','FontSize',16)
    ylabel('Profit (THB)','FontSize',16)
    xlabel('Data set index','FontSize',16)
    ylim([-3500 1000])
    nexttile;
    histogram(plot_case.expense_save_thcurrent,10,'BinWidth',50)
    grid on
    title('Histogram of expense save by EMS 2 when TOU 0 is used','FontSize',16)
    xlabel('Expense save (THB)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(75:50:1250)
    ylim([0 12])
    yticks(0:2:24)
    xlim([200 900])
    
    
    nexttile;
    histogram(-plot_case.percent_save_thcurrent,10,'BinWidth',0.1)
    grid on
    title('Histogram of expense save by EMS 2 when TOU 0 is used','FontSize',16)
    xlabel('Expense save (%)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(0.05:0.1:1.35)
    ylim([0 12])
    yticks(0:2:16)
    xlim([0 1.4])
    
    nexttile;
    bar([plot_case.networth_with_ems_smart, plot_case.networth_without_ems_smart])
    grid on
    legend('with EMS 2','without EMS 2','Location','best','FontSize',16)
    title('Profit when TOU 1 is used (profit + expense -)','FontSize',16)
    ylabel('Profit (THB)','FontSize',16)
    xlabel('Data set index','FontSize',16)
    ylim([-3500 1000])

    nexttile;
    histogram(plot_case.expense_save_smart,10,'BinWidth',50)
    grid on
    title('Histogram of expense save by EMS 2 when TOU 1 is used','FontSize',16)
    xlabel('Expense save (THB)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(75:50:1250)
    yticks(0:2:24)
    ylim([0 12])
    xlim([200 900])
    
    
    nexttile;
    histogram(-plot_case.percent_save_smart,10,'BinWidth',0.1)
    grid on
    title('Histogram of expense save by EMS 2 when TOU 1 is used','FontSize',16)
    xlabel('Expense save (%)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(0.05:0.1:1.35)
    yticks(0:2:16)
    ylim([0 12])
    xlim([0 1.4])

    exportgraphics(t,strcat('graph/EMS2/',pv_list{i},'_',load_list{i},'_percent_bar_hist.png'))
end





%%
start_date = '2023-04-24';  %a start date for plotting graph
start_date = datetime(start_date);
end_date = start_date + 4;
t1 = start_date; t2 = end_date; 
vect = t1:minutes(15):t2 ; vect(end) = []; vect = vect';
b = tiledlayout(1,2);
nexttile
stairs(vect,sol_thcurrent.PARAM.Buy_rate,'-b','LineWidth',1.2)
hold on
grid on
stairs(vect,sol_thcurrent.PARAM.Sell_rate,'-r','LineWidth',1.2)
legend('Buy rate','Sell rate','Location','northeastoutside','FontSize',20)
%set(gca,'YLim',[0 6])
xlabel('Hour','FontSize',20) 
title('TOU 0','FontSize',20) 
ylabel('TOU (THB)','FontSize',20)
xticks(start_date:hours(1):end_date)
ylim([0 8])
xlim([start_date start_date+1])
datetick('x','HH','keepticks')

nexttile
stairs(vect,sol_smart.PARAM.Buy_rate,'-b','LineWidth',1.2)
hold on
grid on
stairs(vect,sol_smart.PARAM.Sell_rate,'-r','LineWidth',1.2)
legend('Buy rate','Sell rate','Location','northeastoutside','FontSize',20)
%set(gca,'YLim',[0 6])
xlabel('Hour','FontSize',20) 
title('TOU 1','FontSize',20) 
ylabel('TOU (THB)','FontSize',20)
ylim([0 8])
xticks(start_date:hours(1):end_date)
xlim([start_date start_date+1])
datetick('x','HH','keepticks')