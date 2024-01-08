clear;clc;

dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
pv_type = dataset_detail.solar_type;
load_type = dataset_detail.load_type;
dataset_startdate = dataset_detail.start_date;

for i = 1:length(dataset_name)
    sol_thcurrent_1batt = load(strcat('solution/EMS1/1batt/','THcurrent','_',dataset_name{i},'.mat'));
    sol_smart_1batt = load(strcat('solution/EMS1/1batt/','smart1','_',dataset_name{i},'.mat'));
    sol_thcurrent_2batt = load(strcat('solution/EMS1/2batt/','THcurrent','_',dataset_name{i},'.mat'));
    sol_smart_2batt = load(strcat('solution/EMS1/2batt/','smart1','_',dataset_name{i},'.mat'));
    networth_1batt_thcurrent(i,1) = sum(-sol_thcurrent_1batt.u);
    networth_1batt_smart(i,1) = sum(-sol_smart_1batt.u);
    networth_2batt_thcurrent(i,1) = sum(-sol_thcurrent_2batt.u);
    networth_2batt_smart(i,1) = sum(-sol_smart_2batt.u);
end
%%
th_diff = all(networth_1batt_thcurrent - networth_2batt_thcurrent <= 1e-2); % 1 mean no different
smart_diff = all(networth_1batt_smart - networth_2batt_smart <= 1e-2);