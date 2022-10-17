rm(list=ls())

library(dplyr)
library(tidyverse)
library(ggplot2)
#library(R.matlab)
library(car)
#library(mvoutlier)
library(lme4)
library(lmerTest)
library(multcomp)
library(emmeans)
library(nlme)
library(r2mlm)
#checkpoint("2022-09-07")

data <- read.csv("C:/Data/CPM-Pressure/scripts/Analysis/behav/Experiment-01_ratings_table_long.csv")
options(contrasts = c("contr.sum","contr.poly"))

#outlier_subs <- data$Subject[which(data$StartleAmplitude > 2)]
#data <- data[!is.element(data$Subject,outlier_subs),]

data$Subject <- factor(data$Subject)
#data$Stimulus <- factor(data$Stimulus)
#data$Trial <- factor(data$Trial)
#data$Block <- factor(data$Block)
#data$StimInBlock <- factor(data$StimInBlock)
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

nlme_1 <- nlme::lme(PainRating ~ Condition * Block * StimInBlock,
                    random = ~ (Condition)|Subject, data = data, na.action=na.omit, 
                    control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

nlme_2 <- nlme::lme(PainRating ~ Condition * Block * StimInBlock,
                         random = ~ (Condition+Block)|Subject, data = data, na.action=na.omit, 
                         control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

nlme_3 <- nlme::lme(PainRating ~ Condition * Block * StimInBlock,
                         random = ~ (Condition*StimInBlock)|Subject, data = data, na.action=na.omit, 
                         control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

#Condition*Block*StimInBlock does not converge

nlme_5 <- nlme::lme(PainRating ~ Condition * Block * StimInBlock,
                    random = ~ (Condition*StimInBlock)|Subject, data = data, na.action=na.omit, 
                    control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

# Only time effects as random effects
nlme_b1 <- nlme::lme(PainRating ~ Condition * Block * StimInBlock,
                    random = ~ (Block)|Subject, data = data, na.action=na.omit, 
                    control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

nlme_b2 <- nlme::lme(PainRating ~ Condition * Block * StimInBlock,
                    random = ~ (Block+StimInBlock)|Subject, data = data, na.action=na.omit, 
                    control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

nlme_b3 <- nlme::lme(PainRating ~ Condition * Block * StimInBlock,
                    random = ~ (Block*StimInBlock)|Subject, data = data, na.action=na.omit, 
                    control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

# bayestestR::bayesfactor_models(nlme_sebr_3, denominator = nlme_sebr_1)

car::Anova(nlme_b1, type = "III")
car::Anova(nlme_b1, type = "II")
car::Anova(nlme_b2, type = "III")

car::Anova(nlme_3, type = "III")

anova(nlme_b2, type = "marginal", adjustSigma = F)
# anova(nlme_b1, type = "sequential")

#drop1(nlme_b1, .~., test="Chisq")

summary(nlme_b1, type = 3)

plot(nlme_b2, resid(., type = "p") ~ fitted(.) | Condition, abline = 0)
plot(nlme_b2, resid(., scaled=TRUE) ~ fitted(.), abline = 0,pch=16, col=data$Condition, xlab="Fitted values",ylab="Standardised residuals")
plot(nlme_b2, Condition ~ resid(.))
plot(nlme_b2, PainRating ~ fitted(.) | Condition*Block, abline = c(0,1))

plot(nlme_b2, as.factor(Condition) ~ resid(., scaled=TRUE),abline=0,pch=16,xlab="Standardised residuals",ylab="Condition")

sjPlot::plot_model(nlme_b2, 
                   type = "est",
                   show.values=TRUE, show.p=TRUE)
sjPlot::plot_model(nlme_b2)
sjPlot::plot_model(nlme_b3)

sjPlot::tab_model(nlme_b2)
sjPlot::tab_model(nlme_b3)

effects_3w <- effects::effect(term= "Condition*Block*StimInBlock", mod= nlme_b2)
summary(effects_3w)
x_effects_3w <- as.data.frame(effects_3w)

write.csv(x_effects_3w,"C:\\Data\\CPM-Pressure\\scripts\\Analysis\\behav\\Experiment-01-nlmeb2-fit.csv", row.names = TRUE)

effects_plot <- ggplot() + 
  #2
  #geom_point(data, aes(Condition, PainRating)) + 
  #3
  #geom_point(data=x_effects_3w, aes(x=StimInBlock, y=fit), color="blue") +
  #4
  geom_line(data=x_effects_3w, aes(x=StimInBlock, y=fit), color="blue") +
  #5
  geom_ribbon(data= x_effects_3w, aes(x=StimInBlock, ymin=lower, ymax=upper), alpha= 0.3, fill="blue") +
  #6
  labs(x="Condition", y="Pain Rating")

effects_plot

emm <- emmeans(nlme_b2, pairwise ~ Condition | Block)
pairs(emm, simple = "Condition", adjust = "tukey", side = "left")

anova(nlme_2)
anova(nlme_3)
anova(nlme_5)

anova(nlme_b1)
anova(nlme_b2)
anova(nlme_b3)



#lmer_test <- lmer(PainRating ~ Condition * Block * StimInBlock + (Condition|Subject) + (Condition|Block), REML = TRUE, data = data)

#lmer_b1 <- lmer(PainRating ~ Condition * Block * StimInBlock + (1|Subject), REML = TRUE, data = data)
lmer_b11 <- lmer(PainRating ~ Condition * Block + (Block|Subject), REML = TRUE, data = data)
lmer_b12 <- lmer(PainRating ~ Condition * StimInBlock + (1|Subject), REML = TRUE, data = data)

lmer_b1 <- lmer(PainRating ~ Condition * Block * StimInBlock + (Block|Subject), REML = TRUE, data = data)
lmer_b2 <- lmer(PainRating ~ Condition * Block * StimInBlock + (Block+StimInBlock|Subject), REML = TRUE, data = data)
#lmer_b3 <- lmer(PainRating ~ Condition * Block * StimInBlock + (Block:StimInBlock|Subject), REML = TRUE, data = data)
# interaction Block:StimInBlock as random effect does not converge

lmer_1 <- lmer(PainRating ~ Condition * Block * StimInBlock + (Condition|Subject), REML = TRUE, data = data)
lmer_2 <- lmer(PainRating ~ Condition * Block * StimInBlock + (Condition+Block|Subject), REML = TRUE, data = data)
lmer_3 <- lmer(PainRating ~ Condition * Block * StimInBlock + (Condition:Block|Subject), REML = TRUE, data = data)

#car::Anova(lmer_b1,type="III",test="F")

sjPlot::tab_model(lmer_b1)

anova(lmer_b1, type = 1)
anova(lmer_b2)
anova(lmer_b3)

anova(lmer_1)
anova(lmer_2)
anova(lmer_3, type = 1)


# Post-hoc contrasts EMM
# Plot
emplot <- emmeans::emmip(lmer_b1, Condition, CIs = TRUE) + theme_bw() + scale_y_continuous(name = "Estimated marginal mean\n(pain rating)", limits = c(0,2))
emplot





# Traditional ANOVA
data_avg <- aggregate(data[,"PainRating"], by = list(data$Subject, data$Condition), mean, na.rm = TRUE)
data_avg <- data_avg %>%
  rename(
    Subject = Group.1,
    Condition = Group.2, 
    PainRating = x 
  )


bxp <- ggpubr::ggboxplot(
  data, x = "Block", y = "PainRating",
  color = "Condition", palette = "jco"
)
bxp

bdp <- ggpubr::ggdensity(data, x = "PainRating",
          add = "mean", rug = TRUE,
          color = "Condition", fill = "Condition",
          palette = c("#00AFBB", "#E7B800"))
bdp

data %>%
  group_by(Condition, Block) %>%
  shapiro_test(PainRating)


p <- ggplot(data_avg, aes(x=Condition, y=PainRating)) + 
  geom_boxplot()
p + geom_dotplot(binaxis='y', stackdir='center', dotsize=1)
p + geom_jitter(shape=16, position=position_jitter(0.1))

anova_trad <- aov(PainRating ~ Condition * Block + Error(Subject/(Condition)), data = data_avg)
anova_trad <- aov(PainRating ~ Condition * Block + Error(Subject), data = data_avg)
summary(anova_trad, type = 3)
DescTools::EtaSq(anova_trad, anova = FALSE)

anova1 <- aov(PainRating ~ Condition * Block * StimInBlock + Error(Subject/(Condition*Block*StimInBlock)), data = data)
summary(anova1, type = 3)

emm <- emmeans(anova1, pairwise ~ Condition | Block)
pairs(emm, simple = "Condition", adjust = "tukey", side = "left")

#anova1b <- car::Anova(lm(PainRating ~ Condition * Block * StimInBlock, data=data, contrasts=list(Condition=contr.sum)), type=3)
#anova1b
