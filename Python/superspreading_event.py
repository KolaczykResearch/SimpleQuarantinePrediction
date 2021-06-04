 #!/usr/bin/env python3
 # -*- coding: utf-8 -*-

 ## ============================================================================
 ## Simulation scenario 2) superspreading events
 ## ============================================================================
 
 import matplotlib
 # With this line the plots will not show up on the screen
 # but they will be saved. Comment it out if you want to see plots
 # on the screen.  This MUST be called before the "import sciris" line.
 matplotlib.use('Agg')

 import covasim as cv
 from igraph import Graph
 import sciris as sc
 import os
 from matplotlib import pyplot as plt
 import numpy as np

 # this ***MUST*** be imported after covasim.
 import bu_covid as bu

 # Location of classroom networks
 net_dir = '../Data/Networks'
 # Location of housing networks
 hnet_dir = '../Data/Networks'
 # Location of pop_info.csv
 pop_info_path = '../Data/PopInfo/pop_info.csv'

 # Name of this simulation for output files:
 sim_name = 'superspreading_event'

 # =============================================================================
 #  Setting
 #
 #        Per-layer beta multiplicative factors
 #        Classroom and housing networks in place.
 #        Classroom networks 'on' only on class days
 #        Platooning turned on
 #        Housing density reduced
 #        Self-attestation for testing is on
 #        Testing is on
 #        Tracing is on
 #        Superspreading event
 # =============================================================================

 # Set a destination for plots and graphml files
 plot_dir = '../Results'

 # Make sure the plot directory exists
 os.makedirs(plot_dir, exist_ok = True)

 # Set the number of parallel runs
 n_runs = 1000

 # Set the average number of imported cases per day
 n_imports = 2
     
 # Set beta multiplicative factors per-layer
 beta_roommate = 0.15
 beta_household = 0.04
 beta_floor = 0.02
 beta_class = 0.01

 # Set test sensitivity
 test_sensitivity = 0.9

 # Set contract tracing sensitivity and specificity
 trace_sensitivity = 0.3
 trace_specificity = 0.9
     
 # Set cleaning days for quarantine and isolation rooms
 quar_cleaning_days = 1
 iso_cleaning_days = 1

 # Set isolation period
 iso_days = 10

 # Set self-attestation rate for testing
 self_report_prob = 0.75
 
 # Set size of superspreading events
 n_event_infect = 20
    
 # =============================================================================
 #  Build class networks
 # =============================================================================
 
 class_files = ['ClassNetPlatoonU.graphml',
                'ClassNetPlatoonM.graphml',
                'ClassNetPlatoonT.graphml',
                'ClassNetPlatoonW.graphml',
                'ClassNetPlatoonR.graphml',
                'ClassNetPlatoonF.graphml',
                'ClassNetPlatoonS.graphml',
                ]
 graphs = [Graph.Read_GraphML(os.path.join(net_dir, cf)) for cf in class_files]
 #if not bu.validate_graphs(graphs):
 #    raise Exception('Graph vertices do not match!  Exiting.')
     
 class_layer_names = ['sun','mon','tue','wed','thu','fri','sat']
 class_contacts = bu.get_all_class_contacts_dicts(graphs, class_layer_names, 3)

 # =============================================================================
 #  Build housing networks
 # =============================================================================
 
 h_files = ['RoomNet.graphml',
            'HouseholdNet_10.graphml',
            'FloorNet.graphml']
 hgraphs = [Graph.Read_GraphML(os.path.join(hnet_dir, hf)) for hf in h_files]

 #if not bu.validate_graphs(hgraphs):
 #    raise Exception('Graph vertices do not match!  Exiting.')
     
 hlayer_names = ['roommate','household','floor']
 household_contacts = bu.get_all_housing_contacts_dict(hgraphs, hlayer_names)
  
 # =============================================================================
 #  Build BU population dictionary
 # =============================================================================
 
 # Use net_dir to load the all_age.txt and all_sex.txt files
 people_lut = bu.load_people_info(pop_info_path)
 BU_pop = bu.gen_BU_pop2(people_lut, class_contacts,household_contacts)

 # =============================================================================
 #  Build intervention
 # =============================================================================
 
 # The semester starts
 start_day = '2020-09-02'
 end_day = '2020-12-19'

 # Total number of simulation days
 num_days = (bu.make_dt(end_day) - bu.make_dt(start_day)).days

 # The population size
 pop_size=BU_pop['uid'].shape[0]

 # Base transmission rate
 beta_val = 0.02

 # Set the quarantine and isolation beta multipliers
 quar_factor = {}
 iso_factor = {}
 for key in {**household_contacts, **class_contacts}:
     quar_factor[key] = 0.0
     iso_factor[key] = 0.0
     
 # Set up simulation parameters.  Get the pop size from the number of
 # vertices in any of the graphs (they're all the same)
 pars = dict(pop_size = pop_size,
             pop_infected = 0, # Initial number of infected people
             beta = beta_val,
             start_day = start_day,
             end_day = end_day,
             quar_factor = quar_factor,
             iso_factor = iso_factor,
             asymp_factor=0.5,
             n_imports=n_imports,
             rescale=False,
             quar_period=10) # Quarantine period

 # =============================================================================
 #     Classroom interventions
 # =============================================================================

 base_interventions = []

 beta_layer = {}
 for key in class_contacts:
     beta_layer[key] = beta_class/beta_val
 beta_layer['roommate'] = beta_roommate/beta_val,
 beta_layer['household'] = beta_household/beta_val,
 beta_layer['floor'] = beta_floor/beta_val
 for key in beta_layer:
     base_interventions.append(cv.change_beta(days=0, changes=beta_layer[key], layers=key))
     
 class_interventions = []
 for day_num, day in enumerate(class_layer_names):
     # In the layer_contact_lists find a matching day name
     for key in class_contacts:
         if key.find(day) >= 0:
             class_interventions.append(bu.gen_daily_interventions(start_day,end_day,[key],[day_num,],[1.0,0.0],cv.clip_edges))

 base_interventions += class_interventions

 # =============================================================================
 #   Testing interventions + self-attestation
 # =============================================================================

 base_interventions += bu.gen_periodic_testing_interventions(BU_pop, num_days,test_period=3)

 base_interventions.append(cv.test_prob(start_day = 0, test_delay = 1, symp_prob = self_report_prob,asymp_prob = 0.0,test_sensitivity=test_sensitivity))

 # =============================================================================
 #   Contact tracing (roommate, household, floors and classrooms)
 # =============================================================================

 trace_probs={}
 trace_time={}
 trace_sens={}
 trace_spec={}
 for layer in {**class_contacts, **household_contacts}:
     trace_probs[layer]= 0
     trace_time[layer] = 1
     trace_sens[layer]=trace_sensitivity
     trace_spec[layer]=trace_specificity
    
 trace_probs['roommate'] = 1.0
 trace_probs['household'] = 1.0

 trace_sens['roommate'] = 1.0
 trace_sens['household'] = 1.0

 trace_spec['roommate'] = 0
 trace_spec['household'] = 0

 interv_contact_trace_log = bu.contact_tracing_sens_spec_log(start_day=start_day,trace_sensitivity=trace_sens,trace_specificity=trace_spec, trace_time=trace_time,presumptive=True)
 base_interventions.append(interv_contact_trace_log)

# =============================================================================
#  Superspreading event
# =============================================================================

pulse_dates = np.zeros(num_days+1,dtype=np.int32)
pulse_dates[59] = 1 # Oct 31
pulse = bu.import_infections_percent_network(pulse_dates,import_count=n_event_infect)
base_interventions.append( pulse )

#%%
# =============================================================================
#  Run the simulations
# =============================================================================

interventions = base_interventions.copy()

verbose = False # keep the simulations quiet
if n_runs == 1:
    verbose = True  #unles there's just 1.

# Create the list of daily snapshot objects
analyzers = bu.get_BU_snapshots(num_days, quar_cleaning_days, iso_cleaning_days, iso_days)

sim=cv.Sim(pars=pars, popfile=BU_pop, verbose = verbose, load_pop = True,
           interventions = interventions, analyzers=analyzers)

# Update the sim with our extra categories
bu.update_sim_people(sim,BU_pop)

sims_complete = bu.parallel_run_sims(sim, n_runs = n_runs, n_cores = bu.get_n_cores())

msim = cv.MultiSim(sims_complete)
msim.reduce()

print("Creating dataframes")

pos_test_date_count_df = bu.BU_pos_test_date_count.to_df(sims_complete)
quarantine_network_count_df = bu.BU_quarantine_network_count.to_df(sims_complete)

# =============================================================================
#  Output
# =============================================================================

print('Generating plots')

with  open(os.path.join(plot_dir,'pos_test_date_count_%s.csv' % sim_name), 'w') as f:
    pos_test_date_count_df.to_csv(f)

with  open(os.path.join(plot_dir,'quarantine_network_count_%s.csv' % sim_name), 'w') as f:
    quarantine_network_count_df.to_csv(f)
