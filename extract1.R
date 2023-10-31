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

# function to extract metrics from JSONL
extract_jsonl_metrics = function(file) {
	# convert each line to data
	lines = readLines(file)
	lines = lapply(lines,unlist)
	lines = lapply(lines,rjson::fromJSON)
	# extract labels
	predicted_labels = sapply(lines,function(o) {
		o$dialog[[1]][[2]]$text
	})
	true_labels = sapply(lines,function(o) {
		o$dialog[[1]][[1]]$eval_labels
	})
	# compute metrics
	metrics = compute_metrics(gold=true_labels,
	pred=predicted_labels)
	return(metrics[c("accuracy","weighted_f1")])
}

# write results to file
sink("exper1result.csv") # open output file
cat(paste("unsafe_prevalence","troll_prevalence","corrupt_action",
"troll_corrupt_rate","method","run","accuracy","weighted_f1",sep=",")) # CSV header
cat("\n") # end CSV header
for(i in list.files()) for(j in list.files(i)) {
	for(k in list.files(paste(i,j,sep="/"))) {
		# get path to file
		path = paste(i,j,k,"log.jsonl",sep="/")
		# extract info from path
		i_write = i # method
		j_write = strsplit(j,"-")[[1]] # other factors
		j_write[c(1:2,4)] = as.numeric(j_write[c(1:2,4)])/100
		j_write = paste(j_write,collapse=",")
		k_write = gsub("run","",k) # run
		metrics = extract_jsonl_metrics(path) # accuracy and F1
		# write into file
		cat(paste(j_write,i_write,k_write,metrics[["accuracy"]],
		metrics[["weighted_f1"]],sep=","))
		cat("\n")
	}
} # loop over every input file
sink() # close output file
