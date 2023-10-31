# load stuff
safety_data = load_from_json(file="./single_turn_safety.json") # full dataset

# simulation factors
sim_factors = list(unsafe_prevalence=c(0.1,0.3),
troll_prevalence=c(0.5,0.9),
corrupt_action=c("deliberate","lazy"),
troll_corrupt_rate=c(0.8,0.95))

# methods used
sim_methods = c("lca","mv") # AES-like vs majority vote baseline

# constants
sim_constants = list(num_users_all=50,num_users_per_utter=5,
helper_corrupt_rate=0.05)

# function: run single replicate
run_sim_repl = function(unsafe_prevalence,troll_prevalence,corrupt_action,
troll_corrupt_rate,method) {
	# training, valid, test
	samp_train = sample_from_df(subset(safety_data,fold=="train"),200,
	unsafe_prevalence=unsafe_prevalence) # train
	samp_valid = sample_from_df(subset(safety_data,fold=="train"),24,
	unsafe_prevalence=unsafe_prevalence) # valid
	samp_eval = subset(safety_data,fold=="valid"&source=="standard") # test
	# compute number of total users
	num_users_all = sim_constants$num_users_all
	# create matrix of labels
	matrix_of_labels = get_ratings(samp_train,
	num_users_all=num_users_all,
	num_users_per_utter=sim_constants$num_users_per_utter,
	troll_prevalence=troll_prevalence,
	helper_corrupt_rate=sim_constants$helper_corrupt_rate,
	troll_corrupt_rate=troll_corrupt_rate,
	corrupt_action=corrupt_action)
	# make predictions
	if(method=="mv") {
		pred_prob = majority_vote(matrix_of_labels)
		pred_bin = round(pred_prob)
		metrics = compute_metrics(gold=samp_train$labels,pred=pred_bin)
	} else if(method=="lca") {
		pred_prob = aes_like(matrix_of_labels)
		pred_bin = round(pred_prob)
		metrics = compute_metrics(gold=samp_train$labels,pred=pred_bin)
	} else {
		stop("method not supported")
	}
	# put together
	all_the_things = list(samp_train=samp_train,samp_valid=samp_valid,
	samp_eval=samp_eval,matrix_of_labels=matrix_of_labels,
	metrics=metrics,pred_prob=pred_prob,pred=pred_bin)
	return(all_the_things)
}

# function: run whole scenario
run_sim_scen = function(seed,unsafe_prevalence,troll_prevalence,
corrupt_action,troll_corrupt_rate,method) {
	# do runs
	num_runs = length(seed)
	runs = lapply(seed,function(s) {
		set.seed(s)
		run_sim_repl(unsafe_prevalence,
		troll_prevalence,corrupt_action,troll_corrupt_rate,method)
	})
	# extract metrics
	metrics = do.call(rbind,lapply(runs,function(o) {
		accuracy = o$metrics[["accuracy"]]
		weighted_f1 = o$metrics[["weighted_f1"]]
		data.frame(accuracy=accuracy,weighted_f1=weighted_f1)
	}))
	# make data frame of scenario parameters
	scen_id = data.frame(unsafe_prevalence=unsafe_prevalence,
	troll_prevalence=troll_prevalence,
	corrupt_action=corrupt_action,
	troll_corrupt_rate=troll_corrupt_rate)
	# put together
	return(cbind(scen_id,data.frame(method=method,run=1:num_runs),
	as.list(metrics)))
}

# function: get scenario averages
aggregate_scen = function(tab) {
	sim_factors = c(names(sim_scens))
	scen_id = tab[1,sim_factors]
	metrics = as.list(colMeans(tab[,setdiff(colnames(tab),c(sim_factors,
	"run"))]))
	method = data.frame(tab$method[1])
	return(suppressWarnings(cbind(scen_id,method,metrics)))
}
