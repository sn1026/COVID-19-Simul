function [] = COVIDSimulation()
    %Main Function
    %% Clean the interface 
    close force all;
    clear;
    clc;
    
    %% Global Variables
    %Time Specific
    simulTime          = 90;                                       % Total duration (in days) of the simulation.
    dT                 = minToDay(90);                             % How fast time will accelerate for the simulation. Currently set to 90min.
    timeInterval       = ceil(simulTime/dT);                       % # of times the code will iterate during computation
    time               = linspace(0,simulTime,timeInterval);       % Create a vector to keep track of time.
    
    %Map Specific
    mapBound           = 600;                                      % Size of the Map
    popDensity         = 200;                                      % Number of nodes (can be treated as population or population density)
    socialDistanceRate = 0.4;                                       % Percentage of population opting for social distancing
    
    %COVID Specific
    initInfect         = 0.03;                                     % Percentage of population infected with COVID at the start of simulation
    infectRate         = 0.6;                                      % Likelihood of infection upon contact.
    infectRadius       = 6;                                        % Infection radius = 6 feet
    mortalityRate      = 0.026;                                    % Likelihood of death if infected.
    avgRecoveryTime    = 15;                                       % Average time (in days) to recover from COVID.
                      
    % Vaccine Specific
    initVaccine        = 0;                                        % Percentage of population vaccinated at the start of simulation
    vaccineRate        = 0.7;                                      % Percentage of population who want to be vaccinated.
    avgVaccineTime     = 40;                                       % Average time (in days) to receive a vaccine
    
    %Initial Movement Setup
    socialDistance     = zeros(popDensity,1);                      % Identifies which people will be socially distancing.
    position           = zeros(popDensity,2);                      % Where each 'person' will spawn in on the map.
    direction          = zeros(popDensity,1);                      % Direction each 'person' will be moving.
    moveSpeed          = zeros(popDensity,2);                      % How fast each 'person' is moving, given a direction.                                
    collision          = zeros(popDensity, popDensity);            % Create an array to keep track of people bumping into each other.
    resetCollision     = ones(popDensity, popDensity);             % Pre-allocating a matrix to reset collision tracking.
    collisionDelay     = ceil(1/dT);                               % Collision delay

    %Plotting/Video Specific
    infectPercent      = zeros(timeInterval,1);                    % Create a vector to keep track of infected population percentage.
    susceptiblePercent = zeros(timeInterval,1);                    % Create a vector to keep track of susceptible population percentage.
    vaccinePercent     = zeros(timeInterval,1);                    % Create a vector to keep track of infected population percentage.
    recoverPercent     = zeros(timeInterval,1);                    % Create a vector to keep track of recovered population percentage.
    deadPercent        = zeros(timeInterval,1);                    % Create a vector to keep track of dead population percentage.
    videoCapture       = false;                                    % Save video?
    ffn_Video          = 'Simulation.avi';                         % Video filename
    
    %Initialize people
    population = cell(1,popDensity);
    color = zeros(200,3);
    successfulSpawn = 0;
    while successfulSpawn < popDensity
        population{successfulSpawn + 1} = initializePerson(initInfect, avgRecoveryTime, ...
                                        mortalityRate, initVaccine, vaccineRate, ...
                                        avgVaccineTime,dT, mapBound, socialDistanceRate);

        goodSpawn = true;
        for j = 1:popDensity
            if position(j,1) == 0 && position(j,2) == 0
                continue;
            end
            if norm(population{successfulSpawn + 1}.position - position(j,:)) <= (2 * infectRadius)
                %Respawn the person if they spawned on top of someone else
                goodSpawn = false;
                break;
            end
        end

        if goodSpawn
            %Aggregate movement variables into vectors for plotting.
            socialDistance(successfulSpawn + 1,:) = population{successfulSpawn + 1}.willSocialDistance;
            position(successfulSpawn + 1,:) = population{successfulSpawn + 1}.position;
            direction(successfulSpawn + 1) = population{successfulSpawn + 1}.direction;
            moveSpeed(successfulSpawn + 1,:) = population{successfulSpawn + 1}.moveSpeed;
            successfulSpawn = successfulSpawn + 1;
        end
    end
    
    % Initialize Video Writer
    if videoCapture
        video = VideoWriter(ffn_Video,'Uncompressed AVI');
        open(video);
    end
    
    %% Computation
    for a = 1:timeInterval
        %Reset state counters for plotting
        infectCount = 0;
        susceptibleCount = 0;
        recoverCount = 0;
        vaccineCount = 0;
        deadCount = 0;

        %% Infected Individual Checks
        for i = 1:popDensity
            if strcmp(population{i}.state,"Infect")                   
                % Checking if the infected individual recovered or died. Has COVID recovery time elapsed?                                                    
                if population{i}.getRecoveryTime() <= 0         
                                                                  
                    if population{i}.willDie                        % If YES:
                        newState = "Dead";                         % Case 1: They're dead.
                        moveSpeed(i,:) = [0 0];
                    else                                           % Case 2: They're recovered.
                        newState = "Recover";
                    end
                    population{i}.updateState(newState);
                    
                else                                               % If NO:
                    population{i}.updateRecoveryTime();             % Decrement their remaining recovery time for the next check.
                end
            end
            
            if strcmp(population{i}.state,"Susceptible")            % Checking if the susceptible individual received a vaccine.
                                                                   % Is it their time to get a vaccine?
                                                                    
                if population{i}.getVaccineTime() <= 0 && ...       % If YES:
                        population{i}.willVaccinate
                    population{i}.updateState("Vaccine");           % They're vaccinated.
                    population{i}.state = "Vaccine";

                else                                               % If NO:
                    population{i}.updateVaccineTime();              % Decrement their remaining vaccination time for the next check.
                end
            end
                   
            %% Collision Variables:           
            collision = max(collision - resetCollision,0);         % Resetting collision variable at the start of each iteration.

            Position_New = position + moveSpeed .* ...             % Update the previous position.
                (~repmat(socialDistance, 1, 2)) * dT;
            
            %% Collision Checks:
            for j = i:popDensity
                if j ~= i                                          % To prevent collisions with themselves!
                    Position_i = Position_New(i,:);                % Get the position of person i.
                    Position_j = Position_New(j,:);                % Get the position of person j.
                    
                    % If a collision has occurred:
                    if norm(Position_i - Position_j) <= (2 * infectRadius) ... 
                        && ~collision(i,j) && ~collision(j,i)
                        
                        % Use collision delays to prevent immediate recollision:
                        collision(i,j) = collisionDelay;
                        collision(j,i) = collisionDelay;
                        
                        % Compute New Move Speed
                        newMoveSpeed = atan2((Position_j(2) - Position_i(2)) ...
                                             ,(Position_j(1) - Position_i(1)));
                            
                        if population{i}.willSocialDistance || strcmp(population{i}.state,"Dead")         % Case 1: Person i is immobile.
                         
                            % Get normal direction vector of 'virtual wall'
                            virtualWall = -newMoveSpeed + pi / 2;
                            newWall = [sin(virtualWall) cos(virtualWall)];
                            dot = moveSpeed(j,:) * newWall';
                            
                            moveSpeed(j,1) = moveSpeed(j,1) - ...                                       % Recompute the X-move speed for person j.
                                              2 * dot * newWall(1);    
                            moveSpeed(j,2) = moveSpeed(j,2) - ...                                       % Recompute the Y-move speed for person j.
                                              2 * dot * newWall(2);
                            moveSpeed(i,:) = [0 0];                                                     % Person j remains immobile.

                        elseif population{j}.willSocialDistance || strcmp(population{j}.state,"Dead")     % Case 2: Person j is immobile.                     
                            
                            % Get normal direction vector of 'virtual wall'
                            virtualWall = -newMoveSpeed + pi / 2;
                            newWall = [sin(virtualWall) cos(virtualWall)];
                            dot = moveSpeed(i,:) * newWall';
                            
                            moveSpeed(i,1) = moveSpeed(i,1) - ...                                       % Recompute the X-move speed for person i.
                                              2 * dot * newWall(1);    
                            moveSpeed(i,2) = moveSpeed(i,2) - ...                                       % Recompute the Y-move speed for person i.
                                              2 * dot * newWall(2);
                            moveSpeed(j,1) = 0;                                                         % Person j remains immobile.
                            moveSpeed(j,2) = 0;                                                         % Person j remains immobile.
                            
                        else                                                                            % Case 3: Both are mobile.
                                                                                    
                            moveSpeed_i = sqrt(moveSpeed(i,1)^2 ...                                     % Compute magnitude of person i's move speed.
                                           + moveSpeed(i,2)^2); 
                            moveSpeed_j = sqrt(moveSpeed(j,1)^2 ...                                     % Compute magnitude of person j's move speed.
                                           + moveSpeed(j,2)^2);
                                       
                            direction(i) = atan2(moveSpeed(i,2) ...                                     % Compute direction of person i.
                                                ,moveSpeed(i,1));     
                            direction(j) = atan2(moveSpeed(j,2) ...                                     % Compute direction of person j.
                                                ,moveSpeed(j,1));
                                            
                            moveSpeed(i,1) = moveSpeed_j * ...                                          % Compute X-Direction move speed for person i.
                                              cos(direction(j) - newMoveSpeed) * ...
                                              cos(newMoveSpeed) + moveSpeed_i * ...
                                              sin(direction(i) - newMoveSpeed) * ...
                                              cos(newMoveSpeed + pi / 2);
                            moveSpeed(i,2) = moveSpeed_j * ...                        % Compute Y-Direction move speed for person i.
                                              cos(direction(j) - newMoveSpeed) * ...
                                              sin(newMoveSpeed) + moveSpeed_i * ...
                                              sin(direction(i) - newMoveSpeed) * ...
                                              sin(newMoveSpeed + pi / 2);
                            moveSpeed(j,1) = moveSpeed_i * ...                        % Compute X-Direction move speed for person j.
                                            cos(direction(i) - newMoveSpeed) * ...
                                            cos(newMoveSpeed) + moveSpeed_j * ...
                                            sin(direction(j) - newMoveSpeed) * ...
                                            cos(newMoveSpeed + pi / 2);
                            moveSpeed(j,2) = moveSpeed_i * ...                        % Compute Y-Direction move speed for person j.
                                              cos(direction(i) - newMoveSpeed) * ...
                                              sin(newMoveSpeed) + moveSpeed_j * ...
                                              sin(direction(j) - newMoveSpeed) * ...
                                              sin(newMoveSpeed + pi / 2);
                        end                     
    
                        %% Transmission Checks
                        if strcmp(population{i}.state,"Infect") || strcmp(population{j}.state,"Infect")      % Check if either person is infected.
    
                            if any(matches(population{i}.state,["Dead","Recover","Vaccine"])) || ... % Case 1: Collided with dead, vaccinated, or recovered person.
                               any(matches(population{j}.state,["Dead","Recover","Vaccine"]))              
                                                                                                    % Do nothing.   

                            else                                                                    % Case 2: Collided with infected or susceptible person.
                                spread = rand() < infectRate;                                       % Roll a number to see if COVID spread.
                                if spread                                                           % COVID gets spread:
                                    population{i}.updateState("Infect");                             % Update state of person i to infected.
                                    population{j}.updateState("Infect");                             % Update state of person j to infected.                
                                end   
                            end
                        end
                    end
                end
            end
            
            %% Map Boundary Collisions:
            % Left Wall
            if Position_New(i,1) <= infectRadius
                if moveSpeed(i,1) < 0
                    moveSpeed(i,1) = -moveSpeed(i,1);
                end
    
            % Right wall
            elseif Position_New(i,1) >= mapBound - infectRadius
                if moveSpeed(i,1) > 0
                    moveSpeed(i,1) = -moveSpeed(i,1);
                end
            end
    
            % Bottom Wall
            if Position_New(i,2) <= infectRadius
                if moveSpeed(i,2) < 0
                    moveSpeed(i,2) = -moveSpeed(i,2);
                end
    
            % Top Wall
            elseif Position_New(i,2) >= mapBound - infectRadius
                if moveSpeed(i,2) > 0
                    moveSpeed(i,2) = -moveSpeed(i,2);
                end
            end

            %Update vectors for plotting
            switch population{i}.state
                case "Infect"
                    color(i,:) = [1 0 0];
                    infectCount = infectCount+1;
                case "Susceptible"
                    color(i,:) = [0 1 0];
                    susceptibleCount = susceptibleCount+1;
                case "Recover"
                    color(i,:) = [0 0 1];
                    recoverCount = recoverCount+1;
                case "Vaccine"
                    color(i,:) = [0 1 1];
                    vaccineCount = vaccineCount+1;
                case "Dead"
                    color(i,:) = [0 0 0];
                    deadCount = deadCount+1;
            end
        end
        
        %% Plotting Variables:  
        infectPercent(a)       = infectCount * ...             % Update infect percentage.
                                100 / popDensity;
        susceptiblePercent(a)  = susceptibleCount * ...        % Update susceptible percentage.
                                100 / popDensity;
        recoverPercent(a)      = recoverCount * ...            % Update recover percentage.
                                100 / popDensity;
        vaccinePercent(a)      = vaccineCount * ...            % Update vaccine percentage.
                                100 / popDensity;
        deadPercent(a)         = deadCount * ...               % Update dead percentage.
                                100 / popDensity;
        
        %% Plotting:
        % Initialize plots on first loop iteration
        if a==1
            % Plot transmission simulation
            figure('Position',[100 100 1200 800],...
                        'defaultLegendAutoUpdate','off',...
                        'DefaultFigureRendererMode','auto');
            markerSize = 16;
            
            nodePlot = subplot(2,3,[1 2 4 5]);
            h = scatter(position(:,1),position(:,2)...
                , markerSize, color, 'filled', 'MarkerEdgeColor', 'k'); 
            hold on;
            axis square;
            grid on;
            box on;
            xlim(nodePlot,[0 mapBound]);
            ylim(nodePlot,[0 mapBound]);
            nodePlot.YTickLabel = [];
            nodePlot.XTickLabel = [];
            titlestring = strcat('Susceptible= ',num2str(susceptibleCount)...
                                ,' Infected= ',num2str(infectCount)...
                                ,' Recovered=', num2str(recoverCount)...
                                ,' Vaccinated=', num2str(vaccineCount)...
                                ,' Deceased=', num2str(deadCount));
            nodePlot.Title.String = titlestring;
            
            
            % Resize markers to match infection radius
            nodePlot.Units = 'Points';
            markerWidth = 2 * infectRadius / mapBound * nodePlot.Position(3); % Calculate Marker width in points
            set(h, 'SizeData', markerWidth^2);
            
            % Plot infection rates vs. time
            statPlot = subplot(2,3,[3 6],...
                        'XLim', [0, simulTime], 'YLim', [0,100], 'Color', 'w');
            statPlot.XLabel.String = 'Days';
            statPlot.YLabel.String = 'Population %';
            hold on;
            Susceptible_Line    = plot(time(1:a),susceptiblePercent(1:a)...
                                  ,'g','LineWidth',2);
            Infect_Line         = plot(time(1:a),infectPercent(1:a)...
                                  ,'r','LineWidth',2);
            Recover_Line        = plot(time(1:a),recoverPercent(1:a)...
                                  ,'b','LineWidth',2);
            Vaccine_Line        = plot(time(1:a),vaccinePercent(1:a)...
                                  ,'c','LineWidth',2);
            Dead_Line           = plot(time(1:a),deadPercent(1:a)...
                                  ,'k','LineWidth',2);
            legend(statPlot,'Susceptible','Infected','Recovered','Vaccinated','Deceased');
            hold off;
            
            
        else
            % Update data on subesequent iterations
            set(h,'XData',Position_New(:,1));
            set(h,'YData',Position_New(:,2));
            set(h,'CData',color);
            
            % Update title
            titlestring = strcat('Susceptible= ',num2str(susceptibleCount)...
                                ,' Infected= ',num2str(infectCount)...
                                ,' Recovered= ', num2str(recoverCount)...
                                ,' Vaccinated= ', num2str(vaccineCount)...
                                ,' Deceased= ', num2str(deadCount));
            title(nodePlot, titlestring);
            nodePlot.XLabel.String = sprintf('%.2f days have elapsed.',a.*dT);
            
            Susceptible_Line.XData(end+1) = time(a);
            Susceptible_Line.YData(end+1) = susceptiblePercent(a);
            Infect_Line.XData(end+1) = time(a);
            Infect_Line.YData(end+1) = infectPercent(a);
            Recover_Line.XData(end+1) = time(a);
            Recover_Line.YData(end+1) = recoverPercent(a);
            Vaccine_Line.XData(end+1) = time(a);
            Vaccine_Line.YData(end+1) = vaccinePercent(a);
            Dead_Line.XData(end+1) = time(a);
            Dead_Line.YData(end+1) = deadPercent(a);            
        end

        drawnow limitrate;
        % Saving the video snapshots
        if videoCapture
            frame = getframe(gcf);
            writeVideo(video,frame);
        end
        
        for i = 1:popDensity
            population{i}.position = Position_New(i,:);      % Update position
            population{i}.moveSpeed = moveSpeed(i,:);        % Update movespeed
            population{i}.direction = direction(i,:);
        end

        position = Position_New;

        if infectCount == 0
            break;
        end
    end
    
    if videoCapture
        close(video);
    end
end

function [p] = initializePerson(initInfect, avgRecoveryTime, mortalityRate, initVaccine, vaccineRate, avgVaccineTime, dT, mapBound, socialDistanceRate)
    recoveryTime = ceil(avgRecoveryTime + 5*randn())/dT;
    vaccineTime = ceil(avgVaccineTime + 10*randn())/dT;
    initPosition  = mapBound * [rand() rand()];

    if rand() < initInfect
        state = "Infect";
    else
        if rand() < initVaccine
            state = "Vaccine";
        else
            state = "Susceptible";
        end
    end

    if rand() < socialDistanceRate
        willSocialDistance = true;
    else
        willSocialDistance = false;
    end

    if rand() < vaccineRate
        willVaccinate = true;
    else
        willVaccinate = false;
    end

    if rand() < mortalityRate
        willDie = true;
    else
        willDie = false;
    end

    p = person(state,recoveryTime,willSocialDistance,willVaccinate,vaccineTime,willDie,initPosition);
end

function [day] = minToDay(min)
    % Converts minutes to days. There are 1440 minutes in a day.
    day = min / 1440; 
end