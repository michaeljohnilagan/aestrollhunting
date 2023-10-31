# function: train
comp599train  () {
	echo "!parlai train_model --max-train-steps 400 -t fromfile:parlaiformat --fromfile-datapath $1$2/$3$4data --fromfile-datatype-extension true --model transformer/classifier --init-model zoo:pretrained_transformers/bi_model_huge_reddit/model --dict-file zoo:pretrained_transformers/bi_model_huge_reddit/model.dict --dict-tokenizer bpe --dict-lower True --output-scaling 0.06 --variant xlm --n-layers 12 --n-heads 12 --learn-positional-embeddings True --ffn-size 3072 --n-positions 1024 --embedding-size 768 --activation gelu  --embeddings-scale False --n-segments 2 --dict-endtoken __start__  --classes __notok__ __ok__ --reduction-type mean --learn-embeddings True --share-word-embeddings False --load-from-pretrained-ranker True --optimizer adamax --max-train-time -1 --share-encoders False -lr 5e-05 --history-size 20 --label-truncate 72 --text-truncate 360 --dropout 0.1 --attention-dropout 0.1 --gradient-clip 0.1 --validation-metric accuracy --validation-metric-mode max --validation-patience 30 --validation-every-n-secs 20 --log-every-n-secs 10 -ttim 7200 --load-from-checkpoint true --lr_scheduler reduceonplateau --lr-scheduler-patience 3 --save-after-valid true --update-freq 1 --fp16 true --betas 0.9,0.999 --warmup-updates 1000 --data-parallel true -bs 20 --model-file /kaggle/temp/model"
} # max train steps capped at 400

# function: eval
comp599eval () {
	echo "!parlai eval_model -t fromfile:parlaiformat --fromfile-datapath $1$2/$3$4data_test.txt -m transformer/classifier -mf /kaggle/temp/model --print-scores true --world-logs /kaggle/working/$2/$3$4log"
}

# function: work
comp599work () {
	# go to input folder
	o=$(pwd)
	cd $1$2
	# loop over all its subfolders
	for x in $(echo */)
	do
		cd $x
		for y in $(echo */)
		do
			# train part
			echo "# ========== train: $1$2/$x$y =========="
			comp599train $1 $2 $x $y
			# eval part
			echo "# ========== eval: $1$2/$x$y =========="
			comp599eval $1 $2 $x $y
			# remove files
			echo "!rm -vf /kaggle/temp/model*"
			echo
		done
		cd ..
	done
	cd $o
}

comp599work /kaggle/input/beyondcomp599/ lca
comp599work /kaggle/input/beyondcomp599/ mv
