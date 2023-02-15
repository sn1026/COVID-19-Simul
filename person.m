classdef person < handle
    properties
        state = "Susceptible";
        recoveryTime;                 % The actual time a person will take to recover from COVID.
        willVaccinate = true;         % Flag which determines whether a person will become vaccinated
        vaccineTime;                  % Wait time to receive a vaccine
        willSocialDistance = false;   % Flag which determines whether a person will opt to social distance
        willDie = false;              % Flag which determines whether a person will die from COVID.

        speed = 20;                   % How fast (in ft/dT) each person is initially moving.
        position;
        moveSpeed;
        direction;
    end
    %Constructor
    methods
        function obj = person(s,rt,sd,wv,vt,wd,pos)
            obj.state = s;
            obj.recoveryTime = rt;
            obj.willSocialDistance = sd;
            obj.willVaccinate = wv;
            obj.vaccineTime = vt;
            obj.willDie = wd;
            obj.position = pos;
            obj.direction = rand() * 2*pi;
            obj.moveSpeed = [obj.speed * cos(obj.direction), ...
                             obj.speed * sin(obj.direction)];
        end
    end
    methods (Access = public)
        function [s] = getState(person)
            s = person.state;
        end

        function [person] = updateState(person, state)
            validStates = ["Susceptible","Infect","Dead","Vaccine","Recover"];
            if any(matches(validStates,state))
                person.setState(state);
                if strcmp(state,"Dead")
                    %Person is immobile if dead.
                    person.moveSpeed = [0 0];
                end
            else
                fprintf('Invalid state. Cannot update state property.')
            end
        end

        function [rt] = getRecoveryTime(person)
            rt = person.recoveryTime;
        end

        function [person] = updateRecoveryTime(person)
            newTime = person.recoveryTime - 1;
            person.setRecoveryTime(newTime);
        end
        function [vt] = getVaccineTime(person)
            vt = person.vaccineTime;
        end

        function [person] = updateVaccineTime(person)
            newTime = person.vaccineTime - 1;
            person.setVaccineTime(newTime);
        end
    end

    methods (Access = private)
        function [person] = setState(person, state)
            person.state = state;
        end

        function [p] = setRecoveryTime(p, rt)
            p.recoveryTime = rt;
        end

        function [p] = setVaccineTime(p, vt)
            p.vaccineTime = vt;
        end
    end
end