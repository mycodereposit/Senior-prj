clear;clc;
%%for THcurrent
dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
dataset_startdate = dataset_detail.start_date;

%TOU_CHOICE = 'smart1' ; % choice for tou 
%TOU_CHOICE = 'nosell' ;
%TOU_CHOICE = 'THcurrent' 
for i = 1:48
    sol_thcurrent = load(strcat('solution/EMS3_2/','THcurrent','_',dataset_name{i},'.mat'));
    sol_smart = load(strcat('solution/EMS3_2/','smart1','_',dataset_name{i},'.mat'));
    
    expense_with_ems_thcurrent(i) = sum(sol_thcurrent.u); %networth when we have ems3
    expense_with_ems_smart(i) = sum(sol_smart.u); %networth when we have ems3
    Pnet_thcurrent = sol_thcurrent.PARAM.PV - sol_thcurrent.PARAM.Puload - sol_thcurrent.Pac_lab - sol_thcurrent.Pac_student;
    Pnet_smart = sol_smart.PARAM.PV - sol_smart.PARAM.Puload - sol_smart.Pac_lab - sol_smart.Pac_student; %pnet when force ac to use the same load as ems
    
    expense_without_ems_thcurrent(i) = sum(sol_thcurrent.PARAM.Buy_rate.*min(0,Pnet_thcurrent)*sol_thcurrent.PARAM.Resolution );
    expense_without_ems_smart(i) = sum(sol_smart.PARAM.Buy_rate.*min(0,Pnet_smart)*sol_smart.PARAM.Resolution );
      
    
end

%%
expense_save_thcurrent = expense_with_ems_thcurrent - expense_without_ems_thcurrent;
expense_save_smart = expense_with_ems_smart - expense_without_ems_smart;
start_date = '2023-05-01';
start_date = datetime(start_date);
end_date = start_date + 30;
tiledlayout(4,2);
nexttile;
bar(dataset_startdate,[expense_with_ems_thcurrent',expense_without_ems_thcurrent'])
grid on
legend('expense with ems3(THB)','expense without ems3(THB)','Location','northeastoutside')
title('expense when TOU THcurrent is used ')
ylabel('expense(THB)')
%xticks(start_date:3:end_date)
datetick('x','DD-mmm','keepticks')


nexttile;
histogram(expense_with_ems_thcurrent,20)
title('histogram of expense by EMS3 when TOU is THcurrent')
xlabel('networth(THB)')

nexttile;
bar(dataset_startdate,[expense_with_ems_smart',expense_without_ems_smart'])
grid on
legend('expense with ems3(THB)','expense without ems3(THB)','Location','northeastoutside')
title('expense when TOU smart1 is used')
ylabel('expense(THB)')
xticks(start_date:3:end_date)
datetick('x','DD-mmm','keepticks')


nexttile;
histogram(expense_with_ems_smart,20)
title('histogram of expense by EMS2 when TOU is smart1')
xlabel('expense(THB)')

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