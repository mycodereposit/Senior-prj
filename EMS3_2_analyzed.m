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
a = table(expense_with_ems_thcurrent,expense_with_ems_smart,expense_without_ems_thcurrent,expense_without_ems_smart,expense_save_thcurrent,expense_save_smart,pv_type,load_type);

high_load = a(strcmp(a.load_type,'high_load'),:);
low_load = a(strcmp(a.load_type,'low_load'),:);
high_solar = a(strcmp(a.pv_type,'high_solar'),:);
low_solar = a(strcmp(a.pv_type,'low_solar'),:);

%plot_case = a;
plot_case = low_load;
%plot_case = high_solar;
% plot_case = low_solar;


tiledlayout(2,3);

nexttile;
bar(1:length(plot_case.pv_type),[plot_case.expense_with_ems_thcurrent,plot_case.expense_without_ems_thcurrent])
grid on
legend('with EMS3(THB)','without EMS3(THB)','Location','northeastoutside')
title('expense when TOU THcurrent is used')
ylabel('expense(THB)')
%xticks(start_date:3:end_date)

nexttile;
histogram(plot_case.expense_with_ems_thcurrent,10)
title('histogram of expense by EMS3 when TOU is THcurrent')
xlabel('expense(THB)')
ylabel('count')
nexttile;
histogram(plot_case.expense_save_thcurrent,10)
title('histogram of expense save by EMS3 when TOU is THcurrent')
xlabel('expense save(THB)')
ylabel('count')

nexttile;
bar(1:length(plot_case.pv_type),[plot_case.expense_with_ems_smart,plot_case.expense_without_ems_smart])
grid on
legend('with EMS3(THB)','without EMS3(THB)','Location','northeastoutside')
title('expense when TOU smart is used')
ylabel('expense(THB)')
%xticks(start_date:3:end_date)

nexttile;
histogram(plot_case.expense_with_ems_smart,10)
title('histogram of networth by EMS3 when TOU is smart')
xlabel('expense(THB)')
ylabel('count')
nexttile;
histogram(plot_case.expense_save_smart,10)
title('histogram of expense save by EMS3 when TOU is smart')
xlabel('expense save(THB)')
ylabel('count')
%%
%plot_case = high_load;
%plot_case = low_load;
plot_case = low_solar;
%plot_case = high_solar;
f = figure('Position', [0 0 1920 1080]);
t = tiledlayout(2,2);

nexttile;
bar([plot_case.expense_with_ems_thcurrent,plot_case.expense_without_ems_thcurrent])
grid on
legend('with EMS3','without EMS3','Location','northeastoutside','FontSize',16)
title('Expense when TOU 0 is used','FontSize',16)
ylabel('Expense (THB)','FontSize',16)
xlabel('Data set index','FontSize',16)

nexttile;
histogram(plot_case.expense_save_thcurrent,10,'BinWidth',25)
grid on
title('Histogram of expense save by EMS 3 when TOU 0 is used','FontSize',16)
xlabel('Expense save (THB)','FontSize',16)
ylabel('Count','FontSize',16)
xticks(0:50:1250)
ylim([0 10])
yticks(0:2:24)
xlim([200 600])

nexttile;
bar([plot_case.expense_with_ems_smart,plot_case.expense_without_ems_smart])
grid on
legend('with EMS3','without EMS3','Location','northeastoutside','FontSize',16)
title('Expense when TOU 1 is used','FontSize',16)
ylabel('Expense (THB)','FontSize',16)
xlabel('Data set index','FontSize',16)

nexttile;
histogram(plot_case.expense_save_smart,10,'BinWidth',25)
grid on
title('Histogram of expense save by EMS 3 when TOU 1 is used','FontSize',16)
xlabel('Expense save (THB)','FontSize',16)
ylabel('Count','FontSize',16)
xticks(0:50:1250)
yticks(0:2:24)
ylim([0 10])
xlim([200 600])
exportgraphics(t,'graph/EMS3_2/low_solar_bar_hist.png')