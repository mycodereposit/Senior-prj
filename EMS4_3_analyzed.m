clear;clc;

dataset_detail = readtable('dataset/dataset_detail.csv');
dataset_name = dataset_detail.name;
pv_type = dataset_detail.solar_type;
load_type = dataset_detail.load_type;
dataset_startdate = dataset_detail.start_date;

for i = 1:length(dataset_name)
    sol = load(strcat('solution/EMS4_3/',dataset_name{i},'.mat'));
    
    
    neg_energy(i,1)   = -sum(min(sol.Pnet,0)*sol.PARAM.Resolution);
    
end
%%
a = table( neg_energy,...
            pv_type,...
            load_type);

%%
% energy < 0 hist plot
f = figure('PaperPosition',[0 0 21 20/3],'PaperOrientation','portrait','PaperUnits','centimeters');
t = tiledlayout(1,1,'TileSpacing','tight','Padding','tight');
plot_case = a;
nexttile;
histogram(plot_case.neg_energy,10,'BinWidth',50,'Normalization','percentage')
grid on
title('Histogram of negative energy in EMS 4')
xlabel('Negative energy (kWh)')
ylabel('Percent')
xticks(0:50:1250)
xlim([0 700])
ylim([0 100])
yticks(0:20:100)



fontsize(0.6,'centimeters')
% print(f,'graph/EMS1/png/EMS1_neg_energy_plot','-dpng')
% print(f,'graph/EMS1/eps/EMS1_neg_energy_plot','-deps')