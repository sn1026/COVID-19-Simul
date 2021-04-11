%%Clean the interface
clear;
clc;

%% Global Variables

%Time Specific
Simul_Time = 30;                                % Total duration (in days) of the simulation.
dT         = 0.02083;                           % How fast time will accelerate for the simulation. Currently set to 30min.
Curr_Time  = 0;                                 % Keep track of how much time has progressed in the simulation.

%Map Specific
Map_Bound      = 5280;                          % Size of the Map.  In our case, its 5280 feet because we're doing 1 mi^2
Boston_Density = 13936;                         % Population Density of Boston/sq. mi
SD_Prop        = 0.5;                           % Percentage of the Population opting for social distancing

%COVID Specific
Initial_Infect     = 0.05;                       % Percentage of population infected with COVID at the start of simulation
Infect_Rate        = 0.75;                       % Likelihood of infection upon contact.
Infect_radius      = 6;                          % Infection radius =  6 feet
Mortality_Rate     = 0.018;                      % Likelihood of death if infected.
Avg_Recovery_Time  = 15;                         % Average time (in days) to recover from COVID.
Recovery_Time      = ceil(Avg_Recovery_Time ...  % The actual time a person will take to recover from COVID.
                    + 5*randn(Boston_Density,1));                         


%Population Specific
Infect      = rand(Boston_Density,1) < Initial_Infect;  % Initially random people with COVID.
Susceptible = ~Infect;                                  % Everyone else that has not contracted COVID is susceptible.   
Recover     = zeros(Boston_Density,1);                  % Create a vector to keep track of recovered
Dead        = zeros(Boston_Density,1);                  % Create a vector to keep track of deceased.
Dead_Chance = rand(Boston_Density,1) < Mortality_Rate;  % Infected random people with COVID have a chance of dying.

%Initial Movement Setup
Speed           = 20;                                   % How fast (in ft/dT) each person is initially moving.  Currently set to 20 feet / 30min.
Social_Distance = rand(Boston_Density,1) < SD_Prop;     % Identifies which people will be socially distancing.
Position        = rand(Boston_Density,2) * (Map_Bound); % Where each 'person' will spawn in on the map.
Direction       = rand(Boston_Density,1) * 2 * pi;      % Direction each 'person' will be moving.
Move_Speed      = [Speed.*cos(Direction), ...           % How fast each 'person' is moving, given a direction.
                   Speed.*sin(Direction)];              
                   
Collision       = zeros(Boston_Density, Boston_Density); % Create an array to keep track of people bumping into each other.
n_delay         = ceil(1/(dT));                          % Collision delay

%% Computation
while Curr_Time <= Simul_Time
    %% Infected Individual Checks
    for i = 1:1:Boston_Density
        if Infect(i)                            % Checking if the infected individual recovered or died.

            if Recovery_Time <= 0
                if Dead_Chance(i)               % Case 1: They're dead.
                    Dead(i)   = 1;              % Set their state to dead.
                    Infect(i) = 0;              % They're no longer infected.
                    Move_Speed(i,:) = [0 0];    % The dead are no longer mobile.

                else                            % Case 2: They're recovered.
                    Recover(i) = 1;             % Set their state to recovered.
                    Infect(i)  = 0;             % They're no longer infected.
                end
            end

            Recovery_Time(i) = Recovery_Time(i) - 1;      % Decrement their remaining recovery time for the next check.
        end
        
        %% Collision Variables : Decrement collision delay
        Collision = Collision-ones(Boston_Density, Boston_Density);
        Collision(Collision<0)=0;


        % Update carrier position
        Position_New = Position + Move_Speed .* (~repmat(Social_Distance,1,2)) * dT;
        
        for j = 1:1:Boston_Density

            % Checking to see which people collided
              % Stepping through all other carriers, looking for collisions, and 
              % if so, transmit disease and recalculate trajectory
            if j ~= i                       

                % Get positions of carriers
                Position_1 = Position_New(i,:);
                Position_2 = Position_New(j,:);
                
                
                % If collision between two living specimens, re-calcuate
                % direction and transmit virus (but don't check the same
                % two carriers twice)
                if norm(Position_1-Position_2)<=(2*Infect_radius) && ~Collision(i,j) && ~Collision(j,i)
                    
                    % Create the collision delay (i.e. if carrier i and j have recently collided, 
                    % don't recompute collisions for a n_delay time steps in case they're still close in proximity,
                    % otherwise they might just keep orbiting eachother)
                    Collision(i,j) = n_delay;
                    Collision(j,i) = n_delay;
                    
                    % Compute New Move Speed
                    New_Move_Speed = atan2((Position_2(2)-Position_1(2)),(Position_2(1)-Position_1(1)));
                    
                    % if one carrier is isolated, treat it like a wall and
                    % bounce the other carrier off it
                    if Social_Distance(j)||Dead(j)
                     
                        % Get normal direction vector of 'virtual wall'
                        Virtual_wall = -New_Move_Speed+pi/2;
                        New_wall = [sin(Virtual_wall) cos(Virtual_wall)];
                        dot = Move_Speed(i,:)*New_wall';
                        
                        % Redirect non-isolated carrier
                        Move_Speed(i,1) = Move_Speed(i,1)-2*dot*New_wall(1);
                        Move_Speed(i,2) = Move_Speed(i,2)-2*dot*New_wall(2);
                        Move_Speed(j,1) = 0;
                        Move_Speed(j,2) = 0;
                        
                    elseif Social_Distance(i)||Dead(i)
                        
                        % Get normal direction vector of 'virtual wall'
                        Virtual_wall = -New_Move_Speed+pi/2;
                        New_wall = [sin(Virtual_wall) cos(Virtual_wall)];
                        dot = Move_Speed(j,:)*New_wall';
                        
                        % Redirect non-isolated carrier
                        Move_Speed(j,1) = Move_Speed(j,1)-2*dot*New_wall(1);
                        Move_Speed(j,2) = Move_Speed(j,2)-2*dot*New_wall(2);
                        Move_Speed(i,1) = 0;
                        Move_Speed(i,2) = 0;
                        
                        % Otherwise, transfer momentum between carriers
                    else 
                        % Get velocity magnitudes
                        Velocity_mag_1 = sqrt(Move_Speed(i,1)^2+Move_Speed(i,2)^2);
                        Velocity_mag_2 = sqrt(Move_Speed(j,1)^2+Move_Speed(j,2)^2);
                        
                        % Get directions
                        th1 = atan2(Move_Speed(i,2),Move_Speed(i,1));
                        th2 = atan2(Move_Speed(j,2),Move_Speed(j,1));
                        
                        % Compute new velocities
                        Move_Speed(i,1) = Velocity_mag_2*cos(th2-New_Move_Speed)*cos(New_Move_Speed)+Velocity_mag_1*sin(th1-New_Move_Speed)*cos(New_Move_Speed+pi/2);
                        Move_Speed(i,2) = Velocity_mag_2*cos(th2-New_Move_Speed)*sin(New_Move_Speed)+Velocity_mag_1*sin(th1-New_Move_Speed)*sin(New_Move_Speed+pi/2);
                        Move_Speed(j,1) = Velocity_mag_1*cos(th1-New_Move_Speed)*cos(New_Move_Speed)+Velocity_mag_2*sin(th2-New_Move_Speed)*cos(New_Move_Speed+pi/2);
                        Move_Speed(j,2) = Velocity_mag_1*cos(th1-New_Move_Speed)*sin(New_Move_Speed)+Velocity_mag_2*sin(th2-New_Move_Speed)*sin(New_Move_Speed+pi/2);
                        
                    end                     

                    %% Transmission Checks
                    if Infect(i) || Infect(j)                               % Check if either person is infected.

                        if Dead(i) || Dead(j) || Recover(i) || Recover(j)   % Case 1: Collided with dead or recovered person. Do nothing.
                            if Dead(i) || Recover(i)
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
     end
    
    Curr_Time = Curr_Time + dT;     %%The simulation progresses forward.
end

%% Plotting