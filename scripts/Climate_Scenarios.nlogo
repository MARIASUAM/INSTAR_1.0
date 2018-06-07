extensions [ ;; Extensions: careful, download the right versions of the extensions and NetLogo (5.2)
  gis ;; gis allows loading of GIS data (vectors and rasters)
  time ; v 1.1.0 : https://github.com/colinsheppard/time/
  rnd ;; v 1.1.0 : Adds primitives for doing weighted random selection; http://ccl.northwestern.edu/netlogo/docs/arraystables.html ;; https://github.com/NetLogo/Rnd-Extension#readme
  table ;; https://github.com/NetLogo/CSV-Extension#from-file
  csv ;; custom-logging; https://github.com/NetLogo/Custom-Logging-Extension/#readme
  profiler
]

globals [
;; INTERNAL VARIABLES
;; ==============
  yesterday ;; saves the day of yesterday
  today
  initialization_date
  start_date
  hours_leap_year
  hours_normal_year
  today_insolation_hours
  area ;; extension of the bounding box of working area
  ; my_landscape ;; contains the list of patches that conform the scenario: which patches will be part of it (1) or not (0). NOT NEEDED if world is the whole NetLogo space, used in older versions of INSTAR
  orientations ;; angles list for each orientation
  orientations-suitability ;; list of suitability of the positions; the higher the value, the worse the suitability
  ;; positions-orientations ;; list of positions names and associated values

  ;; pines
  pines-dataset
  max-suitability-moths
  production

  ;procession_crit
  ;lay_crit

;; OUTPUT VARIABLES
;; ==============
  ;; State variables of plague; they define the total number of individuals in each phase, each day, for the whole world
  stat_egg
  stat_L1
  stat_L2
  stat_nymph
  stat_moth
  ; Variables that sum the stat_* of each day, and at the end of the month are divided by counter, resulting in the monthly mean of each instar for the whole world
  month_st_egg
  month_st_L1
  month_st_L2
  month_st_nymph
  month_st_moth
  counter ; This variables will be used as a day counter to calculate monthly means.

  ;; State variables of hosts
  stat_hosts_quantity ; quantity
  stat_infected ; Percentage of infected pines
  month_st_hosts_quantity
  month_st_infected

  ;; Output files
  execution_name
  day_table
  month_table
  table_bags
  table_nymphs
  ; table_exp2
  ; table_ins_hours
  ; testing_parasitism
  ; testing_initialize_pines
  ; testing_initialize_eggs
  ; emergence_table
  ; hatch_dates
  ; procession_dates
  ; lay_dates

;; EXTERNALY DEFINED PARAMETERS
;; ==============
  ; start_date
  end_date
  elevation_path
  pines_path
  cover_path
  wimmed_path
  patch_size
  max_infectation
  carrying_cap_coef_b0
  carrying_cap_coef_b1
  NPP_rate
  quality_threshold
  ; mean_quantity (in slider)
  ; sd_quantity (in slider)
  mean_clutch
  sd_clutch
  egg_parasitism_coef_b0
  egg_parasitism_coef_b1
  L1_mort_quality
  L2_mort_rate
  L2_mort_quantity_threshold
  lethal_tmin
  lethal_tmax
  min_days_as_egg
  min_days_as_L1
  min_days_as_L2
  max_days_as_nymph
;  dev_t_eggs
;  high_thr_t_larvae
;  dev_ti_larvae
;  low_thr_t_larvae
  max_procession_dist ; disabled for StressTest_max_procession_dist
  emergence_success_coef_b0
  emergence_success_coef_b1
  ; max_pine_density (old)
  max_mating_distance
  max_flight_distance
]

;; ENTITIES AND THEIR STATE VARIABLES
;; ==============
breed [hosts host]
breed [colonies colony]
breed [moths moth]
breed [nymphs nymph]

patches-own [
  elevation
  ;tmean
  tmax
  tmin
  ; radiation
  ; precipitation
  ; soil_moisture
  land_cover

  success_prob
  emergence_prob

  ;; Output variables in .asc format
  asc_eggs
  asc_L1
  asc_L2
  asc_nymphs
  asc_moths
  asc_hosts_quantity
  asc_infected
]

hosts-own [
  ; species
  quantity ;; in older versions: energia
  ; production ; optimizing, I make production a global variable
  quality
  height
  neighbours
  suitability-moth
  carrying_cap
  daily_consumption_per_colony ; for optimization purposes, included as variable
]

colonies-own [
  instar
  ; energy
  number_individuals ;; Real number of individuals alive
  clutch_individuals_number ;; Initial number of individuals (same as number_individuals in Function 4)
  parasitized_individuals
  ; not_born_individuals ;; For statistics, needed?
  days_as_egg ; negative counter to which in each tick the value 1 (a day) is substracted plus the bonification if there is, allowing the change in phase when counter reaches to 0
  days_as_L1
  days_as_L2
  shorten_nymph
  ;hatch_date
  ;procession_date
]

nymphs-own [
 ; energy
 number_individuals
 days_as_nymph
 shorten_nymph
 ;lay_date
]

moths-own [
  ; energy
  sex
  mated?
]

;; ==============
;; INITIALIZATION
;; ==============
to setup
 ca ; clear-all
  ;random-seed 137 ;; set seed, to be able to use the "random" functions and always get the same sequence of numbers. 137 is the example in the manual

  ;; Initialization of global variables
  ;; ====================================
  let scenario word replicate "_NORMAL_"
  set execution_name word (remove ":" date-and-time) scenario
  read_parameters "../inputs/parameters_Climate_Scenarios_PLUS10.txt"
  ;read_parameters "../inputs/parameters_Climate_Scenarios_MINUS10.txt"
  ;read_parameters "../inputs/parametros_noenddate.txt" ; for calibration purposes
  ;read_parameters "../inputs/parametros_StressTest_max_procession_dist.txt" ; for StressTest_max_procession_dist
  ;set lethal_tmin lethal_tmin_testing ; for calibration purposes
  ;set lethal_tmax lethal_tmax_testing ; for calibration purposes
  set initialization_date "2001-07-29"
  ;set initialization_date word calibration_year "-07-29" ; for egg calibration purposes
  ;set initialization_date word calibration_year "-08-14" ; for larvae calibration purposes (mean of hatch_dates in egg calibration)
  set start_date time:create initialization_date ; for calibration purposes
  set today time:create initialization_date ; for calibration purposes
  ;set today time:create start_date
  ;set end_date time:plus initialization_date 15 "months" ; for calibration purposes
  set orientations (list 0 45 90 135 180 225 270 315)
  set orientations-suitability (list 50 80 95 50 10 5 10 5) ;; Higher value, worse suitability
  set hours_normal_year (list 0 9.51 9.52 9.53 9.54 9.55 9.56 9.58 9.59 9.61 9.63 9.65 9.66 9.68 9.70 9.73 9.75 9.77 9.79 9.82 9.84 9.87 9.89 9.92 9.95 9.98 10.00 10.03 10.06 10.09 10.12 10.15 10.19 10.22 10.25 10.28 10.32 10.35 10.39 10.42 10.45 10.49 10.53 10.56 10.60 10.63 10.67 10.71 10.74 10.78 10.82 10.86 10.89 10.93 10.97 11.01 11.05 11.09 11.12 11.16 11.20 11.24 11.28 11.32 11.36 11.40 11.44 11.48 11.52 11.56 11.60 11.64 11.68 11.72 11.76 11.80 11.84 11.87 11.91 11.95 11.99 12.03 12.07 12.11 12.15 12.19 12.23 12.27 12.31 12.35 12.39 12.43 12.47 12.51 12.54 12.58 12.62 12.66 12.70 12.74 12.78 12.81 12.85 12.89 12.93 12.96 13.00 13.04 13.08 13.11 13.15 13.19 13.22 13.26 13.29 13.33 13.36 13.40 13.43 13.47 13.50 13.53 13.57 13.60 13.63 13.67 13.70 13.73 13.76 13.79 13.82 13.85 13.88 13.91 13.94 13.97 13.99 14.02 14.05 14.07 14.10 14.13 14.15 14.17 14.20 14.22 14.24 14.26 14.28 14.30 14.32 14.34 14.36 14.37 14.39 14.41 14.42 14.44 14.45 14.46 14.47 14.48 14.49 14.50 14.51 14.52 14.52 14.53 14.53 14.54 14.54 14.54 14.54 14.55 14.54 14.54 14.54 14.54 14.53 14.53 14.52 14.52 14.51 14.50 14.49 14.48 14.47 14.46 14.45 14.44 14.42 14.41 14.39 14.38 14.36 14.34 14.32 14.30 14.28 14.26 14.24 14.22 14.20 14.18 14.15 14.13 14.10 14.08 14.05 14.03 14.00 13.97 13.94 13.92 13.89 13.86 13.83 13.80 13.77 13.74 13.71 13.67 13.64 13.61 13.58 13.54 13.51 13.48 13.44 13.41 13.37 13.34 13.31 13.27 13.23 13.20 13.16 13.13 13.09 13.05 13.02 12.98 12.94 12.91 12.87 12.83 12.80 12.76 12.72 12.68 12.64 12.61 12.57 12.53 12.49 12.45 12.41 12.38 12.34 12.30 12.26 12.22 12.18 12.14 12.10 12.06 12.03 11.99 11.95 11.91 11.87 11.83 11.79 11.75 11.71 11.67 11.63 11.59 11.56 11.52 11.48 11.44 11.40 11.36 11.32 11.28 11.24 11.21 11.17 11.13 11.09 11.05 11.01 10.98 10.94 10.90 10.86 10.83 10.79 10.75 10.72 10.68 10.64 10.61 10.57 10.54 10.50 10.47 10.43 10.40 10.36 10.33 10.30 10.26 10.23 10.20 10.17 10.14 10.11 10.08 10.05 10.02 9.99  9.96 9.93 9.91 9.88 9.85 9.83 9.81 9.78 9.76 9.74 9.71 9.69 9.67 9.66 9.64 9.62 9.60 9.59 9.57 9.56 9.54 9.53 9.52 9.51 9.50 9.49 9.49 9.48 9.47 9.47 9.46 9.46 9.46 9.46 9.46 9.46 9.46 9.47 9.47 9.48 9.48 9.49 9.50)
  set hours_leap_year   (list 0 9.51 9.52 9.53 9.54 9.55 9.56 9.58 9.59 9.61 9.63 9.64 9.66 9.68 9.70 9.72 9.75 9.77 9.79 9.82 9.84 9.87 9.89 9.92 9.95 9.97 10.00 10.03 10.06 10.09 10.12 10.15 10.18 10.22 10.25 10.28 10.31 10.35 10.38 10.42 10.45 10.49 10.52 10.56 10.59 10.63 10.66 10.70 10.74 10.78 10.81 10.85 10.89 10.93 10.96 11.00 11.04 11.08 11.12 11.16 11.20 11.23 11.27 11.31 11.35 11.39 11.43 11.47 11.51 11.55 11.59 11.63 11.67 11.71 11.75 11.79 11.83 11.87 11.91 11.95 11.98 12.02 12.06 12.10 12.14 12.18 12.22 12.26 12.30 12.34 12.38 12.42 12.46 12.50 12.53 12.57 12.61 12.65 12.69 12.73 12.77 12.80 12.84 12.88 12.92 12.95 12.99 13.03 13.07 13.10 13.14 13.17 13.21 13.25 13.28 13.32 13.35 13.39 13.42 13.46 13.49 13.52 13.56 13.59 13.62 13.66 13.69 13.72 13.75 13.78 13.81 13.84 13.87 13.90 13.93 13.96 13.98 14.01 14.04 14.07 14.09 14.12 14.14 14.16 14.19 14.21 14.23 14.25 14.27 14.29 14.31 14.33 14.35 14.37 14.38 14.40 14.41 14.43 14.44 14.46 14.47 14.48 14.49 14.50 14.51 14.51 14.52 14.53 14.53 14.54 14.54 14.54 14.54 14.55 14.55 14.54 14.54 14.54 14.54 14.53 14.53 14.52 14.51 14.51 14.50 14.49 14.48 14.47 14.46 14.44 14.43 14.41 14.40 14.38 14.37 14.35 14.33 14.31 14.29 14.27 14.25 14.23 14.21 14.19 14.16 14.14 14.12 14.09 14.07 14.04 14.01 13.99 13.96 13.93 13.90 13.88 13.85 13.82 13.79 13.76 13.72 13.69 13.66 13.63 13.60 13.56 13.53 13.50 13.46 13.43 13.40 13.36 13.33 13.29 13.26 13.22 13.19 13.15 13.11 13.08 13.04 13.01 12.97 12.93 12.89 12.86 12.82 12.78 12.74 12.71 12.67 12.63 12.59 12.56 12.52 12.48 12.44 12.40 12.36 12.32 12.29 12.25 12.21 12.17 12.13 12.09 12.05 12.01 11.98 11.94 11.90 11.86 11.82 11.78 11.74 11.70 11.66 11.62 11.59 11.55 11.51 11.47 11.43 11.39 11.35 11.31 11.27 11.24 11.20 11.16 11.12 11.08 11.04 11.01 10.97 10.93 10.89 10.86 10.82 10.78 10.75 10.71 10.67 10.64 10.60 10.57 10.53 10.49 10.46 10.43 10.39 10.36 10.32 10.29 10.26 10.23 10.19 10.16 10.13 10.10 10.07 10.04 10.01 9.98 9.96 9.93 9.90 9.88 9.85 9.83 9.80 9.78 9.76 9.73 9.71 9.69 9.67 9.65 9.64 9.62 9.60 9.59 9.57 9.56 9.54 9.53 9.52 9.51 9.50 9.49 9.48 9.48 9.47 9.47 9.46 9.46 9.46 9.46 9.46 9.46 9.46 9.47 9.47 9.48 9.48 9.49 9.50)
  set max-suitability-moths 0

  ;; Initialization of agents
  ;; ====================================

  initialize_landscape ;; Initialization of landscape (Function 11)
  initialize_pines ;; Initialization of pines (Function 1)

  ask patches [
    let n egg_parasitism_coef_b0 + (egg_parasitism_coef_b1 * elevation)
    set success_prob (e ^ n) / (1 + (e ^ n))

    let my_shaders count hosts-here
    set emergence_prob emergence_success_coef_b0 + (emergence_success_coef_b1 * my_shaders)
    ifelse emergence_prob < 0
     [ set emergence_prob 0 ]
     [ set emergence_prob min (list emergence_prob 0.12) ]
    ]

  initialize_eggs ;; Initialization of bags (Function 3)
  ;set-default-shape nymphs "target" ;; Initialization of nymphs shape.
  ;set-default-shape moths "butterfly" ;; Initialization of moths shape

  ;; Initialization of outputs
  ;; ====================================
  set day_table lput (list "today" "today_insolation_hours" "stat_egg" "stat_L1" "stat_L2" "stat_nymph" "stat_moth" "stat_hosts_quantity" "stat_infected") []
  set month_table lput (list "days_in_month" "date" "month_st_egg" "month_st_L1" "month_st_L2" "month_st_nymph" "month_st_moth" "month_st_hosts_quantity" "month_st_infected") []
  ;set table_bags lput (list "date" "id" "number_individuals" "instar" "days_as_egg" "days_as_L1" "days_as_L2" "hatch_date" "procession_date" "id_hospedador" "quantity_host" "quality_host") []
  ;set table_nymphs lput (list "date" "id" "number_individuals" "days_as_nymph" "lay_date") []
  ; set testing_parasitism lput (list "colony" "clutch_individuals_number" "elevation" "n" "success_probability" "number_individuals") []
  ; set testing_initialize_pines lput (list "host" "height" "carrying_cap" "quantity" "quality" "suitability-moth") []
  ; set testing_initialize_eggs lput (list "host" "suitability-moth" "infected?") []
  ; set table_ins_hours lput (list "today" "today_insolation_hours") []
  ; set emergence_table lput (list "nymph" "clutch_individuals_number" "number pines" "emergence_prob" "number_individuals") []
  ;set hatch_dates []
  ;set procession_dates []
  ;set procession_crit 0
  ;set lay_dates []
  ;set lay_crit 0

  set counter 0
  reset-ticks ;; Reset clock
end

to go
  set yesterday today ;; Defines "today": what day was yesterday
  set today time:plus today 1 "days"  ;; "today" is increased one day

  ifelse ((time:get "month" today) >= 4 and (time:get "month" today) <= 8)
    [ set production NPP_rate ]
    [ set production 0 ]

  ;; Reads landscape variables for today and updates pest and hosts
  read_landscape ;; Reads landscape variables for today (Function 14)
  update_colonies ;; Function 5
  update_nymphs ;; Function 7
  update_moths  ;; Function 8
  update_hosts ;; Function 10

  ;; Generates outputs
  set day_table lput (list (time:show today "yyyy-MM-dd") today_insolation_hours stat_egg stat_L1 stat_L2 stat_nymph stat_moth stat_hosts_quantity stat_infected) day_table
  ; save_monthly_landscape
  ; set table_ins_hours lput (list (time:show today "yyyy-MM-dd") today_insolation_hours) table_ins_hours

  tick ;; Increase one tick

  ;; Results and reports are written at the end of the simulation (when simulation reaches "end_date")
  if (time:show today "yyyy-MM-dd") = (time:show end_date "yyyy-MM-dd") [
    write_results
    write_report
    stop
  ]
end

to optimize
  profiler:start         ;; start profiling
  setup                  ;; set up the model
  repeat 1000 [ go ]     ;; run something you want to measure
  write_results
  write_report
  profiler:stop          ;; stop profiling
  print profiler:report  ;; view the results
  profiler:reset         ;; clear the data

end

to calibrate
  while [(time:show today "yyyy-MM-dd") != (time:show end_date "yyyy-MM-dd")] [ go ]

;  foreach procession_dates [
;    if ((? >= 1)   AND (? <= 124)) [ set procession_crit procession_crit ]
;    if ((? >= 331) AND (? <= 366)) [ set procession_crit procession_crit ]
;    if ((? > 124) AND (? <= 139)) [ set procession_crit procession_crit + ( ( mean [124 139] - ?) / (mean [124 139])) ^ 2 ]
;    if ((? > 139) AND (? < 331)) [ set procession_crit procession_crit + ( ( mean [139 331] - ?) / (mean [139 331])) ^ 4 ]
;  ]

; Activate if calibrating (together will all lay_date/s, hatch_date/s and procession_date/s along the whole code
;  foreach procession_dates [
;    if ((? >= 1)   AND (? <= 124)) [ set procession_crit procession_crit ]
;    if ((? >= 331) AND (? <= 366)) [ set procession_crit procession_crit ]
;    if ((? > 124) AND (? <= 139)) [ set procession_crit procession_crit + 1 ]
;    if ((? > 139) AND (? < 331)) [ set procession_crit procession_crit + 10 ]
;  ]
;
;  foreach lay_dates [
;    if ((? >= 167) AND (? <= 261)) [ set lay_crit lay_crit ]
;    if ((? >= 99) AND (? < 167)) [ set lay_crit lay_crit + 1 ]
;    if ((? > 261) AND (? <= 275)) [ set lay_crit lay_crit + 1 ]
;    if ((? < 99) OR (? > 275)) [ set lay_crit lay_crit + 10 ]
;  ]

  stop
end


;; FUNCTION 1: Convert pines-dataset to agentset
to initialize_pines
  ;set-default-shape hosts "tree"

  set pines-dataset gis:load-dataset pines_path ;; Loading pines distribution
  foreach gis:feature-list-of pines-dataset [
    let location gis:location-of (first (first (gis:vertex-lists-of ?))) ;; for point datasets, each vertex list will contain 1 vertex
    create-hosts 1 [ ;; Creates a host for each vertex and gives it colour, height,...
      set height gis:property-value ? "Height"
      ;set height random-normal 8 2 ; Define height when attribute "Height" is not included in .shp file
      ;set height max list height 0 ; Height cannot be negative
      set carrying_cap round ( carrying_cap_coef_b0 + (carrying_cap_coef_b1 * ln height)) ;; According to JAH data: tree height and number of colonies for trees 90 % defoliated
      set daily_consumption_per_colony 90 / ( carrying_cap * min_days_as_L2 )
      set xcor item 0 location ;; Establishes coordinate x of the pine
      set ycor item 1 location ;; Establishes coordinate y of the pine
      ;set species "Pinus Silvestre"
      ;; set species gis:property-value ? "SP" ;; Enable when the .shp file includes the attribute "SP"

      set quantity truncated_mean mean_quantity sd_quantity ; In order to keep quantity between limits (0-100%), a truncated mean is calculated

      ifelse (quantity < quality_threshold)
         [ set quality "defoliated" ]
         [ set quality "no_defoliated" ]
    ]
  ]

  ;; Establishes the list of neighbours for each orientation
  ask hosts [
    set neighbours map my_neighbours orientations ;; neighbours is then a vector of number, that are obtained with "my_neighbours" (Function 2), in the same order as orientations. Example: (3 4 1 5 7 2 4 0), being 3 the number of pines in the cone N (-22.5º,+22.5º)
    set suitability-moth sum (map [?1 * ?2] neighbours orientations-suitability) ;; weights the neighbours according to their orientation ; Sum of the multiplication of "neighbours" and "orientations-suitability"
  ]

  set max-suitability-moths max [suitability-moth] of hosts ;; Maximum suitability-moth value, initialized as 0, max-suitability-moths is set as the maximum value of all "suitability-moth", to allow weighting in the corresponding function

;  ask hosts [
;     set color scale-color green suitability-moth 0 max-suitability-moths ;; Colours in green scale, being greener less suitability
;     set testing_initialize_pines lput (list who height carrying_cap quantity quality suitability-moth) testing_initialize_pines
;  ]

  set stat_hosts_quantity mean [quantity] of hosts
end

;; FUNCTION 2: reports the number of neighbours in a orientation (neighbours = number of pines per cone in each orientation)
to-report my_neighbours [orientation]
  set heading orientation
  report (count hosts in-cone-nowrap 1 45) - 1 ;; Substracts 1 to avoid counting itself. in-cone to give cone-vision to each pine. The “nowrap” condition ensures that agents at the edges of the world don’t “wrap around” to collect neighbors on the opposite edge
end

to-report truncated_mean [mean_value sd]
  set quantity random-normal mean_quantity sd_quantity
  if (quantity > 100 or quantity < 0) [set quantity truncated_mean mean_quantity sd_quantity]
  report quantity
end

;; FUNCTION 3: Eggs initialization
to initialize_eggs
  ;set-default-shape colonies "bug"
  let initial_moth_number round(max_infectation * (count hosts) / 100.0 ) ;; Quantity of fertilized moths

  ;; Select among existing pines
  ;; rnd:weighted-n-of-with-repeats size list reporter-task: reports a list (infected_pines) of a given size (initial_moth_number) randomly chosen from the list (hosts), with repetitions.
  ;; Besides, in this case a reporter-task is added ([ [ (1 - (suitability-moth / max-suitability-moths)) ] of ? ]) which is: probability of each item being picked
  ;; So, what it does is to define infected_pines as a list of hosts of a specific size (the num_incial_moths, which limits how many pines can be infected) with repetitions,
  ;; since two moths can lay eggs on the same pine. Moreover, this list of hosts is not completely randomly chosen, but it depends on the suitability of the host for the moth (reporter-task).
  ;; The probability of being chosen will be higher as [1-X] will get closer to 1, i.e. when 0 gets closer to 0. Thus, the smaller the suitability-moth in relation to max-suitability-moths.

  let infected_pines rnd:weighted-n-of-with-repeats initial_moth_number hosts [ [ (1 - (suitability-moth / max-suitability-moths)) ] of ? ]

  ;; Creation of colony
  foreach infected_pines [
    ask ? [ ;; ask each "infected_pines"
      lay_eggs_on_host ;; Function 4
      ;lay_larvae_on_host ; for calibration purposes
    ]
  ]

;  ask hosts [
;    set testing_initialize_eggs lput (list who suitability-moth infected?) testing_initialize_eggs
;  ]

  ;; Defines the state variables of the plague (global variables). They are set as 0 except for stat_egg, which corresponds to the sum of number_individuals of the colony
  set stat_egg sum [number_individuals] of colonies
  set stat_L1 0
  set stat_L2 0
  set stat_nymph 0
  set stat_moth 0

  let infected count hosts with [count link-neighbors with [breed = colonies] > 0]
  let total count hosts
  set stat_infected infected * 100 / total
end

;; FUNCTION 4: Procedure to create eggs in hosts, to be used in the egg initialization (“initialize_eggs”) and in the procedure when moths lay eggs ("update_moths"). These functions define which are the hosts to be infected
to lay_eggs_on_host
      hatch-colonies 1 [ ; hatch creates an agent with the atributes of the "father", in this case the host (xcor, ycor). So, it hatches 1 colony and sets every trait except for num_ind_parasitados y no_nacidos
        set instar "egg" ;; We start on phase = "egg"
        ;set hatch_date "NaN"
        ;set procession_date "NaN"
        ; set energy random 101 ;; We establish energy as a random number between 0 and 100. random: If number is positive, reports a random integer greater than or equal to 0, but strictly less than number.
        ; set hidden? false;; Not drawn
        ; set color orange
        ;; set orientation_host item 0 rnd:weighted-one-of positions-orientations [ item 1 ? ]
        ;; weighted-one-of requiere "candidates" (the items that the primitive will select from, positions-orientations) y "weight" (how likely it is for each candidate to be selected, that correspond to item 1 of positions-orientations (0.3, 0.6, 0.9)).
        ;; Thus, orientations more appropiate are favoured because their weight is higher
        ;; set orientation_host rnd:weighted-one-of positions-orientations [ item 1 ? ] ;; We establish the position on the host. Example of result: ["NE" 0.9]

        set clutch_individuals_number round random-normal mean_clutch sd_clutch ; Initial number of individuals are established according to Torres-Muros study (values in PRM.6)

        ;; Submodel: Bags Mortality (egg stage)
;        let n egg_parasitism_coef_b0 + (egg_parasitism_coef_b1 * elevation) ; moved to setup
;        let success_probability (e ^ n) / (1 + (e ^ n)) ; moved to setup
        ifelse ( clutch_individuals_number * success_prob ) <= 0
            [ set number_individuals 0 ]
            [ set number_individuals round ( clutch_individuals_number * success_prob ) ]
        ; set testing_parasitism lput ( list who clutch_individuals_number elevation n success_probability number_individuals) testing_parasitism

        ifelse (time:show today "yyyy-MM-dd") = (time:show start_date "yyyy-MM-dd")
          [ set days_as_egg random min_days_as_egg + 1 ] ;; In the initialization, days_as_egg is a random value to not have such forced starting conditions
          [ set days_as_egg min_days_as_egg ] ;; minumum number of days as egg
        create-link-with myself ;; creates a link between host and colony (myself = host)
      ]
end

;to lay_larvae_on_host ; for larvae calibration purposes
;      hatch-colonies 1 [ ; hatch creates an agent with the atributes of the "father", in this case the host (xcor, ycor). So, it hatches 1 colony and sets every trait except for num_ind_parasitados y no_nacidos
;        set instar "L1" ;; We start on phase = "egg"
;        ;set hatch_date "NaN"
;        ;set procession_date "NaN"
;        set clutch_individuals_number round random-normal mean_clutch sd_clutch ; Initial number of individuals are established according to Torres-Muros study (values in PRM.6)
;        set number_individuals clutch_individuals_number
;        ifelse (time:show today "yyyy-MM-dd") = (time:show start_date "yyyy-MM-dd")
;          [ set days_as_L1 random min_days_as_L1 + 1 ]
;          [ set days_as_L1 min_days_as_L1 ]
;        create-link-with myself
;      ]
;end

;; FUNCTION 5: this procedure updates the colonies variables. It first updates each phase, and then kills each one if days_as_* are finished.
;; This is done by phase because otherwise the eggs with days_as_egg = 0 and therefore change to phase L1 will be included in the update of phase L1 (they would skip a tick, the one of the day when they "are born")
to update_colonies
  ifelse (remainder (time:get "year" today) 4 = 0)
    [ set today_insolation_hours (item time:get "dayofyear" today hours_leap_year) ]
    [ set today_insolation_hours (item time:get "dayofyear" today hours_normal_year) ]

  ask colonies [
    let ti ( tmax + ( today_insolation_hours * 1.5 ) )
    ;; What eggs do in each day
    if (instar = "egg") [
      ifelse (tmax > dev_t_eggs)
        [ set days_as_egg days_as_egg - 1 ]
        [ set days_as_egg days_as_egg
          set shorten_nymph shorten_nymph + 1 ]
      ]

    ;; What L1 do in each day
    if (instar = "L1")[
      if (tmin <= lethal_tmin) [ die ]
      if (tmax >= lethal_tmax) [ die ]

      ;; Development function: ticks are adjusted to L2
      ifelse ( tmax < high_thr_t_larvae and ti > dev_ti_larvae )
        [ set days_as_L1 days_as_L1 - 1 ]
        [ ifelse ( tmin > low_thr_t_larvae )
          [ set days_as_L1 days_as_L1
            set shorten_nymph shorten_nymph + 1 ]
          [ set days_as_L1 days_as_L1 + 1
            set shorten_nymph shorten_nymph + 2 ]
        ]
    ]

    ;; What L2 do in each day: PRB-LL.1
    if (instar = "L2")[
    ;; If the pine has no (or little) biomass, colonies on it die. Actually they should move to another pine, but now they die ;)
      let host_quantity first [quantity] of link-neighbors ;; link-neighbors gives a list of the links, since there will be only one we use the first one
      ifelse (host_quantity < L2_mort_quantity_threshold) ; Mortality function due to available food quantity
        [ set number_individuals number_individuals - ( L2_mort_rate * number_individuals ) ]
        [ set number_individuals number_individuals ]
      if (tmin <= lethal_tmin) [ die ]
      if (tmax >= lethal_tmax) [ die ]

      ;; Development function: ticks are adjusted to nymph
      ifelse ( tmax < high_thr_t_larvae and ti > dev_ti_larvae )
        [ set days_as_L2 days_as_L2 - 1 ]
        [ ifelse ( tmin > low_thr_t_larvae )
          [ set days_as_L2 days_as_L2
            set shorten_nymph shorten_nymph + 1 ]
          [ set days_as_L2 days_as_L2 + 1
            set shorten_nymph shorten_nymph + 2 ]
        ]
    ]

    if round ( number_individuals ) < 1
      [ print "a colony dies when it shouldn't"
        die ]

    ;; Ends of phase "egg"
    if (days_as_egg <= 0) and (instar = "egg")
      [ ;set hatch_date read-from-string (time:show today "D")
        ;set hatch_dates lput hatch_date hatch_dates
        set days_as_L1 min_days_as_L1
        set instar "L1"
        let host_quality first [quality] of link-neighbors ;; link-neighbors gives a list of the links, since there will be only one we use the first one
        ifelse (host_quality = "defoliated")
          [ set number_individuals number_individuals - (number_individuals * L1_mort_quality) ] ;; mortality if defoliated
          [ set number_individuals number_individuals ] ;; mortality if non-defoliated (0)
      ]

    ;; Ends of phase L1
    if (days_as_L1 <= 0) and (instar = "L1")
      [ set days_as_L2 min_days_as_L2
        set instar "L2" ]

    ;; Ends of phase L2
    if (days_as_L2 <= 0) and (instar = "L2") [
      ;set procession_date read-from-string (time:show today "D")
      ;set procession_dates lput procession_date procession_dates
      ;set table_bags lput (list (time:show today "yyyy-MM-dd") who number_individuals instar days_as_egg days_as_L1 days_as_L2 hatch_date procession_date (first [who] of link-neighbors) (first [quantity] of link-neighbors) (first [quality] of link-neighbors) ) table_bags
      let of_colony self ;; for the selected colony
      let my_host [other-end] of one-of [my-links] of of_colony ;; The host is captured, since it will be needed to create the link between the burial patch and the host

      ;; Submodel "Procession"
      ;; "When a colony in L2 has no days left, takes an area around (within max_procession_distance), among them chooses patches with densities < max_pine_density
      ;; and chooses the patch with minimum land_cover and min distance to myself (in case there are more than one patch with the minimum value of land_cover)"
      ;let min_land_cover min [land_cover] of patches in-radius max_procession_dist
      let min_pines min [count hosts-here] of patches in-radius max_procession_dist ; disabled for StressTest_max_procession_dist

      ;let pot_neighbours patches in-radius max_procession_dist with [land_cover = min_land_cover and count hosts-here <= max_pine_density]
      ;let pot_neighbours patches in-radius max_procession_dist with [land_cover = min_land_cover]
      let pot_neighbours patches in-radius max_procession_dist with [count hosts-here = min_pines] ; disabled for StressTest_max_procession_dist

      let best_neighbour min-one-of pot_neighbours [ distance myself ] ; disabled for StressTest_max_procession_dist

      ifelse (best_neighbour = nobody)
        [ print "no available spot" ]
        [ ask best_neighbour [
;       ask one-of neighbors [ ; for calibration purposes
            sprout-nymphs 1 [
              ;set number_individuals [number_individuals] of of_colony ; for testing and calibration
              set number_individuals round ( emergence_prob * [number_individuals] of of_colony ) ;; Number of individuals is calculated by applying chrysallis mortality function
              if number_individuals <= 0
                [ die ]
              ; set energy [energy] of of_colony ;; The nymph inherits the energy of the colony it comes from (not used in this version)

              set shorten_nymph [shorten_nymph] of of_colony
              set days_as_nymph max_days_as_nymph - shorten_nymph
              ;set lay_date "NaN"
              if days_as_nymph < 0
                [ print "no days left for nymph stage"
                  die ]
              ;set hidden? false;; Not drawn

              ;; Link between nymph and the host it comes from is created
              create-link-with my_host ;; of_colony what is the use of this?
              ;set emergence_table lput ( list who ([number_individuals] of of_colony) (count hosts-here) emergence_prob number_individuals) emergence_table ; testing emergence
            ]
         ]
        ]

; Older version of procession submodel
;      if empty? sort-by compare_nymph_landscape patches with [distance myself <= max_procession_dist and count hosts-here <= max_pine_density] = false [
;        ask first sort-by compare_nymph_landscape patches with [distance myself <= max_procession_dist and count hosts-here <= max_pine_density] [ ;; PRC.1
;          sprout-nymphs 1 [ ;; nymph creation
;            let p_exito emergence_success_coef_b0 + (emergence_success_coef_b1 * land_cover)
;            set number_individuals ceiling ( p_exito * [number_individuals] of of_colony ) ;; Number of individuals is calculated by applying chrysallis mortality function
;            set energy [energy] of of_colony ;; The nymph inherits the energy of the colony it comes from (PRC.4)
;            set shorten_nymph [shorten_nymph] of of_colony
;            set days_as_nymph max_days_as_nymph - shorten_nymph
;            set hidden? false;; Not drawn
;            ;; Link between nymph and the host it comes from is created
;            ;; TODO: value if the link is done at colony or host level --> now: host
;            create-link-with my_host ;; of_colony what is the use of this?
;          ] ] ]

      die ;; Once the nymph group has been created the colony can be eliminated
    ]

    ; set table_bags lput (list (time:show today "yyyy-MM-dd") who number_individuals instar days_as_egg days_as_L1 days_as_L2 hatch_date procession_date (first [who] of link-neighbors) (first [quantity] of link-neighbors) (first [quality] of link-neighbors) ) table_bags
  ]

  ;; Statistics
  set stat_egg sum [number_individuals] of colonies with [instar = "egg"]
  set stat_L1 sum [number_individuals] of colonies with [instar = "L1"]
  set stat_L2 sum [number_individuals] of colonies with [instar = "L2"]
end

;; FUNCTION 7
to update_nymphs
  ask nymphs [
    ;let my_energy energy ; not used in this version
    ;let moths_number ceiling (0.01 * number_individuals );; Once nymph mortality is parameterized (see previous lines), moths_number that will get born if days_as_nymph = 0 corresponds to number_individuals
    let moths_number number_individuals
    if number_individuals <= 0
      [ print "a cluster dies when it shouldn't"
        die ]

    ;; Development submodel
    set days_as_nymph days_as_nymph - 1

    ;; Start moth phase:
    if (days_as_nymph <= 0) [
      ask patch-here [
        sprout-moths moths_number [ ;; We create as many moths as individuals
          ; set energy my_energy ;; energy inherited from colony and nymph
          set sex one-of [ "F" "M" ] ;; sex is random
          set mated? false ;; not fertilized
          ;set hidden? false
          ;set color orange
        ]
      ]
      ; set lay_date read-from-string (time:show today "D")
      ; set lay_dates lput lay_date lay_dates
      ; set table_nymphs lput (list (time:show today "yyyy-MM-dd") who number_individuals days_as_nymph lay_date) table_nymphs
      die ;; the nymph dies
    ] ;; end of moth creation

ifelse count moths > 0
        [set stat_moth count moths]
        [set stat_moth 0]
  ]

  ;; Statistics: from the nymph that are left, count how many there are and sets stat_nymph as this number. And if there is no nymphs stat_nymph = 0 (to avoid NaN)
  ifelse count nymphs > 0
    [set stat_nymph sum [number_individuals] of nymphs]
    [set stat_nymph 0]
end

;; FUNCTION 8: moth update
to update_moths
  ;; ;; Submodel Mating
  ask moths with [sex = "F"] [ ;; For female moths, look for mating partner ;)
    let potential_partners moths with [sex = "M"] in-radius max_mating_distance
    if any? potential_partners and random 100 < 95 [
      let my_partner min-one-of potential_partners [ distance myself ]
      face my_partner
      let dist_to_partner distance my_partner
      fd dist_to_partner / 2 ;; We move in between both moths
      set mated? true ;; Change variables values
    ]
  ]

  ;; Ramón: Think if it is necessary to do it concurrently or sequentially, I think sequentially is enough
  ;; Submodel Oviposition
  ask moths with [sex = "F" and mated? = true] [
    let potential_hosts hosts in-radius max_flight_distance ;; draw a circle of reachable trees
    let selected_host rnd:weighted-one-of potential_hosts [ [ (1 - ( distance myself / max_flight_distance ) ) ] of ? ]
    ifelse (selected_host != nobody)
      [ ask selected_host ;; Chooses one of them randomly, weighting the selection by distance (shorter distance, higher probability of being chosen)
        [ lay_eggs_on_host ] ;; Lay eggs (Function 4)
      ]
      [ print (word "[update_moths - " who "] No close hosts") ] ; If there is no potential_hosts prints a message
  ]

  ask moths  ;; Moths live one day, so they die
    [ die ]
end

;; FUNCTION 10: Updates host variables
to update_hosts
  ask hosts [
    ;; quantity(t) = quantity (t-1) + primary production [0; 0.4] – consumption [n_bags_L2 * (90 / ( carrying_cap * max_days_as_L2 )]
;    ifelse ((time:get "month" today) >= 4 and (time:get "month" today) <= 8)
;      [ set production NPP_rate ]
;      [ set production 0 ]

    let number_L2_colonies count link-neighbors with [breed = colonies and instar = "L2"] ; How many colonies in L2 there is on the pine
    ; let daily_consumption_per_colony 90 / ( carrying_cap * min_days_as_L2 )
    let consumption daily_consumption_per_colony * number_L2_colonies

    ;; Biomass quantity cannot be above 100 or below 0 (%)
    set quantity min (list (quantity - consumption + production) 100 ) ;
    set quantity max (list quantity 0 )

    if ((time:get "month" today) = 3 and (time:get "day" today) = 31) [ ;; Biomass quality is defined at the end of the defoliating season
      ifelse (quantity < quality_threshold)
         [ set quality "defoliated" ]
         [ set quality "no_defoliated" ]
      ]
  ]

  ;; Statistics
  let infected count hosts with [count link-neighbors with [breed = colonies] > 0]
  let total count hosts
  set stat_infected infected * 100 / total
  set stat_hosts_quantity mean [quantity] of hosts
end

;; FUNCTION 11: Landscape initialization
to initialize_landscape
  ;; World dimensions are defined according to the layer given as area.
  set area gis:load-dataset elevation_path
  gis:set-world-envelope gis:envelope-of area

  let columns gis:width-of area - 1
  let rows gis:height-of area - 1
  resize-world 0 columns ( - rows ) 0
  set-patch-size patch_size

  gis:apply-raster gis:load-dataset elevation_path elevation ;; Load elevation map
  gis:apply-raster gis:load-dataset cover_path land_cover ;; Load cover map

  ; Visualization settings (optional)
;  let min-elevation gis:minimum-of area
;  let max-elevation gis:maximum-of area
;  ask patches [
;    set pcolor scale-color green elevation min-elevation max-elevation
;    set plabel elevation
;  ]
end

;; FUNCTION 13: Reading of parameters (values of each externaly defined variable). Note that this must be done in the order in which parameters are written in "parameteros.txt"
to read_parameters [filename]
  file-open filename

;  set start_date file-read
;  show "start_date"
;  show start_date

  set end_date file-read
;  show "end_date"
;  show end_date

  set elevation_path file-read
;  show "elevation_path"
;  show elevation_path

  set pines_path file-read
;  show "pines_path"
;  show pines_path

  set cover_path file-read
;  show "cover_path"
;  show cover_path

  set wimmed_path file-read
;  show "wimmed_path"
;  show wimmed_path

  set patch_size file-read
;  show "patch_size"
;  show patch_size

  set max_infectation file-read
;  show "max_infectation"
;  show max_infectation

  set carrying_cap_coef_b0 file-read
;  show "carrying_cap_coef_b0"
;  show carrying_cap_coef_b0

  set carrying_cap_coef_b1 file-read
;  show "carrying_cap_coef_b1"
;  show carrying_cap_coef_b1

  set NPP_rate file-read
;  show "NPP_rate"
;  show NPP_rate

  set quality_threshold file-read
;  show "quality_threshold"
;  show quality_threshold

  set mean_clutch file-read
;  show "mean_clutch"
;  show mean_clutch

  set sd_clutch file-read
;  show "sd_clutch"
;  show sd_clutch

  set egg_parasitism_coef_b0 file-read
;  show "egg_parasitism_coef_b0"
;  show egg_parasitism_coef_b0

  set egg_parasitism_coef_b1 file-read
;  show "egg_parasitism_coef_b1"
;  show egg_parasitism_coef_b1

  set L1_mort_quality file-read
;  show "L1_mort_quality"
;  show L1_mort_quality

  set L2_mort_rate file-read
;  show "L2_mort_rate"
;  show L2_mort_rate

  set L2_mort_quantity_threshold file-read
;  show "L2_mort_quantity_threshold"
;  show L2_mort_quantity_threshold

  set lethal_tmin file-read
;  show "lethal_tmin"
;  show lethal_tmin

  set lethal_tmax file-read
;  show "lethal_tmax"
;  show lethal_tmax

  set min_days_as_egg file-read
;  show "min_days_as_egg"
;  show min_days_as_egg

  set min_days_as_L1 file-read
;  show "min_days_as_L1"
;  show min_days_as_L1

  set min_days_as_L2 file-read
;  show "min_days_as_L2"
;  show min_days_as_L2

  set max_days_as_nymph file-read
;  show "max_days_as_nymph"
;  show max_days_as_nymph

;  set dev_t_eggs file-read
;  show "dev_t_eggs"
;  show dev_t_eggs

;  set high_thr_t_larvae file-read
;  show "high_thr_t_larvae"
;  show high_thr_t_larvae

;  set dev_ti_larvae file-read
;  show "dev_ti_larvae"
;  show dev_ti_larvae

;  set low_thr_t_larvae file-read
;  show "low_thr_t_larvae"
;  show low_thr_t_larvae

  set max_procession_dist file-read
;  show "max_procession_dist"
;  show max_procession_dist

  set emergence_success_coef_b0 file-read
;  show "emergence_success_coef_b0"
;  show emergence_success_coef_b0

  set emergence_success_coef_b1 file-read
;  show "emergence_success_coef_b1"
;  show emergence_success_coef_b1

  set max_mating_distance file-read
;  show "max_mating_distance"
;  show max_mating_distance

  set max_flight_distance file-read
;  show "max_flight_distance"
;  show max_flight_distance

  file-close-all
end

;; FUNCTION 14: Allows reading of landscape variables for today
to read_landscape
  let path_asc word wimmed_path time:show today "yyyy-MM-dd" ;; Temporal variables to generate the name of the .asc files
  ; snev and sbaza world
   ;gis:apply-raster gis:load-dataset (word path_asc "_T_m.asc") tmean ;; Landscape variables are updated for each patch "from raster to patch variables"
;   gis:apply-raster gis:load-dataset (word path_asc "_Tmx.asc") tmax
;   gis:apply-raster gis:load-dataset (word path_asc "_Tmn.asc") tmin
   ;gis:apply-raster gis:load-dataset (word path_asc "_Rdr.asc") radiation
   ;gis:apply-raster gis:load-dataset (word path_asc "_Pre.asc") precipitation
   ;gis:apply-raster gis:load-dataset (word path_asc "_HSol1.asc") soil_moisture

  ; medium world
;  gis:apply-raster gis:load-dataset (word path_asc "_Tmx_30x30.txt.asc") tmax
;  gis:apply-raster gis:load-dataset (word path_asc "_Tmn_30x30.txt.asc") tmin

  ; PLUS10
  gis:apply-raster gis:load-dataset (word path_asc "_Tmx_30x30_CASOMAS10.asc") tmax
  gis:apply-raster gis:load-dataset (word path_asc "_Tmn_30x30_CASOMAS10.asc") tmin

;  ; MINUS10
;  gis:apply-raster gis:load-dataset (word path_asc "_Tmx_30x30_CASOMENOS10.asc") tmax
;  gis:apply-raster gis:load-dataset (word path_asc "_Tmn_30x30_CASOMENOS10.asc") tmin

end

;; FUNCTION 15
to save_monthly_landscape
  ;; month_st_* are defined and monthly means are saved in month_table
  ifelse (time:get "day" today) = 1
    [
    ;; Each first day of the month the monthly mean of previous month is calculated and saved in month_table
;    set month_st_egg month_st_egg / counter
;    set month_st_L1 month_st_L1 / counter
;    set month_st_L2 month_st_L2 / counter
;    set month_st_nymph month_st_nymph / counter
;    set month_st_moth month_st_moth / counter
;    set month_st_hosts_quantity month_st_hosts_quantity / counter
;    set month_st_infected month_st_infected / counter
    set month_table lput (list counter (time:show yesterday "yyyy-MM-dd") month_st_egg month_st_L1 month_st_L2 month_st_nymph month_st_moth month_st_hosts_quantity month_st_infected) month_table

    ;; Monthly mean per patch are also calculated
    ask patches [
;      set asc_eggs asc_eggs / counter
;      set asc_L1 asc_L1 / counter
;      set asc_L2 asc_L2 / counter
;      set asc_nymphs asc_nymphs / counter
;      set asc_moths asc_moths / counter
;      set asc_hosts_quantity asc_hosts_quantity / counter
;      set asc_infected asc_infected / counter
      ]

    ; And map is created (out of "ask patches..." because it is observer-context only)
;    gis:store-dataset gis:patch-dataset asc_eggs (word "../outputs/" execution_name time:show yesterday "_yyyy-MM-dd" "_eggs.asc")
;    gis:store-dataset gis:patch-dataset asc_L1 (word "../outputs/" execution_name time:show yesterday "_yyyy-MM-dd" "_L1.asc")
;    gis:store-dataset gis:patch-dataset asc_L2 (word "../outputs/" execution_name time:show yesterday "_yyyy-MM-dd" "_L2.asc")
;    gis:store-dataset gis:patch-dataset asc_nymphs (word "../outputs/" execution_name time:show yesterday "_yyyy-MM-dd" "_nymphs.asc")
;    gis:store-dataset gis:patch-dataset asc_moths (word "../outputs/" execution_name time:show yesterday "_yyyy-MM-dd" "_moths.asc")
;    gis:store-dataset gis:patch-dataset asc_hosts_quantity (word "../outputs/" execution_name time:show yesterday "_yyyy-MM-dd" "_hosts_quantity.asc")
;    gis:store-dataset gis:patch-dataset asc_infected (word "../outputs/" execution_name time:show yesterday "_yyyy-MM-dd" "_infected.asc")

    ; Once monthly means have been saved, counter, month_st_* and asc_* are reset
    set counter 1
;    set month_st_egg stat_egg
;    set month_st_L1 stat_L1
;    set month_st_L2 stat_L2
;    set month_st_nymph stat_nymph
;    set month_st_moth stat_moth
;    set month_st_hosts_quantity stat_hosts_quantity
;    set month_st_infected stat_infected
    ask patches [
;      set asc_eggs sum [number_individuals] of colonies-here with [instar = "egg"]
;      set asc_L1 sum [number_individuals] of colonies-here with [instar = "L1"]
;      set asc_L2 sum [number_individuals] of colonies-here with [instar = "L2"]
;      set asc_nymphs sum [number_individuals] of nymphs-here
;      set asc_moths sum [number_individuals] of moths-here
;      ifelse count hosts-here > 0
;        [
;          set asc_hosts_quantity mean [quantity] of hosts-here
;          let infected count hosts-here with [count link-neighbors with [breed = colonies] > 0]
;          let total count hosts-here
;          set asc_infected infected * 100 / total
;        ]
;        [ set asc_hosts_quantity -9999
;          set asc_infected -9999
;        ]
      ]
    ]

    [ ;; Every other day of the month counter, month_st_* and asc_* are additive, in order to calculate the total sum of the month
    set counter counter + 1
;    set month_st_egg month_st_egg + stat_egg
;    set month_st_L1 month_st_L1 + stat_L1
;    set month_st_L2 month_st_L2 + stat_L2
;    set month_st_nymph month_st_nymph + stat_nymph
;    set month_st_moth month_st_moth + stat_moth
;    set month_st_hosts_quantity month_st_hosts_quantity + stat_hosts_quantity
;    set month_st_infected month_st_infected + stat_infected
    ask patches [
;      set asc_eggs asc_eggs + sum [number_individuals] of colonies-here with [instar = "egg"]
;      set asc_L1 asc_L1 + sum [number_individuals] of colonies-here with [instar = "L1"]
;      set asc_L2 asc_L2 + sum [number_individuals] of colonies-here with [instar = "L2"]
;      set asc_nymphs asc_nymphs + sum [number_individuals] of nymphs-here
;      set asc_moths asc_moths + sum [number_individuals] of moths-here
;      ifelse count hosts-here > 0
;        [
;          set asc_hosts_quantity asc_hosts_quantity + mean [quantity] of hosts-here
;          let infected count hosts-here with [count link-neighbors with [breed = colonies] > 0]
;          let total count hosts-here
;          set asc_infected asc_infected + (infected * 100 / total)
;        ]
;        [
;          set asc_hosts_quantity -9999
;          set asc_infected -9999
;        ]
      ]
    ]
end

;; FUNCTION 16: saves results in different files
to write_results
  print "writing results"
   let directory  word "../outputs/" execution_name
   csv:to-file (word directory "_day_table.txt") day_table ;; saves day_table
  ;csv:to-file (word directory "_month_table.txt") month_table ;; saves month_table
   ;csv:to-file (word directory "_table_bags.txt") table_bags ;; saves table_bags
   ;csv:to-file (word directory "_table_nymphs.txt") table_nymphs ;; saves table_nymphs
end

;; FUNCTION 17: writes simulation report
to write_report
  let directory  word "../outputs/" execution_name
  let path word directory "_report.txt"
  show path
  file-open path

  file-type "execution_name: "
  file-print execution_name

  file-type "start_date: "
  file-print start_date

  file-type "end_date: "
  file-print end_date

  file-type "elevation_path: "
  file-print elevation_path

  file-type "pines_path: "
  file-print pines_path

  file-type "cover_path: "
  file-print cover_path

  file-type "wimmed_path: "
  file-print wimmed_path

  file-type "patch_size: "
  file-print patch_size

  file-type "max_infectation: "
  file-print max_infectation

  file-type "carrying_cap_coef_b0: "
  file-print carrying_cap_coef_b0

  file-type "carrying_cap_coef_b1: "
  file-print carrying_cap_coef_b1

  file-type "NPP_rate: "
  file-print NPP_rate

  file-type "quality_threshold: "
  file-print quality_threshold

  file-type "mean_quantity: "
  file-print mean_quantity

  file-type "sd_quantity: "
  file-print sd_quantity

  file-type "mean_clutch: "
  file-print mean_clutch

  file-type "sd_clutch: "
  file-print sd_clutch

  file-type "egg_parasitism_coef_b0: "
  file-print egg_parasitism_coef_b0

  file-type "egg_parasitism_coef_b1: "
  file-print egg_parasitism_coef_b1

  file-type "L1_mort_quality: "
  file-print L1_mort_quality

  file-type "L2_mort_rate: "
  file-print L2_mort_rate

  file-type "L2_mort_quantity_threshold: "
  file-print L2_mort_quantity_threshold

  file-type "lethal_tmin: "
  file-print lethal_tmin

  file-type "lethal_tmax: "
  file-print lethal_tmax

  file-type "min_days_as_egg: "
  file-print min_days_as_egg

  file-type "min_days_as_L1: "
  file-print min_days_as_L1

  file-type "min_days_as_L2: "
  file-print min_days_as_L2

  file-type "max_days_as_nymph: "
  file-print max_days_as_nymph

  file-type "dev_t_eggs: "
  file-print dev_t_eggs

  file-type "high_thr_t_larvae: "
  file-print high_thr_t_larvae

  file-type "dev_ti_larvae: "
  file-print dev_ti_larvae

  file-type "low_thr_t_larvae: "
  file-print low_thr_t_larvae

  file-type "max_procession_dist: "
  file-print max_procession_dist

  file-type "emergence_success_coef_b0: "
  file-print emergence_success_coef_b0

  file-type "emergence_success_coef_b1: "
  file-print emergence_success_coef_b1

  file-type "max_mating_distance: "
  file-print max_mating_distance

  file-type "max_flight_distance: "
  file-print max_flight_distance

  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
9
80
769
711
-1
-1
50.0
1
10
1
1
1
0
1
1
1
0
14
-11
0
0
0
1
Days
30.0

BUTTON
182
30
258
63
Initialize
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
264
30
340
63
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
15
20
105
65
Date
time:show today \"yyyy-MM-dd\"
0
1
11

BUTTON
1088
110
1164
143
Go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
778
329
1136
514
Pest development
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Eggs" 1.0 0 -12895429 true "" "plot stat_egg"
"Larvae 1" 1.0 0 -8053223 true "" "plot stat_l1"
"Larvae 2" 1.0 0 -13403783 true "" "plot stat_l2"
"Nymphs" 1.0 0 -865067 true "" "plot stat_nymph"
"Moths" 1.0 0 -2674135 true "" "plot stat_moth"

BUTTON
1076
62
1173
95
CSV
write_results\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
778
526
1136
711
Hosts development
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Quantity" 1.0 0 -612749 true "" "plot stat_hosts_quantity"
"% Infected" 1.0 0 -13840069 true "" "plot stat_infected"

MONITOR
1316
56
1401
109
counter
counter
17
1
13

MONITOR
1198
55
1306
108
month_st_egg
month_st_egg
2
1
13

MONITOR
1198
108
1306
161
month_st_l1
month_st_l1
2
1
13

MONITOR
1198
161
1306
214
month_st_l2
month_st_l2
2
1
13

MONITOR
1198
213
1306
266
month_st_nymph
month_st_nymph
0
1
13

MONITOR
1198
267
1306
320
month_st_moth
month_st_moth
17
1
13

MONITOR
1198
320
1306
373
month_st_host
month_st_hosts_quantity
2
1
13

MONITOR
1198
373
1306
426
month_st_infec
month_st_infected
2
1
13

MONITOR
1408
56
1498
109
today
time:show today \"yyyy-MM-dd\"
17
1
13

TEXTBOX
1376
15
1526
40
CONTROLS
20
0.0
1

SLIDER
779
233
951
266
mean_quantity
mean_quantity
0
100
25
5
1
NIL
HORIZONTAL

SLIDER
965
233
1137
266
sd_quantity
sd_quantity
0
20
20
2
1
NIL
HORIZONTAL

BUTTON
376
30
463
63
NIL
optimize
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1171
571
1343
604
dev_t_eggs
dev_t_eggs
0
40
20
1
1
NIL
HORIZONTAL

SLIDER
1171
606
1343
639
high_thr_t_larvae
high_thr_t_larvae
20
30
22
1
1
NIL
HORIZONTAL

SLIDER
1171
642
1343
675
dev_ti_larvae
dev_ti_larvae
15
25
20
1
1
NIL
HORIZONTAL

SLIDER
1171
677
1343
710
low_thr_t_larvae
low_thr_t_larvae
-15
-5
-10
1
1
NIL
HORIZONTAL

TEXTBOX
1173
485
1323
527
Calibrating Development
17
0.0
0

SLIDER
1171
536
1343
569
calibration_year
calibration_year
2001
2013
2001
1
1
NIL
HORIZONTAL

BUTTON
487
28
575
61
NIL
calibrate
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1376
537
1554
570
lethal_tmin_testing
lethal_tmin_testing
-20
0
-12
1
1
NIL
HORIZONTAL

SLIDER
1376
571
1554
604
lethal_tmax_testing
lethal_tmax_testing
25
45
32
1
1
NIL
HORIZONTAL

CHOOSER
1385
631
1477
676
replicate
replicate
1 2 3
0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="StressTest-prueba1" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>stat_L1</metric>
    <metric>stat_L2</metric>
    <metric>stat_hosts_quantity</metric>
    <enumeratedValueSet variable="mean_quantity">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="L1_mort_quality">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="calib_egg" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean hatch_dates</metric>
    <metric>min hatch_dates</metric>
    <metric>max hatch_dates</metric>
    <metric>hatch_dates</metric>
    <metric>execution_name</metric>
    <steppedValueSet variable="dev_t_eggs" first="15" step="1" last="25"/>
    <steppedValueSet variable="year" first="2001" step="1" last="2013"/>
  </experiment>
  <experiment name="calib_larvae" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>calibrate</go>
    <metric>procession_crit</metric>
    <metric>mean procession_dates</metric>
    <metric>min procession_dates</metric>
    <metric>max procession_dates</metric>
    <metric>procession_dates</metric>
    <steppedValueSet variable="high_thr_t_larvae" first="20" step="1" last="30"/>
    <steppedValueSet variable="dev_ti_larvae" first="15" step="1" last="25"/>
    <steppedValueSet variable="low_thr_t_larvae" first="-15" step="1" last="-5"/>
    <steppedValueSet variable="year" first="2001" step="1" last="2013"/>
  </experiment>
  <experiment name="calib_larvae_new_crit" repetitions="2" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>calibrate</go>
    <metric>procession_crit</metric>
    <metric>mean procession_dates</metric>
    <metric>min procession_dates</metric>
    <metric>max procession_dates</metric>
    <metric>procession_dates</metric>
    <metric>lay_crit</metric>
    <metric>mean lay_dates</metric>
    <metric>min lay_dates</metric>
    <metric>max lay_dates</metric>
    <metric>lay_dates</metric>
    <steppedValueSet variable="high_thr_t_larvae" first="20" step="1" last="30"/>
    <steppedValueSet variable="dev_ti_larvae" first="15" step="1" last="25"/>
  </experiment>
  <experiment name="StressTest_max_procession_dist" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count nymphs</metric>
    <metric>execution_name</metric>
    <enumeratedValueSet variable="max_procession_dist">
      <value value="1.23"/>
      <value value="6.15"/>
      <value value="12.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_Climate_Scenarios" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>execution_name</metric>
    <enumeratedValueSet variable="calibration_year">
      <value value="2001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replicate">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
