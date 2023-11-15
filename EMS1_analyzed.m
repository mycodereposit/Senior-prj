clear;clc;
%%for THcurrent
dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
dataset_startdate = dataset_detail.start_date;

%TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
%TOU_CHOICE = 'THcurrent' 
for i = 1:48
    sol_thcurrent = load(strcat('solution/EMS1/','THcurrent','_',dataset_name{i},'.mat'));
    sol_smart = load(strcat('solution/EMS1/','smart1','_',dataset_name{i},'.mat'));
    
    networth_with_ems_thcurrent(i) = sum(-sol_thcurrent.u);
    networth_with_ems_smart(i) = sum(-sol_smart.u);
    networth_without_ems_thcurrent(i) = sum(sol_thcurrent.PARAM.Resolution*min(0,sol_thcurrent.PARAM.PV-sol_thcurrent.PARAM.PL).*sol_thcurrent.PARAM.Buy_rate);  
    networth_without_ems_smart(i) = sum(sol_smart.PARAM.Resolution*min(0,sol_smart.PARAM.PV-sol_smart.PARAM.PL).*sol_smart.PARAM.Buy_rate); 
    
end
%%
expense_save_thcurrent = networth_with_ems_thcurrent - networth_without_ems_thcurrent;
expense_save_smart = networth_with_ems_smart - networth_without_ems_smart;
start_date = '2023-04-01';
start_date = datetime(start_date);
end_date = start_date + 30;
tiledlayout(4,2);
nexttile;
bar(dataset_startdate,[networth_with_ems_thcurrent',networth_without_ems_thcurrent'])
grid on
legend('networth with ems2(THB)','networth without ems2(THB)','Location','northeastoutside')
title('networth when TOU THcurrent is used')
ylabel('networth(THB)')
%xticks(start_date:3:end_date)
datetick('x','DD-mmm','keepticks')


nexttile;
histogram(networth_with_ems_thcurrent,20)
title('histogram of networth by EMS2 when TOU is THcurrent')
xlabel('networth(THB)')

nexttile;
bar(dataset_startdate,[networth_with_ems_smart',networth_without_ems_smart'])
grid on
legend('networth with ems2(THB)','networth without ems2(THB)','Location','northeastoutside')
title('networth when TOU smart1 is used')
ylabel('networth(THB)')
%xticks(start_date:3:end_date)
datetick('x','DD-mmm','keepticks')


nexttile;
histogram(networth_with_ems_smart,20)
title('histogram of profit gain by EMS2 when TOU is smart1')
xlabel('networth(THB)')

nexttile;
bar(dataset_startdate,[expense_save_thcurrent',expense_save_smart'])
grid on
legend('expense save by EMS when TOU is THcurrent','expense save by EMS when TOU is smart1','Location','northeastoutside')
title('expense save by EMS')
ylabel('expense save(THB)')
xticks(start_date:3:end_date)
datetick('x','DD-mmm','keepticks')

nexttile;
histogram(expense_save_thcurrent,20)
title('expense save by using EMS2 when TOU is THcurrent')
xlabel('expense save(THB)')
ylabel('count')
nexttile;

nexttile;
histogram(expense_save_smart,20)
title('expense save by EMS2 when TOU is smart1')
xlabel('expense save(THB)')
ylabel('count')