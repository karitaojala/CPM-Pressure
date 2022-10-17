rm(list=ls())

library(dplyr)
library(tidyverse)
library(ggplot2)
library(car)
library(lme4)
library(lmerTest)
library(multcomp)
library(emmeans)
library(nlme)
library(r2mlm)

data <- read.csv("C:/Data/CPM-Pressure/scripts/Analysis/behav/CPM_rated_reported.csv")
options(contrasts = c("contr.sum","contr.poly"))

data$Subject <- factor(data$Subject)
#data$Block <- factor(data$Block)
data$VerbalCPM <- factor(data$VerbalCPM)

cpm_nlme <- lme(RatedCPM ~ VerbalCPM, random = ~ 1|Subject, data = data, na.action=na.omit, 
             control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")
cpm_lm <- lm(RatedCPM ~ VerbalCPM, data = data)
anova(cpm_lm)
car::Anova(cpm_nlme, type = "III")
anova_trad <- aov(RatedCPM ~ VerbalCPM, data = data)
summary(anova_trad)
