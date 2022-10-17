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

data <- read.csv("C:/Data/CPM-Pressure/scripts/Analysis/behav/Experiment-01_ratings_table_long.csv")
options(contrasts = c("contr.sum","contr.poly"))

data$Subject <- factor(data$Subject)
#data$Block <- factor(data$Block)
data$Condition <- factor(data$Condition)
data$Condition <- plyr::revalue(data$Condition, c("0"="Con", "1"="Exp"))

# Mean-center time variables
data$StimulusCentered <- scale(data$Stimulus, scale = FALSE)
data$BlockCentered <- scale(data$Block, scale = FALSE)
data$StimInBlockCentered <- scale(data$StimInBlock, scale = FALSE)

# Delete first stimulus of each block
data2 <- data[!(data$StimInBlock==1),]
data2$StimInBlock <- data2$StimInBlock-1
data2$Stimulus <- data2$Stimulus-1
data2$StimulusCentered <- scale(data2$Stimulus, scale = FALSE)

# LMEs
# Only time effects as random effects
nlme_s1 <- nlme::lme(PainRating ~ StimulusCentered * Condition,
                     random = ~ (StimulusCentered)|Subject, data = data, na.action=na.omit, 
                     control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")
  
nlme_s2 <- nlme::lme(PainRating ~ StimulusCentered * Condition,
                     random = ~ (Stimulus)|Subject, data = data2, na.action=na.omit, 
                     control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

nlme_b1 <- nlme::lme(PainRating ~ Condition * Block * StimInBlock,
                     random = ~ (Block)|Subject, data = data, na.action=na.omit, 
                     control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

nlme_b2 <- nlme::lme(PainRating ~ Condition * BlockCentered * StimInBlockCentered,
                     random = ~ (Block+StimInBlock)|Subject, data = data, na.action=na.omit, 
                     control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

# Does not converge with Block as factor
nlme_b3 <- nlme::lme(PainRating ~ Condition * Block * StimInBlock,
                     random = ~ (Block*StimInBlock)|Subject, data = data, na.action=na.omit, 
                     control = nlme::lmeControl(maxIter = 1e8, msMaxIter = 1e8), method = "REML")

car::Anova(nlme_s1, type = "III")
car::Anova(nlme_s2, type = "III")

car::Anova(nlme_b1, type = "III")
car::Anova(nlme_b2, type = "III")

anova(nlme_s1, type = "marginal", adjustSigma = F) # same as above
#drop1(nlme_b1, .~., test="Chisq")
#summary(nlme_b1, type = 3)

# Way to look at residuals
plot(nlme_b2, resid(., type = "p") ~ fitted(.) | Condition, abline = 0)
plot(nlme_b2, resid(., scaled=TRUE) ~ fitted(.), abline = 0,pch=16, col=data$Condition, xlab="Fitted values",ylab="Standardised residuals")
plot(nlme_b2, Condition ~ resid(.))
plot(nlme_s1, PainRating ~ fitted(.) | Condition*Stimulus, abline = c(0,1))
plot(nlme_b2, as.factor(Condition) ~ resid(., scaled=TRUE),abline=0,pch=16,xlab="Standardised residuals",ylab="Condition")

# Ways to look at estimates
sjPlot::plot_model(nlme_s1, 
                   type = "est", title = "Linear mixed effects model estimates",
                   show.values=TRUE, show.p=TRUE, ci.lvl = NA, se = TRUE,
                   vline.color = "grey", line.size = 2, dot.size = 3)
sjPlot::tab_model(nlme_s1) # Cleaner table of results

# Fitted responses
effects_3w <- effects::effect(term= "StimulusCentered*Condition", mod= nlme_s1,
                              xlevels=72)
summary(effects_3w)
x_effects_3w <- as.data.frame(effects_3w)
write.csv(x_effects_3w,"C:\\Data\\CPM-Pressure\\scripts\\Analysis\\behav\\Experiment-01-nlmes1-fit.csv", row.names = TRUE)


ggplot(data = data, 
       aes(x   = Stimulus,
           y   = PainRating, 
           col = as.factor(Condition)))+
  geom_point(size     = 1, 
             alpha    = .7, 
             position = "jitter")+
  geom_smooth(method   = lm,
              se       = T, 
              level    = 0.95,
              size     = 1.5, 
              linetype = 1, 
              alpha    = .7)+
  theme_minimal()+
  labs(title    = "Linear Relationship Between Stimulus Index and Pain Rating for the two Tonic Conditions")+
  scale_color_manual(name   =" Condition",
                     labels = c("Control (non-painful)", "Experimental (painful)"),
                     values = c("yellow", "orange"))
