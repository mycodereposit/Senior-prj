
function [PV,PL] = loadPVandPLcsv(Resolution,name,PV_capacity)
    
    PV_scale_factor = PV_capacity/8; % scale up from 8kW to PV_capacity kW
    step = Resolution*4;
    source = strcat(name,'.csv');
    data = readtable(strcat('dataset/',name));
    PV = PV_scale_factor*data.PVtot;
    PL = data.PLtot;
    PV = PV(1:step:end);
    PL = PL(1:step:end);
  
end