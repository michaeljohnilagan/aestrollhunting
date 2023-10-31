# function: load from JSON
load_from_json = function(file) {
	# load data
	json_data = rjson::fromJSON(file=file)
	# combinations
	sources = c("standard","adversarial")
	folds = c("train","valid","test")
	labels = c("safe","unsafe")
	rounds = "1" # hard coded using only round 1
	combos = expand.grid(source=sources,fold=folds,label=labels,
	round=rounds)
	# loop over each combo to make dataframe
	list_of_dfs = lapply(1:nrow(combos),function(i) {
		# coordinates
		source = combos$source[i]
		fold = combos$fold[i]
		label = combos$label[i]
		round = combos$round[i]
		# construct dataframe
		df_data = json_data[[source]][[fold]][[round]][[label]]
		df_data = lapply(df_data,function(o) {
			data.frame(text=o$text,labels=o$labels,
			episode_done=o$episode_done)
		})
		df = do.call(rbind,df_data)
		# append combo information
		df$source = source
		df$fold = fold
		df$round = round
		df
	})
	return(do.call(rbind,list_of_dfs)) # put together
}

# function: take sample from dataframe
sample_from_df = function(x,n,unsafe_prevalence=NULL) {
	# always sample with replacement, hard coded
	replace = TRUE
	# stratify by label if proportion specified
	if(is.null(unsafe_prevalence)) {
		sampled = sample(1:nrow(x),size=n,replace=replace)
	} else {
		# group IDs by label
		ids_unsafe = which(x$labels=="__notok__")
		ids_safe = which(x$labels=="__ok__")
		# determine how many to sample per class
		size_unsafe = floor(n*unsafe_prevalence)
		size_safe = n-size_unsafe
		# do stratified sampling
		sampled_bad = sample(ids_unsafe,size=size_unsafe,
		replace=replace)
		sampled_good = sample(ids_safe,size=size_safe,replace=replace)
		sampled = c(sampled_bad,sampled_good)
	}
	return(x[sampled,])
}

# function: convert dataframe to parlai format text
convert_to_parlai_text = function(x,file) {
	# open sink
	sink(file)
	# write per row
	sapply(1:nrow(x),function(i) {
		# get fields
		text = x$text[i]
		labels = x$labels[i]
		episode_done = ifelse(x$episode_done[i],"True","False")
		# put together and write
		line_to_write = paste("text:",text,"\t","labels:",labels,
		"\t","episode_done:",episode_done,sep="")
		cat(line_to_write)
		cat("\n")
	})
	# close sink
	sink()
	return(invisible(NULL))
}

# function: corrupt labels
corrupt_labels = function(x,corrupt_rate,corrupt_action) {
	# fully corrupt vectors
	x_flipped = 1-x
	x_lazy = rbinom(length(x),size=1,prob=0.5)
	# which to corrupt
	corrupted = rbinom(length(x),size=1,prob=corrupt_rate)
	# apply corruption
	if(corrupt_action=="deliberate") {
		x_corrupt = ifelse(corrupted==1,x_flipped,x)
	} else if(corrupt_action=="lazy") {
		x_corrupt = ifelse(corrupted==1,x_lazy,x)
	} else {
		stop("corrupt type not recognized")
	}
	return(x_corrupt)
}

# function: get ratings
get_ratings = function(x,num_users_all,num_users_per_utter,troll_prevalence,
helper_corrupt_rate,troll_corrupt_rate,corrupt_action) {
	# get gold labels
	gold_labels = ifelse(x$labels=="__ok__",0,1)
	# create synthetic users
	num_trolls = floor(num_users_all*troll_prevalence)
	num_helpers = num_users_all-num_trolls
	user_type = c(rep("helper",times=num_helpers),
	rep("troll",times=num_trolls))
	# perform corruption of labels
	corrupt_rate = ifelse(user_type=="troll",troll_corrupt_rate,
	helper_corrupt_rate)
	matrix_of_labels = sapply(corrupt_rate,function(r) {
		corrupt_labels(gold_labels,corrupt_rate=r,
		corrupt_action=corrupt_action)
	}) # complete matrix of labels
	# generate missingness mask
	num_missing = num_users_all-num_users_per_utter
	missing_mask = t(replicate(nrow(x),{
		to_be_shuffled = c(rep(FALSE,num_users_per_utter),
		rep(TRUE,num_missing))
		sample(to_be_shuffled)
	}))
	# apply missingness to matrix of labels
	matrix_of_labels = replace(matrix_of_labels,missing_mask,NA)
	return(matrix_of_labels)
}

# function: determine classes with latent class analysis
aes_like = function(x) {
	# remove useless users
	users_to_keep = apply(x,2,function(v) {
		how_many_unique = unique(v[!is.na(v)])
		length(how_many_unique)>1
	}) # each column must have both classes
	# model fitting
	fit = mirt::mdirt(as.data.frame(x[,users_to_keep]),2,verbose=FALSE)
	# get cluster probabilities
	predicted_prob = mirt::fscores(fit,method="EAP")[,1]
	predicted_bin = round(predicted_prob)
	# assume smaller cluster is unsafe
	if(sum(predicted_bin==1)>sum(predicted_bin==0)) {
		predicted_prob = 1-predicted_prob
		predicted_bin = 1-predicted_bin
	} # swap to make smaller class have label 1
	return(setNames(predicted_prob,predicted_bin))
}

# function: determine classes with majority vote
majority_vote = function(x) {
	prop_unsafe = rowMeans(x==1,na.rm=TRUE)
	predicted_bin = round(prop_unsafe)
	return(setNames(prop_unsafe,predicted_bin))
}

# function: imputation metrics
compute_metrics = function(gold,pred) {
	# make binary integer format
	if(!is.numeric(gold)) {
		gold_int = ifelse(gold=="__ok__",0,1)
	} else {
		gold_int = gold
	}
	if(!is.numeric(pred)) {
		pred_int = ifelse(pred=="__ok__",0,1)
	} else {
		pred_int = pred
	}
	# compute metrics
	confusion_table = table(gold=gold,pred=pred)
	accuracy = mean(gold_int==pred_int)
	recall_1 = mean(pred_int[gold_int==1]==1) # sensitivity
	precision_1 = mean(gold_int[pred_int==1]==1) # positive predictive value
	recall_0 = mean(pred_int[gold_int==0]==0)
	precision_0 = mean(gold_int[pred_int==0]==0)
	prev_1 = mean(gold_int)
	f1_1 = 2*recall_1*precision_1/(recall_1+precision_1) # F1 score class 1
	f1_0 = 2*recall_0*precision_0/(recall_0+precision_0) # F1 score class 0
	weighted_f1 = prev_1*f1_1+(1-prev_1)*f1_0
	metrics = list(confusion_table=confusion_table,accuracy=accuracy,
	f1=f1_1,precision=precision_1,recall=recall_1,
	weighted_f1=weighted_f1) # put together
	return(metrics)
}

# single replicate run
if(FALSE) {
	set.seed(2029)
	with(new.env(),{
		# constants
		helper_corrupt_rate = 0.05
		troll_corrupt_rate = 0.8
		num_users_all = 50
		# scenario
		unsafe_prevalence = 0.3
		troll_prevalence = 0.9
		corrupt_action = "deliberate"
		num_users_per_utter = 3
		# get safety data
		safety_data = load_from_json("./single_turn_safety.json")
		# sample training data
		dat = sample_from_df(safety_data,n=200,
		unsafe_prevalence=unsafe_prevalence)
		# create synthetic users and labels
		matrix_of_labels = get_ratings(dat,num_users_all=num_users_all,
		num_users_per_utter=num_users_per_utter,
		troll_prevalence=troll_prevalence,
		helper_corrupt_rate=helper_corrupt_rate,
		troll_corrupt_rate=troll_corrupt_rate,
		corrupt_action=corrupt_action)
		# make predictions with proposed
		pred_proposed = aes_like(matrix_of_labels)
		print(compute_metrics(gold=dat$labels,pred=round(pred_proposed)))
	})
}
