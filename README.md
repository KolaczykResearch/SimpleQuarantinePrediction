# SimpleQuarantinePrediction
This repository contains code supporting the text "Projecting quarantine utilization during a pandemic".



## R

* Projecting quarantine utilization over a 10 day window: getQuarPred.R
* Figure 3 (a): fig3a.R
* Figure 3 (b): fig3b.R

## Python

This directory contains codes for the simulation study. We used a stochastic agent-based model for transmission of SARS-CoV-2, implemented by the software tool for BU COVID prediction exercise described in Hamer, Davidson H., et al. "Control of COVID-19 transmission on an urban university campus during a second wave of the pandemic." medRxiv (2021). Software details are available on https://github.com/bu-rcs/BU-COVID.

* Simulation scenario 1) no superspreading events: no_superspreading_event.py
* Simulation scenario 2) having a superspreading event: superspreading_event.py

## Data

This directory contains data of an artificial university. The details of generating data can be found at https://github.com/bu-rcs/BU-COVID.

## Results

This directory contains results of running two simulations: 1) no superspreading events and 2) having a superspreading event.
