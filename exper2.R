# source
source("funs.R")
source("simcommon.R")

# number of runs
num_runs = 500

# work
result = array(list(),c(sapply(sim_factors,length),
length(sim_methods))) # initialize array
result_tab = NULL # initialize dataframe
for(i1 in 1:length(sim_factors$unsafe_prevalence))
for(i2 in 1:length(sim_factors$troll_prevalence))
for(i3 in 1:length(sim_factors$corrupt_action))
for(i4 in 1:length(sim_factors$troll_corrupt_rate))
for(i5 in 1:length(sim_methods)) {
	# report
	message(Sys.time())
	unsafe_prevalence = sim_factors$unsafe_prevalence[[i1]]
	print(unsafe_prevalence)
	troll_prevalence = sim_factors$troll_prevalence[[i2]]
	print(troll_prevalence)
	corrupt_action = sim_factors$corrupt_action[[i3]]
	print(corrupt_action)
	troll_corrupt_rate = sim_factors$troll_corrupt_rate[[i4]]
	print(troll_corrupt_rate)
	method = sim_methods[[i5]]
	print(method)
	# work
	result[[i1,i2,i3,i4,i5]] = run_sim_scen(2311+1:num_runs,
	unsafe_prevalence,troll_prevalence,corrupt_action,troll_corrupt_rate,
	method)
}; Sys.time() # fill array
result_tab = do.call(rbind,result)

# create CSV file for results, runs separate
write.csv(result_tab,"exper2_result.csv",row.names=FALSE)

# save and end session
save.image("exper2.RData")
devtools::session_info()
