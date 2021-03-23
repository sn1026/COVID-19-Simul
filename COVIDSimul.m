%% Global Variables
Boston_Density = 13936;
MA_pop = 6893000;
MA_vac = 1069066;
MA_inf = 27341; %Currently active COVID cases
MA_risk = MA_pop - MA_vac - MA_inf; % Population at risk for infection
Vac_Boston = round((MA_vac/MA_pop)*Boston_Density);
Inf_Boston = round((MA_inf/MA_pop)*Boston_Density);
Risk_Boston = round((MA_risk/MA_pop)*Boston_Density);


%Coordinates for active COVID-cases in Boston
x_inf = linspace(0,1609.34,Inf_Boston);
y_inf = rand(1,Inf_Boston)*1609.34;

%Coordinates for vaccinated population in Boston
x_vac = linspace(0,1609.34,Vac_Boston);
y_vac = rand(1,Vac_Boston)*1609.34;

%Coordinates for at-risk population in Boston
x_risk = linspace(0,1609.34,Risk_Boston);
y_risk = rand(1,Risk_Boston)*1609.34;

%% Plotting
figure;

hold on;
scatter(x_inf, y_inf, 1, 'k','.', 'MarkerEdgeColor', 'red');
scatter(x_vac, y_vac, 1, 'k','.', 'MarkerEdgeColor', 'green');
scatter(x_risk, y_risk, 1, 'k','.', 'MarkerEdgeColor', 'blue');
hold off;

axis([0 1609.34 0 1609.34]);
box on;
set(gca,'xtick',[])
set(gca,'ytick',[])
title('COVID-19 Simulation for Boston Area');
legend('Infected','Vaccinated','At Risk');