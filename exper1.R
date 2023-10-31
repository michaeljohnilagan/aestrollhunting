# source
source("funs.R")
source("simcommon.R")

# number of runs
num_runs = 5

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
	# create scenario folder
	scenario_id = paste(c(100*unsafe_prevalence,100*troll_prevalence,
	corrupt_action,100*troll_corrupt_rate),
	collapse="-") # put non method factors
	scenario_id = paste(method,"/",scenario_id,sep="") # add method factor
	if(!dir.exists(scenario_id)) dir.create(scenario_id,
	recursive=TRUE) # create directory
	# work
	result[[i1,i2,i3,i4,i5]] = lapply(1:num_runs,function(i) {
		# create replicate folder
		path = paste(scenario_id,"/run",i,sep="")
		dir.create(path)
		message(path)
		# current run
		set.seed(2132+i)
		current_run = run_sim_repl(unsafe_prevalence,troll_prevalence,
		corrupt_action,troll_corrupt_rate,method)
		# create files
		df = current_run$samp_train
		df$labels = ifelse(current_run$pred==0,"__ok__","__notok__")
		convert_to_parlai_text(df,file=paste(path,
		"/data_train.txt",sep="")) # train
		convert_to_parlai_text(current_run$samp_valid,file=paste(path,
		"/data_valid.txt",sep="")) # valid
		convert_to_parlai_text(current_run$samp_eval,file=paste(path,
		"/data_test.txt",sep="")) # test
		# return object
		current_run
	})
	# tabular form
	result_tab = rbind(result_tab,
	do.call(rbind,lapply(result[[i1,i2,i3,i4,i5]],function(o){
		data.frame(unsafe_prevalence=unsafe_prevalence,
		troll_prevalence=troll_prevalence,
		corrupt_action=corrupt_action,
		troll_corrupt_rate=troll_corrupt_rate,method=method,
		train_accuracy=o$metrics$accuracy,
		train_weighted_f1=o$metrics$weighted_f1)
	})))
}; Sys.time() # fill array

# save and end session
save.image("exper1.RData")
devtools::session_info()
