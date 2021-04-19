%%Clean the interface
clear;
clc;

%% Global Variables

%Time Specific
Simul_Time          = 90;                                       % Total duration (in days) of the simulation.
dT                  = 0.02083*3;                                % How fast time will accelerate for the simulation. Currently set to 30min.
Time_Interval       = Simul_Time/dT;                            % # of times the code will iterate during computation
Time                = linspace(0,Simul_Time,Time_Interval);     % Create a vector to keep track of time.

%Map Specific
Map_Bound           = 600;                                      % Size of the Map.  In our case, its 5280 feet because we're doing 1 mi^2
Boston_Density      = 200;                                      % Population Density of Boston/sq. mi
SD_Prop             = 0.4;                                      % Percentage of the Population opting for social distancing

%COVID Specific
Initial_Infect      = 0.03;                                     % Percentage of population infected with COVID at the start of simulation
Infect_Rate         = 0.66;                                     % Likelihood of infection upon contact.
Infect_Radius       = 6;                                        % Infection radius =  6 feet
Mortality_Rate      = 0.026;                                    % Likelihood of death if infected.
Avg_Recovery_Time   = 15;                                       % Average time (in days) to recover from COVID.
Recovery_Time       = ceil(Avg_Recovery_Time ...                % The actual time a person will take to recover from COVID.
                      + 5*randn(Boston_Density,1))/dT;
                  
% Vaccine Specific
Initial_Vaccine     = 0;                                        % Percentage of population vaccinated at the start of simulation
Avg_Vaccine_Time    = 30;                                       % Average time (in days) to receive a vaccine
Vaccine_Time       = ceil(Avg_Vaccine_Time ...                  % The actual time a person will take to get vaccinated
                      + 10*randn(Boston_Density,1))/dT;

%Population Specific
Infect              = rand(Boston_Density,1) < Initial_Infect;  % Initially random people with COVID.
Susceptible         = ~Infect;                                  % Everyone else that has not contracted COVID is susceptible.
Vaccine             = zeros(Boston_Density,1);                  % Create a vector to keep track of vaccinated
Recover             = zeros(Boston_Density,1);                  % Create a vector to keep track of recovered
Dead                = zeros(Boston_Density,1);                  % Create a vector to keep track of deceased.
Dead_Chance         = rand(Boston_Density,1) < Mortality_Rate;  % Infected random people with COVID have a chance of dying.
Infect_Percent      = zeros(ceil(Time_Interval),1);             % Create a vector to keep track of infected population percentage.
Susceptible_Percent = zeros(ceil(Time_Interval),1);             % Create a vector to keep track of susceptible population percentage.
Vaccine_Percent     = zeros(ceil(Time_Interval),1);             % Create a vector to keep track of infected population percentage.
Recover_Percent     = zeros(ceil(Time_Interval),1);             % Create a vector to keep track of recovered population percentage.
Dead_Percent        = zeros(ceil(Time_Interval),1);             % Create a vector to keep track of dead population percentage.

%Initial Movement Setup
Speed               = 20;                                       % How fast (in ft/dT) each person is initially moving.  Currently set to 20 feet / 30min.
Social_Distance     = rand(Boston_Density,1) < SD_Prop;         % Identifies which people will be socially distancing.
Position            = rand(Boston_Density,2) * (Map_Bound);     % Where each 'person' will spawn in on the map.
Direction           = rand(Boston_Density,1) * 2 * pi;          % Direction each 'person' will be moving.
Move_Speed          = [Speed.*cos(Direction), ...               % How fast each 'person' is moving, given a direction.
                       Speed.*sin(Direction)];                                 
Collision           = zeros(Boston_Density, Boston_Density);    % Create an array to keep track of people bumping into each other.
Collision_Delay     = ceil(1/dT);                               % Collision delay
Video_capture       = true;                                     % Save video?
filename_video      = 'Simulation.avi';                              % Video filename

% Initialize videowriter
if Video_capture
    video = VideoWriter(filename_video,'Uncompressed AVI');
    open(video);
end

%% Computation
for a = 1:Time_Interval
    %% Infected Individual Checks
    for i = 1:1:Boston_Density
        
        if Infect(i)                                            % Checking if the infected individual recovered or died.  
                                                                % Has COVID recovery time elapsed?
                                                
            if Recovery_Time(i) <= 0                            % If YES:
                if Dead_Chance(i)                               % Case 1: They're dead.
                    Dead(i)   = 1;                              % Set their state to dead.
                    Infect(i) = 0;                              % They're no longer infected.
                    Move_Speed(i,:) = [0 0];                    % The dead are no longer mobile.
                    
                else                                            % Case 2: They're recovered.
                    Recover(i) = 1;                             % Set their state to recovered.
                    Infect(i)  = 0;                             % They're no longer infected.
                end
                
            else                                                % If NO:
                Recovery_Time(i) = Recovery_Time(i) - 1;        % Decrement their remaining recovery time for the next check.
            end
        end
        
        if Susceptible(i)                                       % Checking if the susceptible individual received a vaccine.
                                                                %Is it their time to get a vaccine?
                                                                
            if Vaccine_Time(i) <= 0                             % If YES:
                    Vaccine(i) = 1;                             % Set their state to vaccinateded.
                    Infect(i)  = 0;                             % They're no longer susceptible.
                    
            else                                                % If NO:
                Vaccine_Time(i) = Vaccine_Time(i) - 1;          % Decrement their remaining vaccination time for the next check.
            end
        end
               
        %% Collision Variables:
        Collision = Collision - ...                             % Resetting collision variable at the start of each iteration.
              ones(Boston_Density, Boston_Density);
        Collision(Collision < 0) = 0;
        Position_New = Position + Move_Speed .* ...             % Update the previous position.
            (~repmat(Social_Distance, 1,2 )) * dT;
        
        %% Collision Checks:
        for j = 1:1:Boston_Density
            if j ~= i                                           % To prevent collisions with themselves!            
                Position_i = Position_New(i,:);                 % Get the position of person i.
                Position_j = Position_New(j,:);                 % Get the position of person j.
                
                % If a collision has occurred:
                if norm(Position_i - Position_j) <= (2 * Infect_Radius) ... 
                    && ~Collision(i,j) && ~Collision(j,i)
                    
                    % Use collision delays to prevent immediate
                    % recollision:
                    Collision(i,j) = Collision_Delay;
                    Collision(j,i) = Collision_Delay;
                    
                    % Compute New Move Speed
                    New_Move_Speed = atan2((Position_j(2) - Position_i(2)) ...
                                     ,(Position_j(1) - Position_i(1)));
                    
                    if Social_Distance(i)||Dead(i)                              % Case 1: Person i is immobile.
                     
                        % Get normal direction vector of 'virtual wall'
                        Virtual_wall = -New_Move_Speed + pi / 2;
                        New_wall = [sin(Virtual_wall) cos(Virtual_wall)];
                        dot = Move_Speed(j,:) * New_wall';
                        
                        Move_Speed(j,1) = Move_Speed(j,1) - ...                 % Recompute the X-move speed for person j.
                                          2 * dot * New_wall(1);    
                        Move_Speed(j,2) = Move_Speed(j,2) - ...                 % Recompute the Y-move speed for person j.
                                          2 * dot * New_wall(2);
                        Move_Speed(i,1) = 0;                                    % Person i remains immobile.
                        Move_Speed(i,2) = 0;
                        
                    elseif Social_Distance(j)||Dead(j)                          % Case 2: Person j is immobile.                     
                        
                        % Get normal direction vector of 'virtual wall'
                        Virtual_wall = -New_Move_Speed + pi / 2;
                        New_wall = [sin(Virtual_wall) cos(Virtual_wall)];
                        dot = Move_Speed(i,:) * New_wall';
                        
                        Move_Speed(i,1) = Move_Speed(i,1) - ...                 % Recompute the X-move speed for person i.
                                          2 * dot * New_wall(1);    
                        Move_Speed(i,2) = Move_Speed(i,2) - ...                 % Recompute the Y-move speed for person i.
                                          2 * dot * New_wall(2);
                        Move_Speed(j,1) = 0;                                    % Person j remains immobile.
                        Move_Speed(j,2) = 0;
                        
                    else                                                            % Case 3: Both are mobile.
                                                                                
                        Move_Speed_i = sqrt(Move_Speed(i,1)^2 ...                   % Compute magnitude of person i's move speed.
                                       + Move_Speed(i,2)^2); 
                        Move_Speed_j = sqrt(Move_Speed(j,1)^2 ...                   % Compute magnitude of person j's move speed.
                                       + Move_Speed(j,2)^2);
                                   
                        Direction_i = atan2(Move_Speed(i,2) ...                     % Compute direction of person i.
                                            ,Move_Speed(i,1));     
                        Direction_j = atan2(Move_Speed(j,2) ...                     % Compute direction of person j.
                                            ,Move_Speed(j,1));
                                        
                        Move_Speed(i,1) = Move_Speed_j * ...                        % Compute X-Direction move speed for person i.
                                          cos(Direction_j - New_Move_Speed) * ...
                                          cos(New_Move_Speed) + Move_Speed_i * ...
                                          sin(Direction_i - New_Move_Speed) * ...
                                          cos(New_Move_Speed + pi / 2);
                        Move_Speed(i,2) = Move_Speed_j * ...                        % Compute Y-Direction move speed for person i.
                                          cos(Direction_j - New_Move_Speed) * ...
                                          sin(New_Move_Speed) + Move_Speed_i * ...
                                          sin(Direction_i-New_Move_Speed) * ...
                                          sin(New_Move_Speed + pi / 2);
                        Move_Speed(j,1) = Move_Speed_i * ...                        % Compute X-Direction move speed for person j.
                                        cos(Direction_i - New_Move_Speed) * ...
                                        cos(New_Move_Speed) + Move_Speed_j * ...
                                        sin(Direction_j - New_Move_Speed) * ...
                                        cos(New_Move_Speed + pi / 2);
                        Move_Speed(j,2) = Move_Speed_i * ...                        % Compute Y-Direction move speed for person j.
                                          cos(Direction_i - New_Move_Speed) * ...
                                          sin(New_Move_Speed) + Move_Speed_j * ...
                                          sin(Direction_j - New_Move_Speed) * ...
                                          sin(New_Move_Speed + pi / 2);
                    end                     

                    %% Transmission Checks
                    if Infect(i) || Infect(j)                               % Check if either person is infected.

                        if Dead(i) || Dead(j) ...
                           || Recover(i) || Recover(j) ...
                           || Vaccine(i) || Vaccine(j)                      % Case 1: Collided with dead or recovered person. Do nothing.
                            if Dead(i) || Recover(i) || Vaccine(i)
                                Infect(i) = 0;                              % Person i should not be infected.
                            else
                                Infect(j) = 0;                              % Person j should not be infected.
                            end

                        else                                                % Case 2: Collided with infected or susceptible person.
                            spread = rand(1) < Infect_Rate;                 % Roll a number to see if COVID spread.
                            if spread                                       % COVID gets spread:
                                Susceptible(i) = 0;             
                                Infect(i) = 1;                              % Update state of person i to infected.
                                Susceptible(j) = 0;             
                                Infect(j) = 1;                              % Update state of person j to infected.
                            end   
                        end
                    end
                end
            end
        end
        
        %% Map Boundary Collisions:
        % Left Wall
        if Position_New(i,1) <= Infect_Radius
            if Move_Speed(i,1) < 0
                Move_Speed(i,1) = -Move_Speed(i,1);
            end

        % Right wall
        elseif Position_New(i,1) >= Map_Bound - Infect_Radius
            if Move_Speed(i,1) > 0
                Move_Speed(i,1) = -Move_Speed(i,1);
            end
        end

        % Bottom Wall
        if Position_New(i,2) <= Infect_Radius
            if Move_Speed(i,2) < 0
                Move_Speed(i,2) = -Move_Speed(i,2);
            end

        % Top Wall
        elseif Position_New(i,2) >= Map_Bound - Infect_Radius
            if Move_Speed(i,2) > 0
                Move_Speed(i,2) = -Move_Speed(i,2);
            end
        end
    end
    
    %% Plotting Variables:
    color = [Infect Susceptible Recover] .* (1 - Vaccine - Dead);     % Update person's color based on state.
    
    Infect_Percent(a)       = sum(Infect) * ...             % Update infect percentage.
                            100 / Boston_Density;
    Susceptible_Percent(a)  = sum(Susceptible) * ...        % Update susceptible percentage.
                            100 / Boston_Density;
    Recover_Percent(a)      = sum(Recover) * ...            % Update recover percentage.
                            100 / Boston_Density;
    Vaccine_Percent(a)      = sum(Vaccine) * ...            % Update vaccine percentage.
                            100 / Boston_Density;
    Dead_Percent(a)         = sum(Dead) * ...               % Update dead percentage.
                            100 / Boston_Density;
    
    %% Plotting:
    % Initialize plots on first loop iteration
    if a==1
        % Plot transmission simulation
        figure(1);
        markerSize = 16;
        set(gcf,'DefaultFigureRendererMode','auto');
        set(gcf,'Position',[100 100 800 500]);
        subplot(2,3,[1 2 4 5]);
        h = scatter(Position_New(:,1),Position_New(:,2)...
            , markerSize, color, 'filled', 'MarkerEdgeColor', 'k'); 
        hold on;
        xlim([0,Map_Bound]);
        ylim([0,Map_Bound]);
        axis square;
        grid on;
        box on;
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        titlestring = strcat('Total: Susceptible= ',num2str(sum(Susceptible))...
                            ,' Infected= ',num2str(sum(Infect))...
                            ,' Recovered=', num2str(sum(Recover))...
                            ,' Vaccinated=', num2str(sum(Vaccine))...
                            ,' Deceased=', num2str(sum(Dead)));
        title(titlestring);
        
        % Resize markers to match infection radius
        currentunits = get(gca,'Units');
        set(gca, 'Units', 'Points');
        axpos = get(gca,'Position');
        set(gca, 'Units', currentunits);
        markerWidth = 2 * Infect_Radius / diff(xlim) * axpos(3); % Calculate Marker width in points
        lineWidth = 0.5 * markerWidth;
        set(h, 'SizeData', markerWidth^2);
        markerSize = markerWidth^2;
        
        % Plot infection rates vs. time
        subplot(2,3,[3 6]);
        hold on;
        Susceptible_Line    = plot(Time(1:a),Susceptible_Percent(1:a)...
                              ,'g','LineWidth',2);
        Infect_Line         = plot(Time(1:a),Infect_Percent(1:a)...
                              ,'r','LineWidth',2);
        Recover_Line        = plot(Time(1:a),Recover_Percent(1:a)...
                              ,'b','LineWidth',2);
        Vaccine_Line        = plot(Time(1:a),Vaccine_Percent(1:a)...
                              ,'c','LineWidth',2);
        Dead_Line           = plot(Time(1:a),Dead_Percent(1:a)...
                              ,'k','LineWidth',2);
        hold off;
        legend('Susceptible','Infected','Recovered','Vaccinated','Deceased');
        xlabel('Days');
        ylabel('Population %');
        xlim([0,Simul_Time]);
        ylim([0,100]);
        set(gcf,'Color','w');
        
        % Update data on subesequent iterations
    else
        subplot(2,3,[1 2 4 5]);
        set(h,'XData',Position_New(:,1));
        set(h,'YData',Position_New(:,2));
        set(h,'CData',color);
        
        % Update title
        titlestring = strcat('Total: Susceptible= ',num2str(sum(Susceptible))...
                            ,' Infected= ',num2str(sum(Infect))...
                            ,' Recovered= ', num2str(sum(Recover))...
                            ,' Vaccinated= ', num2str(sum(Recover))...
                            ,' Deceased= ', num2str(sum(Dead)));
        title(titlestring);
        
        subplot(2,3,[3 6]);
        set(Susceptible_Line,'XData',Time(1:a)); ...
            set(Susceptible_Line,'YData',Susceptible_Percent(1:a));
        set(Infect_Line,'XData',Time(1:a)); ...
            set(Infect_Line,'YData',Infect_Percent(1:a));
        set(Recover_Line,'XData',Time(1:a)); ...
            set(Recover_Line,'YData',Recover_Percent(1:a));
        set(Vaccine_Line,'XData',Time(1:a)); ...
            set(Vaccine_Line,'YData',Vaccine_Percent(1:a));
        set(Dead_Line,'XData',Time(1:a)); ...
            set(Dead_Line,'YData',Dead_Percent(1:a));
        
    end
    drawnow;
    % Saving the video snapshots
    if Video_capture
        frame = getframe(gcf);
        writeVideo(video,frame);
    end
    
    Position = Position_New;      % Update position
end

if Video_capture
    close(video);
end
