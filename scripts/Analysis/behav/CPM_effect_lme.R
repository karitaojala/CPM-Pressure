rm(list=ls())

library(dplyr)
library(tidyverse)
library(ggplot2)
library(R.matlab)
library(car)
library(mvoutlier)
library(lme4)
library(lmerTest)
library(multcomp)
library(emmeans)
library(nlme)
library(r2mlm)
#checkpoint("2018-11-21")

data <- read.csv("C:/Data/CPM-Pressure/scripts/Analysis/behav/Experiment-01_ratings_table_long.csv")

#outlier_subs <- data$Subject[which(data$StartleAmplitude > 2)]
#data <- data[!is.element(data$Subject,outlier_subs),]

data$Subject <- factor(data$Subject)
#data$Stimulus <- factor(data$Stimulus)
#data$Trial <- factor(data$Trial)
#data$Block <- factor(data$Block)
data$Condition <- factor(data$Condition)

data$Condition <- plyr::revalue(data$Condition, c("0"="Con", "1"="Exp"))

# Standardize data by dividing all values by average CS- response
#Con_data <- data$PainRating[data$Condition=="Con"]
#Con_avg <- mean(Con_data)
#Con_std <- sd(Con_data)

#data_avg = mean(data$PainRating,na.rm = TRUE)
#data_sd = sd(data$PainRating,na.rm = TRUE)

#data_std <- data
#data_std$PainRating <- (data_std$PainRating-data_avg)/data_sd

# Estimable models
nlme_1 <- nlme::lme(PainRating ~ Condition * Block * Trial,
                        random = ~ Condition|Subject, data = data, na.action=na.omit, 
                        control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "ML")

nlme_2 <- nlme::lme(PainRating ~ Condition * Stimulus,
                         random = ~ 1|Subject, data = data, na.action=na.omit, 
                         control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "ML")

nlme_3 <- nlme::lme(PainRating ~ Condition * Stimulus,
                         random = ~ (Condition)|Subject, data = data, na.action=na.omit, 
                         control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "ML")

#bayestestR::bayesfactor_models(nlme_sebr_3, denominator = nlme_sebr_1)

anova(nlme_1)
anova(nlme_2)
anova(nlme_3)

nlme_sebr <- nlme::lme(StartleAmplitude ~ Group * Trial * CSType * CSComplexity, random = ~ 1 | Subject, data = data, method = "REML", control = lmeControl(opt = "optim"))
#na.action=na.omit, 
anova(nlme_sebr)

lme4_sebr <- lmer(StartleAmplitude ~ Group * Trial * CSType * CSComplexity + (1|Subject), REML = TRUE, data = data)
anova(lme4_sebr)

# LME
lme4_sebr <- lmer(StartleAmplitude ~ Group + Trial + CSType + CSComplexity + Group*CSType + Group*CSComplexity + Group*Trial + Trial*CSType + Trial*CSComplexity + CSType*CSComplexity + Group*Trial*CSType + Group*CSType*CSComplexity + (1|Subject), REML = TRUE, data = data)
summary(lme_sebr)
anova(lme4_sebr) # ANOVA

nlme_sebr <- lme(StartleAmplitude ~ Group + Trial + CSType + CSComplexity + Group*CSType + Group*CSComplexity + Group*Trial + Trial*CSType + Trial*CSComplexity + CSType*CSComplexity + Group*Trial*CSType + Group*CSType*CSComplexity, random = ~ 1 | Subject, data = data)
anova(nlme_sebr)
summary(nlme_sebr)
# Post-hoc contrasts EMM
# Plot
emplot <- emmip(lme_sebr, Group ~ CSType | CSComplexity, CIs = TRUE) + theme_bw() + scale_y_continuous(name = "Estimated marginal mean\n(startle amplitude)", limits = c(0,2))
emplot

# Per group, per CS complexity
emm <- emmeans(lme_sebr, ~ Group*CSType | CSComplexity)
pairs(emm, simple = "CSType")

# Averaged over CS complexity separately for groups
emmeans(lme_sebr, specs = consec ~ CSType | Group, adjust = "none")
# or alternative way:
emm3 <- emmeans(lme_sebr, ~ Group*CSType)
pairs(emm3, simple = "CSType")

# Experimental vs. control CS+/CS- averaged over CS complexity
emm2 <- emmeans(lme_sebr, trt.vs.ctrl ~ Group*CSType)
contrast(emm2[[1]], interaction = c("trt.vs.ctrl","trt.vs.ctrl"))

# Experimental vs. control CS+/CS- separately for CS complexity
emm4 <- emmeans(lme_sebr, pairwise ~ Group*CSType | CSComplexity)
contrast(emm4[[1]], interaction = c("trt.vs.ctrl","trt.vs.ctrl"))

# Traditional ANOVA both groups
data_avg <- aggregate(data[,"StartleAmplitude"], by = list(data$Subject, data$Group, data$CSComplexity, data$CSType), mean)
data_avg <- data_avg %>%
  rename(
    Subject = Group.1,
    Group = Group.2, 
    CSComplexity = Group.3,
    CSType = Group.4,
    StartleAmplitude = x 
  )


x1 <- mean(data$StartleAmplitude[data$CSComplexity=="Simple" & data$Group=="Control" & data$CSType=="CS+"],na.rm = TRUE)
x2 <- mean(data$StartleAmplitude[data$CSComplexity=="Simple" & data$Group=="Control" & data$CSType=="CS-"],na.rm = TRUE)
x3 <- mean(data$StartleAmplitude[data$CSComplexity=="Complex" & data$Group=="Control" & data$CSType=="CS+"],na.rm = TRUE)
x4 <- mean(data$StartleAmplitude[data$CSComplexity=="Complex" & data$Group=="Control" & data$CSType=="CS-"],na.rm = TRUE)
barplot(c(x1,x2,x3,x4), ylim = c(-0.5,2.5))

x1 <- mean(data$StartleAmplitude[data$CSComplexity=="Simple" & data$Group=="Experimental" & data$CSType=="CS+"],na.rm = TRUE)
x2 <- mean(data$StartleAmplitude[data$CSComplexity=="Simple" & data$Group=="Experimental" & data$CSType=="CS-"],na.rm = TRUE)
x3 <- mean(data$StartleAmplitude[data$CSComplexity=="Complex" & data$Group=="Experimental" & data$CSType=="CS+"],na.rm = TRUE)
x4 <- mean(data$StartleAmplitude[data$CSComplexity=="Complex" & data$Group=="Experimental" & data$CSType=="CS-"],na.rm = TRUE)
barplot(c(x1,x2,x3,x4), ylim = c(-0.5,2.5))

anova_sebr_avg_trad <- aov(StartleAmplitude ~ Group*CSType*CSComplexity + Error(Subject/(CSType*CSComplexity)), data = data)
summary(anova_sebr_avg_trad, type = 3)
DescTools::EtaSq(anova_sebr_avg_trad, anova = FALSE)

## Controls only LME
data_control <- data[data$Group=="Control",]
#lme_sebr_c <- lmer(StartleAmplitude ~ CSType*CSComplexity + Trial*CSType + Trial*CSComplexity + (1|Subject), REML = TRUE, data = data_control)

nlme_sebr_c <- lme(StartleAmplitude ~ CSType*CSComplexity + Trial*CSType + Trial*CSComplexity + Trial*CSType*CSComplexity, random = ~ 1 | Subject, data = data_control)
summary(nlme_sebr_c)
anova(nlme_sebr_c)

lme4_sebr_c <- lmer(StartleAmplitude ~ CSType*CSComplexity + Trial*CSType + Trial*CSComplexity + Trial*CSType*CSComplexity + (1|Subject), REML = TRUE, data = data_control)
lme_sebr_c <- lmer(StartleAmplitude ~ CSType*CSComplexity + (1|Subject), REML = TRUE, data = data_control)
summary(lme_sebr_c)
anova(lme4_sebr_c) # ANOVA


# Look at conditionwise averaged data for the control group
data_control_avg <- aggregate(data_control[,"StartleAmplitude"], by = list(data_control$Subject, data_control$CSComplexity, data_control$CSType), mean)
data_control_avg <- data_control_avg %>%
  rename(
    Subject = Group.1,
    CSComplexity = Group.2,
    CSType = Group.3,
    StartleAmplitude = x 
  )

anova_sebr_c_avg_trad <- aov(StartleAmplitude ~ CSType + CSComplexity + CSType*CSComplexity + Error(Subject/(CSType*CSComplexity)), data = data_control_avg)
summary(anova_sebr_c_avg_trad, type = 3)

ttest_simple <- t.test(StartleAmplitude[data_control_avg$CSComplexity=="Simple"] ~ CSType[data_control_avg$CSComplexity=="Simple"], data_control_avg, paired = TRUE, alternative = "less")
ttest_simple
ttest_complex <- t.test(StartleAmplitude[data_control_avg$CSComplexity=="Complex"] ~ CSType[data_control_avg$CSComplexity=="Complex"], data_control_avg, paired = TRUE, alternative = "less")
ttest_complex

aggregate(data_control[,"StartleAmplitude"], by = list(data_control$CSComplexity, data_control$CSType), mean)

# Conditionwise average for control group, over CS complexity
data_control_avg_complex <- aggregate(data_control[,"StartleAmplitude"], by = list(data_control$Subject, data_control$CSType), mean)
data_control_avg_complex <- data_control_avg_complex %>%
  rename(
    Subject = Group.1,
    CSType = Group.2,
    StartleAmplitude = x 
  )
ttest_complexavg <- t.test(StartleAmplitude ~ CSType, data_control_avg_complex, paired = TRUE, alternative = "less")

# Traditional ANOVA both groups
data_avg <- aggregate(data[,"StartleAmplitude"], by = list(data$Subject, data$Group, data$CSComplexity, data$CSType), mean)
data_avg <- data_avg %>%
  rename(
    Subject = Group.1,
    Group = Group.2, 
    CSComplexity = Group.3,
    CSType = Group.4,
    StartleAmplitude = x 
  )

anova_sebr_avg_trad <- aov(StartleAmplitude ~ (Group*CSType*CSComplexity) + Error(Subject/(CSType*CSComplexity)), data = data_avg)
summary(anova_sebr_avg_trad, type = 3)
etasq(mod, anova = TRUE)


# CS+/CS- difference complex CS control vs. experimental group
CS_diff_control <- data$StartleAmplitude[data$CSType=="CS+" & data$Group=="Control" & data$CSComplexity=="Complex"]-data$StartleAmplitude[data$CSType=="CS-" & data$Group=="Control" & data$CSComplexity=="Complex"]
CS_diff_exp <- data$StartleAmplitude[data$CSType=="CS+" & data$Group=="Experimental" & data$CSComplexity=="Complex"]-data$StartleAmplitude[data$CSType=="CS-" & data$Group=="Experimental" & data$CSComplexity=="Complex"]
ttest_result <- t.test(CS_diff_control, CS_diff_exp, alternative = "greater", paired = FALSE)
print(ttest_result)

# CS+ difference complex CS control vs. experimental group
data_avg <- aggregate(data[,"StartleAmplitude"], by = list(data$Subject, data$Group, data$CSType), mean)
data_avg <- data_avg %>%
  rename(
    Subject = Group.1,
    Group = Group.2, 
    CSType = Group.3,
    StartleAmplitude = x 
  )

CSp_control <- data_avg$StartleAmplitude[data_avg$CSType=="CS+" & data_avg$Group=="Control"]
CSp_exp <- data_avg$StartleAmplitude[data_avg$CSType=="CS+" & data_avg$Group=="Experimental"]
ttest_result <- t.test(CSp_control, CSp_exp, alternative = "two.sided", paired = FALSE)
print(ttest_result)

data <- data_avg

# CS+/CS- difference for controls over CS complexity
CSp_control <- data$StartleAmplitude[data$CSType=="CS+" & data$Group=="Control"]
CSm_control <- data$StartleAmplitude[data$CSType=="CS-" & data$Group=="Control"]
ttest_result <- t.test(CSp_control, CSm_control, alternative = "greater", paired = TRUE)
print(ttest_result)

# CS+/CS- difference for experimentals over CS complexity
CSp_exp <- data$StartleAmplitude[data$CSType=="CS+" & data$Group=="Experimental"]
CSm_exp <- data$StartleAmplitude[data$CSType=="CS-" & data$Group=="Experimental"]
ttest_result <- t.test(CSp_exp, CSm_exp, alternative = "greater", paired = TRUE)
print(ttest_result)


data_firsthalf <- data[data$Trial <= 6,]
data_lasthalf <- data[data$Trial >= 13,]
# Average over CS complexity
data_avg_h1 <- aggregate(data_firsthalf[,"StartleAmplitude"], by = list(data_firsthalf$Subject, data_firsthalf$Group, data_firsthalf$CSType), mean)
data_avg_h1 <- data_avg_h1 %>%
  rename(
    Subject = Group.1,
    Group = Group.2, 
    CSType = Group.3,
    StartleAmplitude = x 
  )

data_avg_h2 <- aggregate(data_lasthalf[,"StartleAmplitude"], by = list(data_lasthalf$Subject, data_lasthalf$Group, data_lasthalf$CSType), mean)
data_avg_h2 <- data_avg_h2 %>%
  rename(
    Subject = Group.1,
    Group = Group.2, 
    CSType = Group.3,
    StartleAmplitude = x 
  )

# Block 1 data controls
#CSp_control_b1 <- data$StartleAmplitude[data$CSType=="CS+" & data$Group=="Control" & data$Trial <= 12]
#CSm_control_b1 <- data$StartleAmplitude[data$CSType=="CS-" & data$Group=="Control" & data$Trial <= 12]
# Block 1 data exp
#CSp_exp_b1 <- data$StartleAmplitude[data$CSType=="CS+" & data$Group=="Experimental" & data$Trial <= 12]
#CSm_exp_b1 <- data$StartleAmplitude[data$CSType=="CS-" & data$Group=="Experimental" & data$Trial <= 12]
# Block 6 data controls
#CSp_control_b6 <- data$StartleAmplitude[data$CSType=="CS+" & data$Group=="Control" & data$Trial >= 13]
#CSm_control_b6 <- data$StartleAmplitude[data$CSType=="CS-" & data$Group=="Control" & data$Trial >= 13]
# Block 6 data exp
#CSp_exp_b6 <- data$StartleAmplitude[data$CSType=="CS+" & data$Group=="Experimental" & data$Trial >= 13]
#CSm_exp_b6 <- data$StartleAmplitude[data$CSType=="CS-" & data$Group=="Experimental" & data$Trial >= 13]


# Block 1 data controls
CSp_control_b1 <- data_avg_h1$StartleAmplitude[data_avg_h1$CSType=="CS+" & data_avg_h1$Group=="Control"]
CSm_control_b1 <- data_avg_h1$StartleAmplitude[data_avg_h1$CSType=="CS-" & data_avg_h1$Group=="Control"]
# Block 1 data exp
CSp_exp_b1 <- data_avg_h1$StartleAmplitude[data_avg_h1$CSType=="CS+" & data_avg_h1$Group=="Experimental"]
CSm_exp_b1 <- data_avg_h1$StartleAmplitude[data_avg_h1$CSType=="CS-" & data_avg_h1$Group=="Experimental"]
# Block 6 data controls
CSp_control_b6 <- data_avg_h2$StartleAmplitude[data_avg_h2$CSType=="CS+" & data_avg_h2$Group=="Control"]
CSm_control_b6 <- data_avg_h2$StartleAmplitude[data_avg_h2$CSType=="CS-" & data_avg_h2$Group=="Control"]
# Block 6 data exp
CSp_exp_b6 <- data_avg_h2$StartleAmplitude[data_avg_h2$CSType=="CS+" & data_avg_h2$Group=="Experimental"]
CSm_exp_b6 <- data_avg_h2$StartleAmplitude[data_avg_h2$CSType=="CS-" & data_avg_h2$Group=="Experimental"]

# CS+/CS- difference
CS_diff_control_b1 <- CSp_control_b1-CSm_control_b1
CS_diff_control_b6 <- CSp_control_b6-CSm_control_b6
CS_diff_exp_b1 <- CSp_exp_b1-CSm_exp_b1
CS_diff_exp_b6 <- CSp_exp_b6-CSm_exp_b6

CS_diff_control_b1b6 <- CS_diff_control_b1-CS_diff_control_b6
CS_diff_exp_b1b6 <- CS_diff_exp_b1-CS_diff_exp_b6

# T-tests

# Difference block 1-2 control vs. exp
ttest_result <- t.test(CS_diff_control_b1, CS_diff_exp_b1, alternative = "two.sided", paired = FALSE)
print(ttest_result)
# Difference block 5-6 control vs. exp
ttest_result <- t.test(CS_diff_control_b6, CS_diff_exp_b6, alternative = "two.sided", paired = FALSE)
print(ttest_result)
# Difference between the groups for first half vs. last half in CS+/CS- discrimination
ttest_result <- t.test(CS_diff_control_b1b6, CS_diff_exp_b1b6, alternative = "two.sided", paired = FALSE)
print(ttest_result)

# Block 1 vs. block 2 control
ttest_result <- t.test(CS_diff_control_b1, CS_diff_control_b6, alternative = "two.sided", paired = TRUE)
print(ttest_result)
# Block 1 vs. block 2 exp
ttest_result <- t.test(CS_diff_exp_b1, CS_diff_exp_b6, alternative = "two.sided", paired = TRUE)
print(ttest_result)
