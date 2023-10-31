# load table, long format
dat_o = read.csv("./exper2_result.csv")

# wide format
dat = with(new.env(),{
	# separate LCA and MV halves
	lca = subset(dat_o,method=="lca")
	names(lca) = replace(names(lca),names(lca)%in%c("accuracy","weighted_f1"),
	c("train_accuracy_lca","train_f1_lca"))
	mv = subset(dat_o,method=="mv")
	names(mv) = replace(names(mv),names(mv)%in%c("accuracy","weighted_f1"),
	c("train_accuracy_mv","train_f1_mv"))
	# put together
	cbind(lca,with(mv,data.frame(train_accuracy_mv,train_f1_mv)))
})

# replace undefined with 0
dat$train_f1_lca = (function(x) {ifelse(is.na(x),0,x)})(dat$train_f1_lca)
dat$train_f1_mv = (function(x) {ifelse(is.na(x),0,x)})(dat$train_f1_mv)

# make descriptive labels for plot
dat$unsafe_prevalence = paste("unsafe prevalence: ",
100*dat$unsafe_prevalence,"%",sep="")
dat$troll_prevalence = paste("troll prevalence: ",
100*dat$troll_prevalence,"%",sep="")
dat$corrupt_action = paste("corrupt action: ",dat$corrupt_action,sep="")
dat$troll_corrupt_rate = paste("troll corrupt rate: ",
100*dat$troll_corrupt_rate,"%",sep="")

# scatterplot with guide lines
ggplot2::ggplot(dat,ggplot2::aes(x=train_accuracy_mv,y=train_accuracy_lca))+
ggplot2::geom_point(alpha=0.1)+
ggplot2::geom_abline(slope=1,intercept=0)+
ggplot2::geom_hline(yintercept=0.9,lty=3)+
ggplot2::geom_vline(xintercept=0.9,lty=3)+
ggplot2::facet_wrap(~unsafe_prevalence+troll_prevalence+corrupt_action+
troll_corrupt_rate,nrow=4)+
ggplot2::xlab("imputation accuracy, MV")+
ggplot2::ylab("imputation accuracy, LCA+SM")

# scatterplot with guide lines, for unsafe prevalence 10
dat_unsafe10 = subset(dat,unsafe_prevalence=="unsafe prevalence: 10%")
ggplot2::ggplot(dat_unsafe10,
ggplot2::aes(x=train_accuracy_mv,y=train_accuracy_lca))+
ggplot2::geom_point(alpha=0.1)+
ggplot2::geom_abline(slope=1,intercept=0)+
ggplot2::geom_hline(yintercept=0.9,lty=3)+
ggplot2::geom_vline(xintercept=0.9,lty=3)+
ggplot2::facet_wrap(~troll_prevalence+corrupt_action+
troll_corrupt_rate,nrow=2)+
ggplot2::xlab("imputation accuracy, MV")+
ggplot2::ylab("imputation accuracy, LCA+SM")+
ggplot2::ggtitle("Unsafe prevalence: 10%")

# scatterplot with guide lines, for unsafe prevalence 30
dat_unsafe30 = subset(dat,unsafe_prevalence=="unsafe prevalence: 30%")
ggplot2::ggplot(dat_unsafe30,
ggplot2::aes(x=train_accuracy_mv,y=train_accuracy_lca))+
ggplot2::geom_point(alpha=0.1)+
ggplot2::geom_abline(slope=1,intercept=0)+
ggplot2::geom_hline(yintercept=0.7,lty=3)+
ggplot2::geom_vline(xintercept=0.7,lty=3)+
ggplot2::facet_wrap(~troll_prevalence+corrupt_action+
troll_corrupt_rate,nrow=2)+
ggplot2::xlab("imputation accuracy, MV")+
ggplot2::ylab("imputation accuracy, LCA+SM")+
ggplot2::ggtitle("Unsafe prevalence: 30%")
