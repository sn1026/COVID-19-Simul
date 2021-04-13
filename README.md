# COVID-19-Simul
*work in progress* Simulates the impact of COVID-19 vaccination on the population of Boston.  Analyzes COVID-19 mobility and infection rates, as well as considers herd immunity.

# Introduction

The impact of COVID-19 has directly and indirectly affected the lives of billions of people worldwide. As the most widespread pandemic in recent history it is essential to understand the implications of a pandemic as well as the spread. Measures to control the spread of the virus have lagged behind the progression of the contagion. Failure to understand the pandemic has resulted in the loss of thousands of lives in the United States and millions worldwide. 
The quick development of a vaccine has been the hope for many. But despite having one, not every person is able to obtain the vaccination. The problem we aim to solve is to predict the end of the pandemic. Based on current and projected rates of infection and dosage distribution our simulation aims to predict when herd immunity is reached within the united states.

# Simulation
The MATLAB code takes great inspiration from The Washington Post’s article[1] in regards to viably modelling the spread of COVID-19 over a set period of time.  Specifically, it focuses on modelling people as nodes, so of which may be mobile, and focusing on transmissibility due to collisions between the nodes.

# Variable Initialization:
Time Specific — The MATLAB code takes into consideration the total duration of the simulation as well as how often the information within our Monte-Carlo simulation will be updated.
Map Specific — The code considers the population density of Boston and attempts to downscale the model in order to reduce overhead.  It also takes into account the percentage of the population who actively participate in social distancing.
COVID-19 Specific — The initial infection status of the population at a given time as well as the transmissibility, mortality, and average recovery time rates of COVID-19 has been taken into consideration.  In specific, COVID-19 takes roughly 10 - 20 days to recover from, so we assumed an average recovery time of 15 ± 5 days.
Population Specific — The MATLAB code initializes the vectors to keep track of the status of individuals as the simulation progresses.  The four possible states are as follows - susceptible, infected, recovered, and deceased.  We plan on implementing a vaccinated state in the near future.
Movement — The code takes into account the population mobility, with the assumption that individuals who are socially distant remain immobile. Their current position, direction, and speed are considered. A collision vector is also initialized to determine which individuals come into contact with each other.

# Infected Individual Checks:
We consider the status of an infected individual as the simulation progresses. There are three cases that can occur:
Case 1 — The infected individual dies.  Update their state and prevent their mobility.
Case 2 — The infected individual recovers from COVID-19.  Update their state.  Unlike case 1, their mobility is unaffected.
Case 3 — No state update.  We decrement how much longer it will take for the individual to recover.

# Collision Checks:
As the simulation progresses, we identify which individuals have collided and considered the following:
Mobility — With the exception of immobile (either deceased or socially distant) individuals, as individuals collide, they follow the laws of momentum.  Their direction, position, and movement speed are recalculated upon collision to determine their future movements.
Boundaries — Individuals may not leave the bounds of the simulation map.  If an individual encounters a map boundary, treat the interaction as if it was a collision and ‘bounce’ the object in an appropriate direction.

# Transmission Checks:
If two individuals collide with each other we consider whether either person is infected.  There are four possible cases:
Case 1: Neither individual is infected.  There is no need to consider COVID-19 transmission.
Case 2: There is one infected individual and one recovered or dead individual.  No COVID-19 transmission occurs.
Case 3: There is one infected individual and one susceptible individual.  We perform a probability check based on the infectivity of COVID-19.  This will determine whether the individuals will be infected.  Their states are updated accordingly.
Case 4: Both individuals are infected.  There is no need to update the status of either.  [This case is combined with case 3 code-wise for better code clarity.]

# Plotting:
The MATLAB code initializes the vectors to update the colors of each individual depending on their state.  Furthermore, we compute each state’s population percentage to give a better visualization of our simulation data.

# Results [Work in Progress]

