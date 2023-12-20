clear;clc;

dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
pv_type = dataset_detail.pv_type;
load_type = dataset_detail.load_type;
dataset_startdate = dataset_detail.start_date;

for i = 1:48
    sol_thcurrent = load(strcat('solution/EMS1/','THcurrent','_',dataset_name{i},'.mat'));
    sol_smart = load(strcat('solution/EMS1/','smart1','_',dataset_name{i},'.mat'));
    
    networth_with_ems_thcurrent(i,1) = sum(-sol_thcurrent.u);
    networth_with_ems_smart(i,1) = sum(-sol_smart.u);
    networth_without_ems_thcurrent(i,1) = sum(sol_thcurrent.PARAM.Resolution*min(0,sol_thcurrent.PARAM.PV-sol_thcurrent.PARAM.PL).*sol_thcurrent.PARAM.Buy_rate);  
    networth_without_ems_smart(i,1) = sum(sol_smart.PARAM.Resolution*min(0,sol_smart.PARAM.PV-sol_smart.PARAM.PL).*sol_smart.PARAM.Buy_rate); 
    neg_energy_thcurrent(i,1)   = -sum(min(sol_thcurrent.Pnet,0)*sol_thcurrent.PARAM.Resolution);
    neg_energy_smart(i,1)       = -sum(min(sol_smart.Pnet,0)*sol_smart.PARAM.Resolution);
end
%%


expense_save_thcurrent = networth_with_ems_thcurrent - networth_without_ems_thcurrent;
expense_save_smart = networth_with_ems_smart - networth_without_ems_smart;
percent_save_thcurrent = -expense_save_thcurrent*100./networth_without_ems_thcurrent;
percent_save_smart = -expense_save_smart*100./networth_without_ems_smart;
a = table( neg_energy_thcurrent, ...
            neg_energy_smart,...
            percent_save_smart,...    
            percent_save_thcurrent,...
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
% energy < 0 hist plot
f = figure('PaperPosition',[0 0 21 20/3],'PaperOrientation','portrait','PaperUnits','centimeters');
t = tiledlayout(1,2,'TileSpacing','tight','Padding','tight');
plot_case = a;
nexttile;
histogram(plot_case.neg_energy_thcurrent,10,'BinWidth',50,'Normalization','percentage')
grid on
title('Histogram of negative energy in EMS 1 when TOU 0 is used')
xlabel('Negative energy (kWh)')
ylabel('Percent')
xticks(25:50:1250)
xlim([0 700])
ylim([0 100])
yticks(0:20:100)

nexttile;
histogram(plot_case.neg_energy_smart,10,'BinWidth',50,'Normalization','percentage')
grid on
title('Histogram of negative energy in EMS 1 when TOU 1 is used')
xlabel('Negative energy (kWh)')
ylabel('Percent')
xticks(25:50:1250)
xlim([0 700])
ylim([0 100])
yticks(0:20:100)

fontsize(0.6,'centimeters')
print(f,'graph/EMS1/png/EMS1_neg_energy_plot','-dpng')
print(f,'graph/EMS1/eps/EMS1_neg_energy_plot','-deps')

%%
% percentage histogram
pv_list = {'low_solar','low_solar','high_solar','high_solar'};
load_list  = {'high_load','low_load','high_load','low_load'};
for i = 1:4
    plot_case = a(strcmp(a.pv_type,pv_list{i}) & strcmp(a.load_type,load_list{i}),:);
    f = figure('Position', [0 0 2480 1000]);
    t = tiledlayout(2,2);


    nexttile;
    bar([-plot_case.networth_with_ems_thcurrent, -plot_case.networth_without_ems_thcurrent])
    grid on
    legend('with EMS 1','without EMS 1','Location','northeastoutside')
    title('Expense when TOU 0 is used ')
    ylabel('Expense (THB)')
    xlabel('Data set index')
    ylim([0 3500])
    yticks(0:500:3500)
    xticks(1:30)
    
    nexttile;
    histogram(plot_case.percent_save_thcurrent,10,'BinWidth',10,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 1 when TOU 0 is used')
    xlabel('Expense save (%)')
    ylabel('Percent')
    xticks(5:10:100)
    ylim([0 100])
    yticks(0:20:100)
    xlim([0 100])

    nexttile;
    bar([-plot_case.networth_with_ems_smart, -plot_case.networth_without_ems_smart])
    grid on
    legend('with EMS 1','without EMS 1','Location','northeastoutside')
    title('Expense when TOU 1 is used')
    ylabel('Expense (THB)')
    xlabel('Data set index')
    ylim([0 3500])
    yticks(0:500:3500)
    xticks(1:30)
    
    nexttile;
    histogram(plot_case.percent_save_smart,10,'BinWidth',10,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 1 when TOU 1 is used')
    xlabel('Expense save (%)')
    ylabel('Percent')
    xticks(5:10:100)
    yticks(0:20:100)
    ylim([0 100])
    xlim([0 100])
    fontsize(20,'points')
    exportgraphics(t,strcat('graph/EMS1/png/',pv_list{i},'_',load_list{i},'_bar_percent_hist.png'))
    exportgraphics(t,strcat('graph/EMS1/eps/',pv_list{i},'_',load_list{i},'_bar_percent_hist.eps'))
end
%% 
% actual hist

pv_list = {'low_solar','low_solar','high_solar','high_solar'};
load_list  = {'high_load','low_load','high_load','low_load'};
for i = 1:4
    
    plot_case = a(strcmp(a.pv_type,pv_list{i}) & strcmp(a.load_type,load_list{i}),:);

    f = figure('Position', [0 0 2480 1000]);
    t = tiledlayout(2,2);
    
    nexttile;
    bar([-plot_case.networth_with_ems_thcurrent, -plot_case.networth_without_ems_thcurrent])
    grid on
    legend('with EMS 1','without EMS 1','Location','northeastoutside')
    title('Expense when TOU 0 is used ')
    ylabel('Expense (THB)')
    xlabel('Data set index')
    ylim([0 3500])
    yticks(0:500:3500)
    xticks(1:30)
    
    nexttile;
    histogram(plot_case.expense_save_thcurrent,10,'BinWidth',100,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 1 when TOU 0 is used')
    xlabel('Expense save (THB)')
    ylabel('Percent')
    xticks(50:100:1250)
    ylim([0 100])
    yticks(0:20:100)
    xlim([0 1200])
    
     
    
    
    
    nexttile;
    bar([-plot_case.networth_with_ems_smart, -plot_case.networth_without_ems_smart])
    grid on
    legend('with EMS 1','without EMS 1','Location','northeastoutside')
    title('Expense when TOU 1 is used')
    ylabel('Expense (THB)')
    xlabel('Data set index')
    ylim([0 3500])
    yticks(0:500:3500)
    xticks(1:30)


    nexttile;
    histogram(plot_case.expense_save_smart,10,'BinWidth',100,'Normalization','percentage')
    grid on
    title('Histogram of expense save by EMS 1 when TOU 1 is used')
    xlabel('Expense save (THB)')
    ylabel('Percent')
    xticks(50:100:1250)
    yticks(0:20:100)
    ylim([0 100])
    xlim([0 1200])
    fontsize(20,'points')
    exportgraphics(t,strcat('graph/EMS1/png/',pv_list{i},'_',load_list{i},'_bar_actual_hist.png'))
    exportgraphics(t,strcat('graph/EMS1/eps/',pv_list{i},'_',load_list{i},'_bar_actual_hist.eps'))
    
    

   
end
