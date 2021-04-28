# Abstract
COVID-19 has cemented itself globally as the worst pandemic to occur in recent history. It has impacted the lives of billions of people worldwide. It is essential to understand the implications of a pandemic as well as the spread. Measures to control the spread of the virus have lagged behind contagion progression. Failure to understand the pandemic has resulted in the loss of thousands of lives in the United States and millions worldwide. As such, it is absolutely crucial for data to be quickly compiled and analyzed for better transparency and information in regards to the virus.  The problem we aim to solve is to predict the end of the pandemic. Based on current and projected rates of infection and dosage distribution our simulation aims to predict when herd immunity is reached within the United States. The project consists of two components: a Python web scraping script and a MATLAB simulation script. We have developed a MATLAB simulation tool to help predict future trends, specifically herd immunity and COVID-19 remaining duration, based on various parameters such as social distancing, transmissibility, and vaccination rates.  These simulation parameters are either taken directly or inferred from data on the CDC website via a Python web scraper.  When executed, the program will spawn mobile nodes which will interact with each other.  Based on their interactions, we are able to predict determinants such as vaccination herd immunity dates and COVID-19 duration to better understand the impact of vaccination rates and social distancing on a given population.

# Introduction
COVID-19 has likely established itself as the worst infectious disease pandemic of a generation. As of April 17 the total number of cases exceeds 30 million. The widespread infection leads to a risk of overwhelming healthcare services. Decreased access to medical care could prove fatal to those at high risk increasing the number of deaths. Economic consequences from world-wide lockdowns have devastated many and the trillions borrowed to stimulate the economy set the dollar itself at risk for inflation. Children born today are likely to be paying off this debt with tax dollars for a pandemic many years into their future. Additionally, the stress and social isolation many experienced during the pandemic is not to be underestimated. Riots and protests erupted across the country amidst elections and the frequency of mass shootings increased by a significant amount.
Early on, as the threat became clear, governments relied on computer simulations to determine how best to reduce its impact. It is essential to understand the development of a global pandemic and due to global efforts humanity seems to be on the path to recovery. Measures to control the spread of the virus's early stages have lagged behind the progression of the disease. Epidemiological modelling of the spread of COVID-19 has been an essential tool in improving the decision making of government officials. The modeling environment provides the ability to test different solutions without experimenting on the real population. Developing these models can lead to better understanding of the nature of the disease's progression. This leads to more efficient implementation of solutions with better results in high pressure situations that are highly time sensitive.

# Simulation
The MATLAB code takes great inspiration from The Washington Post’s article[2] in regards to viably modeling the spread of COVID-19 over a set period of time. Specifically, it focuses on modeling people as nodes and focusing on transmissibility due to collisions between the nodes.  A series of vectors are used to continually update the current status of each node.  Specifically: 
Current Status  
Time until status change (if susceptible / infected)
Current Position and Movement
In effect, as time progresses, we can keep track of how nodes act and whether a discrete event, such as a collision occurs. In the case of a collision, we consider how each node changes after the interaction based on each node’s previous status and movement.  Moreover, after each computational iteration is done i.e. all the checks as shown in the activity flow diagram is performed, the simulation plotting starts and it continues till the end of the computation. Video is also being created by saving and processing each snapshot of the simulation process.


# Variable Initialization
Time Specific — The code takes into consideration the total duration of the simulation as well as how often the information within our stochastic discrete event simulation will be updated.
Map Specific — The code takes into consideration the population density of a given area and attempts to downscale the model in order to reduce overhead.  It also takes into account the percentage of the population who are active in social distancing.
COVID-19 Specific — The code takes into consideration the initial infection status of the population at a given time as well as the transmissibility, mortality, and average recovery time rates of COVID-19.  In specific, COVID-19 takes roughly 10 - 20 days to recover from, so we assumed an average recovery time of 15 ± 5 days[1].
Vaccine Specific — The code takes into consideration the initial vaccination status of the population at a given time as well as the amount of time to become fully vaccinated under 2-dose vaccines, such as the Pfizer-BioNTech vaccine or the Moderna vaccine.
Population Specific — The code initializes the vectors to keep track of the status of individuals as the simulation progresses.  The five possible states are as follows: susceptible, infected, vaccinated, recovered, and deceased.
Movement — The code takes into consideration population mobility, with the assumption that individuals who are socially distant remain immobile. Their current position, direction, and speed are considered. A collision vector is also initialized to determine which individuals come into contact with each other.

# Infected Individual Checks
We consider the status of an infected individual as the simulation progresses. There are three cases that can occur:
Case 1 — The infected individual dies.  Update their state to deceased and prevent their mobility.
Case 2 — The infected individual recovers from COVID-19.  Update their state to recovered.  Unlike case 1, their mobility is unaffected.
Case 3 — The infected individual remains infected.  No state update.  We decrement how much longer it will take for the individual to recover.

# Vaccination Checks
We consider the status of a susceptible individual waiting for a vaccine as the simulation progresses. There are two cases that can occur:
Case 1 — The time to receive a vaccine has elapsed for a susceptible individual.  Update their state to vaccinated.
Case 2 — The time to receive a vaccine has not elapsed for a susceptible individual.   No state update.  We decrement how much longer it will take for the individual to be vaccinated.

# Collision Checks
As the simulation progresses, we identify which individuals have collided and considered the following:
Mobility — With the exception of immobile (either deceased or socially distant) individuals, as individuals collide, they follow the laws of momentum.  Their direction, position, and movement speed are recalculated upon collision to determine their future movements.
Boundaries — Individuals may not leave the bounds of the simulation map.  If an individual encounters a map boundary, treat the interaction as if it was a collision and ‘bounce’ the object in an appropriate direction.

# Transmission Checks
If two individuals collide with each other, we consider whether either person is infected.  There are four possible cases:
Case 1: There is one infected individual and one recovered, vaccinated, or deceased individual.  No COVID-19 transmission occurs.
Case 2: There is one infected individual and one susceptible individual.  We perform a probability check based on the infectivity of COVID-19.  This will determine whether the individuals will be infected.  Their states are updated accordingly.
Case 3: Both individuals are infected.  There is no need to update the status of either.
Case 4: Neither individual is infected.  There is no need to consider COVID-19 transmission.

# Plotting
The MATLAB code initializes the vectors to update the colors of each individual depending on their state.  Furthermore, we compute each state’s population percentage to give a better visualization of our simulation data.

# Results
As it stands, the MATLAB code can effectively produce a visualization of the COVID-19 stochastic discrete event simulation.  In comparison to data received from the New York Time’s Massachusetts COVID-19 case information[3] we have found that our prediction model serves as a good model based on historical numbers received. We are able to isolate variables such as social distancing proportion, transmission rate, and average vaccination time and test such cases against a base case to determine the significance of the impact of certain variables.  Our results utilize information taken from the CDC website as of April 19, 2021.  We use the following base case:
Simulation Duration: 90 days
Population Size: 200
Map Size: 600 feet
Transmission Rate: 40%
Initial Infected Population: 3%
Infection Radius: 6 feet
Average Vaccination Time: 30 ± 10 days
Mortality Rate: 1.7%
Average Recovery Time: 15 ± 5 days


# Analysis
# Overview
In the scope of the 90-day simulation period, the results demonstrate interesting but unsurprising trends.  At best, we see that herd immunity can best be reached via distributing vaccinations as quickly as possible.  With an average vaccination time of 20 ± 10 days, herd immunity will be reached in 29 days with COVID-19 dying out a mere 11 days after herd immunity is reached.  In the worst-case scenario, social distancing is not actively practiced.  We see that although the herd immunity date does not improve (we attribute the 2-day difference to random variance within our simulation), COVID-19 duration significantly worsens, dying out at 64 days.  We discuss our findings in detail below.
# Social Distancing
As the proportion of nodes that are socially distant increases, we see that vaccination herd immunity date gradually decreases until a threshold value of 37-38 days is reached.   In regards to COVID-19 duration, we see that as more people are socially distant, COVID-19 dies out in a significantly shorter period of time — this is especially notable as the social distancing proportion increases from 60% to 80%.

# Transmission Rate
As the transmission rate increases, we see that the vaccination herd immunity date rapidly increases at an exponential rate until at higher transmission rates (80% and 100%) we see that the vaccination herd immunity is not reached due to COVID-19 spreading rapidly to susceptible individuals.  However, one notable observation is that at 80% and 100% transmission rate, COVID-19 dies out in a shorter period of time compared to 40% and 60% transmission rate.  We hypothesize that this is due to COVID-19 spreading too quickly to susceptible nodes.  With such a high transmission rate, many susceptible nodes will have become infected early into the simulation (i.e. before vaccination time occurs) leading to COVID-19 dying out due to a lack of susceptible nodes to infect.

# Average Vaccination Time
As average vaccination time increases, we see that unsurprisingly, the vaccination herd immunity date increases.  It is notable, however, that with an average vaccination time of 40 ± 10 days, a threshold value appears to be reached with the COVID-19 duration at 64 days.

# Limitations
Nonetheless, the MATLAB model experiences one significant issue: scalability due to large computational time overhead (O(N3) time complexity), constraining us to downscale the all out the total population (i.e. lower node count) of Boston within the model. As a result, lower node count may result in lower precision. This may be resolved by utilizing data structures (e.g. hash maps) to improve the computational overhead and accordingly, consider for higher population valuations. Additionally, consistency of vaccine distribution rates may change contingent upon outer factors, such as arising COVID-19 strains, not considered within the scope of our simulation. Furthermore, it is difficult to maintain an exact and accurate simulation as the epidemiology landscape changes rapidly.

# Future Scope
As it stands, the web scraper acquires its information from the CDC and computes them as a moving average.  Due to COVID-19’s inherent nature as a virus, COVID-19 rapidly changes over the course of time leading to less precise moving average values.  We seek to implement usage of recent data to compute more precise values and parameters for input into the MATLAB simulation.  Moreover, we aim to streamline parameter updating by improving the connectivity between the Python web scraper and the MATLAB simulation.  We aim to remove the necessity of generating a .csv file for the simulation to parse its parameter data from.  Optimally, parameter data from the web scraper will be directly fed into the simulation without the usage of intermediary files. 
Additionally, we seek to improve the scalability of our model via optimization of our algorithm — this may be resolved via utilization of data structures.  Furthermore, distributed simulations are well-known to give performance improvements for complex simulation models.  Scalability improvements may be possible via usage of parallelization and perhaps even linking additional simulation models to this model.
We also aim to make the code more robust via various functionality implementations. Because COVID-19 is a virus, it inherently has the predisposition to rapidly mutate and evolve into several variants over a short period of time.  We will take into consideration how these strains differ in the future.  Improvements on both the vaccination prediction model and the mobility design can also be made.  Currently, our model assumes a static approach for both, i.e. vaccinations distribution rate is constant and nodes mobility is linear until collisions occur.  We seek to implement more dynamic considerations such as vaccination shortages and non-linear node mobility in the future.  Population-specific improvements such as susceptibility conditions (e.g. immunocompromised or elderly) and node clustering for better representation of social distancing circles will also be considered.

# Conclusion
COVID-19 has cemented itself globally as the worst pandemic to occur in recent history.  As such, it is absolutely crucial for data to be quickly compiled and analyzed for better transparency and information in regards to the virus.  We have developed a MATLAB simulation tool to help predict future trends, specifically herd immunity and COVID-19 remaining duration, based on various parameters such as social distancing, transmissibility, and vaccination rates.  These simulation parameters are either taken directly or inferred from data on the CDC website via a Python web scraper.  Our results show that, as of April 19, 2021, herd immunity will reasonably be reached between 29 - 57 days and COVID-19 will die out between 40 - 64 days.  Furthermore, we find that vaccination distribution rates have the greatest impact on herd immunity whereas social distancing has the greatest impact on COVID-19 duration.  Overall, these are very promising initial results and expectations — we will continue to develop our model to improve precision and robustness for future utilization.
