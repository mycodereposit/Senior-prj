clear;clc;

dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
pv_type = dataset_detail.pv_type;
load_type = dataset_detail.load_type;
dataset_startdate = dataset_detail.start_date;


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
percent_save_thcurrent = -expense_save_thcurrent*100./networth_without_ems_thcurrent;
percent_save_smart = -expense_save_smart*100./networth_without_ems_smart;
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

% low_solar_high_load = a(strcmp(a.pv_type,'low_solar') & strcmp(a.load_type,'high_load'),:);
% low_solar_low_load = a(strcmp(a.pv_type,'low_solar') & strcmp(a.load_type,'low_load') ,:);
% high_solar_high_load = a(strcmp(a.pv_type,'high_solar') & strcmp(a.load_type,'high_load') ,:);
% high_solar_low_load = a(strcmp(a.pv_type,'high_solar') & strcmp(a.load_type,'low_load') ,:);
%%
% get percentage profit and expense
expense_case = a(a.networth_with_ems_thcurrent < 0 & a.networth_without_ems_thcurrent < 0,:);
profit_case = a(a.networth_with_ems_thcurrent > 0 & a.networth_without_ems_thcurrent > 0,:);

%%
% absolute plot

pv_list = {'low_solar','low_solar','high_solar','high_solar'};
load_list  = {'high_load','low_load','high_load','low_load'};
for i = 1:4
    plot_case = a(strcmp(a.pv_type,pv_list{i}) & strcmp(a.load_type,load_list{i}),:);
    f = figure('Position', [0 0 2480 1000]);
    t = tiledlayout(2,2);

    nexttile;
    bar([plot_case.networth_with_ems_thcurrent, plot_case.networth_without_ems_thcurrent])
    grid on
    legend('with EMS 2','without EMS 2','Location','northeastoutside')
    title('Profit when TOU 0 is used (profit + expense -)')
    ylabel('Profit (THB)')
    xlabel('Data set index')
    ylim([-3500 1000])
    yticks(-3500:500:1000)

    nexttile;
    histogram(plot_case.expense_save_thcurrent,10,'BinWidth',50,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 2 when TOU 0 is used')
    xlabel('Expense save (THB)')
    ylabel('Percent')
    xticks(75:50:1250)
    xlim([100 900])
    ylim([0 100])
    yticks(0:20:100)


    nexttile;
    bar([plot_case.networth_with_ems_smart, plot_case.networth_without_ems_smart])
    grid on
    legend('with EMS 2','without EMS 2','Location','northeastoutside')
    title('Profit when TOU 1 is used (profit + expense -)')
    ylabel('Profit (THB)')
    xlabel('Data set index')
    ylim([-3500 1000])
    yticks(-3500:500:1000)

    nexttile;
    histogram(plot_case.expense_save_smart,10,'BinWidth',50,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 2 when TOU 1 is used')
    xlabel('Expense save (THB)')
    ylabel('Percent')
    xticks(75:50:1250)
    xlim([100 900])
    ylim([0 100])
    yticks(0:20:100)
    fontsize(20,'points')
    exportgraphics(t,strcat('graph/EMS2/png/',pv_list{i},'_',load_list{i},'_bar_percent_hist.png'))
    exportgraphics(t,strcat('graph/EMS2/eps/',pv_list{i},'_',load_list{i},'_bar_percent_hist.eps'))
end
%%
% percentage histogram
pv_list = {'low_solar','low_solar','high_solar','high_solar'};
load_list  = {'high_load','low_load','high_load','low_load'};

for i = 1:4
    
    plot_case = a(strcmp(a.pv_type,pv_list{i}) & strcmp(a.load_type,load_list{i}),:);

    f = figure('Position', [0 0 1920 1080]);
    t = tiledlayout(2,2);
    
    nexttile;
    bar([plot_case.networth_with_ems_thcurrent, plot_case.networth_without_ems_thcurrent])
    grid on
    legend('with EMS 2','without EMS 2','Location','best')
    title('Profit when TOU 0 is used (profit + expense -)')
    ylabel('Profit (THB)')
    xlabel('Data set index')
    ylim([-3500 1000])
    
    nexttile;
    histogram(plot_case.percent_save_thcurrent,10,'BinWidth',10,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 2 when TOU 0 is used')
    xlabel('Expense save (%)')
    ylabel('Percent')
    xticks(5:10:140)
    ylim([0 100])
    yticks(0:20:100)
    xlim([0 140])
    
    
    nexttile;
    bar([plot_case.networth_with_ems_smart, plot_case.networth_without_ems_smart])
    grid on
    legend('with EMS 2','without EMS 2','Location','best')
    title('Profit when TOU 1 is used (profit + expense -)')
    ylabel('Profit (THB)')
    xlabel('Data set index')
    ylim([-3500 1000])

       
    
    nexttile;
    histogram(plot_case.percent_save_smart,10,'BinWidth',10,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 2 when TOU 1 is used')
    xlabel('Expense save (%)')
    ylabel('Percent')
    xticks(5:10:140)
    yticks(0:20:100)
    ylim([0 100])
    xlim([0 140])
    fontsize(20,'pixels')

    fontsize(20,'points')
    exportgraphics(t,strcat('graph/EMS2/png/',pv_list{i},'_',load_list{i},'_bar_actual_hist.png'))
    exportgraphics(t,strcat('graph/EMS2/eps/',pv_list{i},'_',load_list{i},'_bar_actual_hist.eps'))
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