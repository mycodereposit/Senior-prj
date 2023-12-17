clear;clc;

dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
pv_type = dataset_detail.pv_type;
load_type = dataset_detail.load_type;
dataset_startdate = dataset_detail.start_date;


for i = 1:48
    sol_thcurrent = load(strcat('solution/EMS3_2/','THcurrent','_',dataset_name{i},'.mat'));
    sol_smart = load(strcat('solution/EMS3_2/','smart1','_',dataset_name{i},'.mat'));
    
    expense_with_ems_thcurrent(i,1) = sum(sol_thcurrent.u); %networth when we have ems3
    expense_with_ems_smart(i,1) = sum(sol_smart.u); %networth when we have ems3
    Pnet_thcurrent = sol_thcurrent.PARAM.PV - sol_thcurrent.PARAM.Puload - sol_thcurrent.Pac_lab - sol_thcurrent.Pac_student;
    Pnet_smart = sol_smart.PARAM.PV - sol_smart.PARAM.Puload - sol_smart.Pac_lab - sol_smart.Pac_student; %pnet when force ac to use the same load as ems
    
    expense_without_ems_thcurrent(i,1) = -sum(sol_thcurrent.PARAM.Buy_rate.*min(0,Pnet_thcurrent)*sol_thcurrent.PARAM.Resolution );
    expense_without_ems_smart(i,1) = -sum(sol_smart.PARAM.Buy_rate.*min(0,Pnet_smart)*sol_smart.PARAM.Resolution );
      
    
end

%%
expense_save_thcurrent = - expense_with_ems_thcurrent + expense_without_ems_thcurrent;
expense_save_smart = -expense_with_ems_smart + expense_without_ems_smart;
percent_save_thcurrent = expense_save_thcurrent*100./expense_without_ems_thcurrent;
percent_save_smart = expense_save_smart*100./expense_without_ems_smart;
a = table(percent_save_thcurrent,percent_save_smart,expense_with_ems_thcurrent,expense_with_ems_smart,expense_without_ems_thcurrent,expense_without_ems_smart,expense_save_thcurrent,expense_save_smart,pv_type,load_type);

% high_load = a(strcmp(a.load_type,'high_load'),:);
% low_load = a(strcmp(a.load_type,'low_load'),:);
% high_solar = a(strcmp(a.pv_type,'high_solar'),:);
% low_solar = a(strcmp(a.pv_type,'low_solar'),:);

%%
% percent hist
pv_list = {'low_solar','high_solar'};
for i = 1:2
    f = figure('Position', [0 0 2480 1000]);
    t = tiledlayout(2,2);
    plot_case = a(strcmp(a.pv_type,pv_list{i}),:);
    nexttile;
    bar([plot_case.expense_with_ems_thcurrent,plot_case.expense_without_ems_thcurrent])
    grid on
    yticks(0:100:700)
    ylim([0 700])
    legend('with EMS3','without EMS3','Location','northeastoutside')
    title('Expense when TOU 0 is used')
    ylabel('Expense (THB)')
    xlabel('Data set index')
    
    nexttile;
    histogram(plot_case.percent_save_thcurrent,10,'BinWidth',5,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 3 when TOU 0 is used')
    xlabel('Expense save (%)')
    ylabel('Percent')
    xticks(0:10:100)
    xlim([0 110])
    ylim([0 100])
    yticks(0:20:100)
    
    
    nexttile;
    bar([plot_case.expense_with_ems_smart,plot_case.expense_without_ems_smart])
    grid on
    yticks(0:100:700)
    ylim([0 700])
    legend('with EMS3','without EMS3','Location','northeastoutside')
    title('Expense when TOU 1 is used')
    ylabel('Expense (THB)')
    xlabel('Data set index')
    
    nexttile;
    histogram(plot_case.percent_save_smart,10,'BinWidth',5,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 3 when TOU 1 is used')
    xlabel('Expense save (%)')
    ylabel('Percent')
    xticks(0:10:100)
    xlim([0 110])
    ylim([0 100])
    yticks(0:20:100)
    fontsize(20,'points')
    exportgraphics(t,strcat('graph/EMS3_2/png/',pv_list{i},'_bar_percent_hist.png'))
    exportgraphics(t,strcat('graph/EMS3_2/eps/',pv_list{i},'_bar_percent_hist.eps'))
end
%%
% actual hist
pv_list = {'low_solar','high_solar'};
for i = 1:2
    f = figure('Position', [0 0 2480 1000]);
    t = tiledlayout(2,2);
    plot_case = a(strcmp(a.pv_type,pv_list{i}),:);
    
    nexttile;
    bar([plot_case.expense_with_ems_thcurrent,plot_case.expense_without_ems_thcurrent])
    grid on
    legend('with EMS3','without EMS3','Location','north')
    title('Expense when TOU 0 is used')
    ylabel('Expense (THB)')
    xlabel('Data set index')
    yticks(0:100:700)
    ylim([0 700])
    
    nexttile;
    histogram(plot_case.expense_save_thcurrent,10,'BinWidth',50,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 3 when TOU 0 is used')
    xlabel('Expense save (THB)')
    ylabel('Percent')
    xticks(175:50:600)
    xlim([150 600])
    ylim([0 100])
    yticks(0:20:100)
    
    nexttile;
    bar([plot_case.expense_with_ems_smart,plot_case.expense_without_ems_smart])
    grid on
    legend('with EMS3','without EMS3','Location','north')
    title('Expense when TOU 1 is used')
    ylabel('Expense (THB)')
    xlabel('Data set index')
    yticks(0:100:700)
    ylim([0 700])

    nexttile;
    histogram(plot_case.expense_save_smart,10,'BinWidth',50,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 3 when TOU 1 is used')
    xlabel('Expense save (THB)')
    ylabel('Percent')
    xticks(175:50:600)
    xlim([150 600])
    ylim([0 100])
    yticks(0:20:100)
    fontsize(20,'pixels')
    fontsize(20,'points')
    exportgraphics(t,strcat('graph/EMS3_2/png/',pv_list{i},'_bar_actual_hist.png'))
    exportgraphics(t,strcat('graph/EMS3_2/eps/',pv_list{i},'_bar_actual_hist.eps'))
end