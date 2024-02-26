function [f,t] = EMS4_plot(sol,is_save,save_path)
    % sol -> solution from EMS1_opt
    % num_plot -> choose 6 or 8 plot
    PARAM = sol.PARAM;
    %----------------prepare solution for plotting
    k = 24*PARAM.Horizon/PARAM.Resolution;
    
    
    %expense = -min(0,sol.Pnet)*PARAM.Resolution.*PARAM.Buy_rate;
    %expense_noems = -min(0,PARAM.PV-PARAM.PL)*PARAM.Resolution.*PARAM.Buy_rate;
    
    Pload = sol.Pac_lab + PARAM.Puload + sol.Pac_student; % Load + Battery charge
    %Pac = sol.Pac_lab + sol.Pac_student;
    excess_gen = PARAM.PV - Pload;
    start_date = '2023-04-24';  %a start date for plotting graph
    start_date = datetime(start_date);
    end_date = start_date + PARAM.Horizon;    
    t1 = start_date; t2 = end_date; 
    vect = t1:minutes(PARAM.Resolution*60):t2 ; vect(end) = []; vect = vect';
    %end of prepare for solution for plotting
    % 6 plot
    
    
    f = figure('PaperPosition',[0 0 21 20],'PaperOrientation','portrait','PaperUnits','centimeters');
    t = tiledlayout(3,2,'TileSpacing','tight','Padding','tight');
    colororder({'r','r','r','r'})

    nexttile
    hold all
    stairs(vect,PARAM.PV,'-b','LineWidth',1.2) 
    stairs(vect,sol.PV,'-g','LineWidth',1.2) 
    ylim([0 10])
    yticks(0:2:10)
    ylabel('P_{pv} (kW)')
    grid on
    yyaxis right
    stairs(vect,Pload,'-r','LineWidth',1.2)
    ylim([0 10])
    yticks(0:2:10)
    ylabel('Load (kW)')
    legend('P_{pv}^{max}','P_{pv}','load','Location','northeastoutside')
    title('Solar generation (P_{pv}^{max}) and load consumption (P_{load} = P_{uload} + P_{ac,s} + P_{ac,m})')
    xlabel('Hour')
    xticks(start_date:hours(3):end_date)
    datetick('x','HH','keepticks')
    hold off
    
    nexttile
    stairs(vect,sol.soc(1:k),'k','LineWidth',1.5) 
    ylabel('SoC (%)')
    ylim([35 75])
    hold on
    stairs(vect,[40*ones(k,1),70*ones(k,1)],'--m','LineWidth',1.5,'HandleVisibility','off') 
    grid on
    hold on
    yyaxis right
    stairs(vect,Pload,'-r','LineWidth',1.2)
    ylim([0 10])
    yticks(0:2:10)
    ylabel('Load (kW)')
    legend('SoC','Load','Location','northeastoutside')
    title('State of charge (SoC) and load consumption (P_{uload} + P_{ac,s} + P_{ac,m})')
    xlabel('Hour')
    xticks(start_date:hours(3):end_date)
    datetick('x','HH','keepticks')
    hold off
    
    nexttile
    hold all
    stairs(vect,excess_gen,'-k','LineWidth',1.2) 
    grid on
    ylim([-10 10])
    yticks(-10:5:10)
    ylabel('Excess power (kW)')
    yyaxis right 
    stairs(vect,sol.xchg(:,1),'-b','LineWidth',1)
    stairs(vect,-sol.xdchg(:,1),'-r','LineWidth',1)
    legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
    title('Excess power = P_{pv} - P_{load} and Battery charge/discharge status')
    
    xlabel('Hour')
    xticks(start_date:hours(3):end_date)
    datetick('x','HH','keepticks')
    yticks(-2:1:2)
    ylim([-1.5,1.5])
    hold off
    
    nexttile
    stairs(vect,sol.Pac_lab*100/PARAM.AClab.Paclab_rate,'-r','LineWidth',1.2)
    ylim([0 100])
    ylabel('AC level (%)')
    yticks([0 50 70 80 100])
    hold on 
    grid on
    yyaxis right
    stairs(vect,PARAM.ACschedule,'-.k','LineWidth',1.2)
    ylim([0 1.5])
    yticks([0 1])
    legend('AC level','ACschedule')
    title('Lab AC level')
    xlabel('Hour')
    xticks(start_date:hours(3):end_date)
    datetick('x','HH','keepticks')
    hold off
    
    nexttile
    hold all
    stairs(vect,PARAM.PV,'-b','LineWidth',1.2) 
    stairs(vect,sol.PV,'-g','LineWidth',1.2)
    stairs(vect,sol.Pnet,'--k','LineWidth',1.2)
    grid on
    legend('P_{pv}^{max}','P_{pv}','P_{net} = 0','Location','northeastoutside')
    title('Solar generation (P_{pv}^{max}) and P_{pv}')
    xlabel('Hour')
    ylim([-10 10])
    yticks(-10:5:10)
    ylabel('P_{net} (kW)')
    xticks(start_date:hours(3):end_date)
    datetick('x','HH','keepticks')
    hold off
    
    
    nexttile
    stairs(vect,sol.Pac_student*100/PARAM.ACstudent.Pacstudent_rate,'-r','LineWidth',1.2)
    ylim([0 100])
    yticks([0 50 70 80 100])
    ylabel('AC level (%)')
    hold on 
    grid on
    yyaxis right
    stairs(vect,PARAM.ACschedule,'-.k','LineWidth',1.2)
    yticks([0 1])
    ylim([0 1.5])
    legend('AC level','ACschedule')
    title('Student AC level')
    xlabel('Hour')
    xticks(start_date:hours(3):end_date)
    datetick('x','HH','keepticks')
    hold off
    
    fontsize(0.6,'centimeters')
    
    
    % print(f,strcat('graph/EMS2/png/8_plot_',filename),'-dpng')
    % print(f,strcat('graph/EMS2/eps/8_plot_',filename),'-deps')
    if is_save == 1
        print(f,strcat(save_path,'/EMS4/png/6_plot_',sol.dataset_name(1:end-4)),'-dpng')
        print(f,strcat(save_path,'/EMS4/eps/6_plot_',sol.dataset_name(1:end-4)),'-deps')
    end
    


end