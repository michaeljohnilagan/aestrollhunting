# Learning to love diligent trolls: Accounting for rater effects in the dialogue safety task

This repository contains computer code for the article with an __accept-Findings__ decision at __EMNLP 2023__:  
[https://arxiv.org/abs/2310.19271](https://arxiv.org/abs/2310.19271)

## Abstract

<blockquote>
Chatbots have the risk of generating offensive utterances, which must be avoided. 
Post-deployment, one way for a chatbot to continuously improve is to source utterance/label pairs from feedback by live users. 
However, among users are trolls, who provide training examples with incorrect labels. 
To de-troll training data, previous work removed training examples that have high user-aggregated cross-validation (CV) error. 
However, CV is expensive; and in a coordinated attack, CV may be overwhelmed by trolls in number and in consistency among themselves.
In the present work, I address both limitations by proposing a solution inspired by methodology in automated essay scoring (AES): have multiple users rate each utterance, then perform latent class analysis (LCA) to infer correct labels. 
As it does not require GPU computations, LCA is inexpensive. 
In experiments, I found that the AES-like solution can infer training labels with high accuracy when trolls are consistent, even when trolls are the majority.
</blockquote>

## Data and software

The utterance/label pairs used in the Experiments are from Meta AI's single-turn safety dataset.  
[https://dl.fbaipublicfiles.com/parlai/dialogue_safety/single_turn_safety.json](https://dl.fbaipublicfiles.com/parlai/dialogue_safety/single_turn_safety.json)

For the work done in R, version used was 4.2.2 Patched (2022-11-10 r83330) on Xubuntu 18.04.2, using the R package `mirt` version 1.39.
The rest of the work was done in Kaggle notebooks with Python 3.10 module `parlai` version 1.7.2 installed.

## Instructions

To reproduce the results in the paper, do as follows, assuming the JSON data file is in your working directory.

### Experiment 1

1. Run the R script `exper1.R`.
Doing so creates the directories and files needed for the next step.
May require installation of R packages `rjson`, `mirt`, and `devtools`.
2. Run the Bash script `script.sh`.
Doing so outputs Bash code for ParlAI.
Note that the paths therein assume running in a Kaggle notebook, so change them accordingly.
3. Run the ParlAI code.
Doing so creates JSONL files in the directories created in the first step.
4. Run the R script `extract1.R`.
Doing so creates a CSV file that stores the results of Experiment 1.
5. Run the R script `figs1.R`.
Doing so produces the relevant Figures.
May require installation of R package `ggplot2`.

The Kaggle notebooks ran into memory issues.
To ensure everything would run to completion, I split up the work into 8 notebooks. 

### Experiment 2

1. Run the R script `exper2.R`.
Doing so creates a CSV file that stores the results of Experiment 2.
2. Run the R script `figs2.R`.
Doing so produces the relevant Figures.
