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
    sol_thcurrent = load(strcat('solution/EMS1/','THcurrent','_',dataset_name{i},'.mat'));
    sol_smart = load(strcat('solution/EMS1/','smart1','_',dataset_name{i},'.mat'));
    
    networth_with_ems_thcurrent(i,1) = sum(-sol_thcurrent.u);
    networth_with_ems_smart(i,1) = sum(-sol_smart.u);
    networth_without_ems_thcurrent(i,1) = sum(sol_thcurrent.PARAM.Resolution*min(0,sol_thcurrent.PARAM.PV-sol_thcurrent.PARAM.PL).*sol_thcurrent.PARAM.Buy_rate);  
    networth_without_ems_smart(i,1) = sum(sol_smart.PARAM.Resolution*min(0,sol_smart.PARAM.PV-sol_smart.PARAM.PL).*sol_smart.PARAM.Buy_rate); 
    
end
%%


expense_save_thcurrent = networth_with_ems_thcurrent - networth_without_ems_thcurrent;
expense_save_smart = networth_with_ems_smart - networth_without_ems_smart;
percent_save_thcurrent = expense_save_thcurrent./networth_without_ems_thcurrent;
percent_save_smart = expense_save_smart./networth_without_ems_smart;
a = table(percent_save_smart,...
            percent_save_thcurrent,...
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




% tiledlayout(2,3);
% 
% nexttile;
% bar(1:length(plot_case.pv_type),[plot_case.networth_with_ems_thcurrent,plot_case.networth_without_ems_thcurrent])
% grid on
% legend('with ems1(THB)','without ems1(THB)','Location','northeastoutside')
% title('profit when TOU0 is used (+ profit - expense)')
% ylabel('profit(THB)')
% %xticks(start_date:3:end_date)
% 
% nexttile;
% histogram(plot_case.networth_with_ems_thcurrent,10)
% title('histogram of profit by EMS1 when TOU0 is used')
% xlabel('profit(THB)')
% ylabel('count')
% nexttile;
% histogram(plot_case.expense_save_thcurrent,10)
% title('histogram of expense save by EMS1 when TOU0 is used')
% xlabel('expense save(THB)')
% ylabel('count')
% 
% nexttile;
% bar(1:length(plot_case.pv_type),[plot_case.networth_with_ems_smart,plot_case.networth_without_ems_smart])
% grid on
% legend('with ems1(THB)','without ems1(THB)','Location','northeastoutside')
% title('profit when TOU1 is used (+ profit - expense)')
% ylabel('profit(THB)')
% %xticks(start_date:3:end_date)
% 
% nexttile;
% histogram(plot_case.networth_with_ems_smart,10)
% title('histogram of profit by EMS1 when TOU1 is used')
% xlabel('profit(THB)')
% ylabel('count')
% nexttile;
% histogram(plot_case.expense_save_smart,10)
% title('histogram of expense save by EMS1 when TOU1 is used')
% xlabel('expense save(THB)')
% ylabel('count')
%%
%plot_case = low_solar_high_load;
%plot_case = low_solar_low_load;
%plot_case = high_solar_high_load;

pv_list = {'low_solar','low_solar','high_solar','high_solar'};
load_list  = {'high_load','low_load','high_load','low_load'};
for i = 1:4
    plot_case = a(strcmp(a.pv_type,pv_list{i}) & strcmp(a.load_type,load_list{i}),:);
    f = figure('Position', [0 0 1920 1080]);
    t = tiledlayout(2,2);


    nexttile;
    bar([-plot_case.networth_with_ems_thcurrent, -plot_case.networth_without_ems_thcurrent])
    grid on
    legend('with EMS 1','without EMS 1','Location','bestoutside','FontSize',16)
    title('Expense when TOU 0 is used ','FontSize',16)
    ylabel('Expense (THB)','FontSize',16)
    xlabel('Data set index','FontSize',16)
    ylim([0 3500])
    nexttile;
    histogram(plot_case.expense_save_thcurrent,10,'BinWidth',100)
    grid on
    title('Histogram of expense save by EMS 1 when TOU 0 is used','FontSize',16)
    xlabel('Expense save (THB)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(50:100:1250)
    ylim([0 12])
    yticks(0:2:16)
    xlim([0 1200])

    nexttile;
    bar([-plot_case.networth_with_ems_smart, -plot_case.networth_without_ems_smart])
    grid on
    legend('with EMS 1','without EMS 1','Location','bestoutside','FontSize',16)
    title('Expense when TOU 1 is used','FontSize',16)
    ylabel('Expense (THB)','FontSize',16)
    xlabel('Data set index','FontSize',16)
    ylim([0 3500])


    nexttile;
    histogram(plot_case.expense_save_smart,10,'BinWidth',100)
    grid on
    title('Histogram of expense save by EMS 1 when TOU 1 is used','FontSize',16)
    xlabel('Expense save (THB)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(50:100:1250)
    yticks(0:2:16)
    ylim([0 12])
    xlim([0 1200])
    exportgraphics(t,strcat('graph/EMS1/',pv_list{i},'_',load_list{i},'_bar_hist.png'))
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
    bar([-plot_case.networth_with_ems_thcurrent, -plot_case.networth_without_ems_thcurrent])
    grid on
    legend('with EMS 1','without EMS 1','Location','northwest','FontSize',16)
    title('Expense when TOU 0 is used ','FontSize',16)
    ylabel('Expense (THB)','FontSize',16)
    xlabel('Data set index','FontSize',16)
    ylim([0 3500])
    
    nexttile;
    histogram(plot_case.expense_save_thcurrent,10,'BinWidth',100)
    grid on
    title('Histogram of expense save by EMS 1 when TOU 0 is used','FontSize',16)
    xlabel('Expense save (THB)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(50:100:1250)
    ylim([0 12])
    yticks(0:2:16)
    xlim([0 1200])
    
     
    nexttile;
    histogram(-plot_case.percent_save_thcurrent,10,'BinWidth',0.1)
    grid on
    title('Histogram of expense save by EMS 1 when TOU 0 is used','FontSize',16)
    xlabel('Expense save (%)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(0.05:0.1:1)
    ylim([0 8])
    yticks(0:2:16)
    xlim([0 1])
    
    
    nexttile;
    bar([-plot_case.networth_with_ems_smart, -plot_case.networth_without_ems_smart])
    grid on
    legend('with EMS 1','without EMS 1','Location','northwest','FontSize',16)
    title('Expense when TOU 1 is used','FontSize',16)
    ylabel('Expense (THB)','FontSize',16)
    xlabel('Data set index','FontSize',16)
    ylim([0 3500])


    nexttile;
    histogram(plot_case.expense_save_smart,10,'BinWidth',100)
    grid on
    title('Histogram of expense save by EMS 1 when TOU 1 is used','FontSize',16)
    xlabel('Expense save (THB)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(50:100:1250)
    yticks(0:2:16)
    ylim([0 12])
    xlim([0 1200])
    exportgraphics(t,strcat('graph/EMS1/',pv_list{i},'_',load_list{i},'_bar_hist.png'))
    
    
    nexttile;
    histogram(-plot_case.percent_save_smart,10,'BinWidth',0.1)
    grid on
    title('Histogram of expense save by EMS 1 when TOU 1 is used','FontSize',16)
    xlabel('Expense save (%)','FontSize',16)
    ylabel('Count','FontSize',16)
    xticks(0.05:0.1:1)
    yticks(0:2:16)
    ylim([0 8])
    xlim([0 1])

    exportgraphics(t,strcat('graph/EMS1/',pv_list{i},'_',load_list{i},'_percent_bar_hist.png'))
end
