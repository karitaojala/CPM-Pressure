rm(list = ls())

#remotes::install_github('jorvlan/raincloudplots')
library(raincloudplots)
library(plyr)
library(dplyr)

#cpm_data <- read.csv(file = 'C:/Data/CPM-Pressure/data/CPM-Pressure-01/Pilot-02/cpm_data.csv')
#data <- read.csv("C:/Data/CPM-Pressure/scripts/Analysis/behav/Experiment-01_ratings_table_long.csv")
data <-
  read.csv(
    "C:/Data/CPM-Pressure/scripts/Analysis/behav/Experiment-01_ratings_time_difference_table_wide.csv"
  )

# remove subject 50 (excluded)
#data <- data[!is.element(data$Subject,50),]

data$Subject <- factor(data$Subject)
#data$Block <- factor(data$Block)
data$Condition <- factor(data$Condition)
data$Condition <-
  plyr::revalue(data$Condition, c("0" = "Con", "1" = "Exp"))

# Mean-center time variables
#data$StimulusCentered <- scale(data$Stimulus, scale = FALSE)

#data_wide <- spread(data, Condition, PainRating)

#data_adj <- datawizard::adjust(data_wide, effect = "Stimulus", select = c("Con", "Exp"), keep_intercept = TRUE)

# Average over stimuli of each condition within subjects
#data_avg <- aggregate(data_wide[,c("Con","Exp")], by = list(data_adj$Subject), mean, na.rm=TRUE)
#data_avg <- data_avg %>%
#  rename(
#    Subject = Group.1,
#    #Condition = Group.2,
#    #PainRating = x
#  )

#CON_data <- data_avg[data_avg$Condition == "Con",]
#EXP_data <- data_avg[data_avg$Condition == "Exp",]

data_1x1 <- data_1x1(
  #array_1 = CON_data$PainRating,
  #array_2 = EXP_data$PainRating,
  #array_1 = data_avg$Con,
  #array_2 = data_avg$Exp,
  array_1 = data$RatingDiffCON,
  array_2 = data$RatingDiffEXP,
  jit_distance = 0.0001,
  jit_seed = 321
)

# raincloud_2 <- raincloud_1x1_repmes(
#   data = df_1x1,
#   #colors = (c('goldenrod1', 'darkorange1')),
#   colors = (c('#FCC018', '#3A77F2')),
#   fills = (c('#FCC018', '#3A77F2')),
#   line_color = 'gray',
#   line_alpha = .9,
#   size = 5,
#   alpha = 0.8,
#   align_clouds = FALSE) +

mean_x_axis <- c(1 - 0.25, 2 + 0.25)
mean_y_axis <- c(mean(data_1x1$y_axis[data_1x1$x_axis == "1"]),mean(data_1x1$y_axis[data_1x1$x_axis == "2"]))
data_mean <- data.frame(mean_x_axis,mean_y_axis)
  
colors = (c('#FCC018', '#3A77F2'))
fills = (c('#FCC018', '#3A77F2'))
line_color = 'gray'
line_alpha = .9
size = 5
alpha = 0.8
align_clouds = FALSE

figure_1x1 <-
  ggplot(data = data_1x1) + 
  geom_point(
    data = data_1x1 %>%
      dplyr::filter(x_axis == "1"),
    aes(x = jit, y = y_axis),
    color = colors[1],
    size = size,
    alpha = alpha,
    show.legend = FALSE) +
  geom_point(
    data = data_1x1 %>% 
      dplyr::filter(x_axis == "2"),
    aes(x = jit, y = y_axis),
    color = colors[2],
    size = size,
    alpha = alpha,
    show.legend = FALSE) +
  geom_line(
    aes(x = jit, y = y_axis, group = id),
    color = line_color,
    alpha = line_alpha,
    show.legend = FALSE) +
  geom_line(
    data = data_mean,
    aes(x = mean_x_axis, y = mean_y_axis),
    color = line_color,
    linewidth = 1.5,
    alpha = line_alpha,
    show.legend = FALSE) +
  geom_point(
    data = data_1x1 %>%
      dplyr::filter(x_axis == "1"),
    aes(x = x_axis, y = mean(y_axis)),
    color = colors[1],
    size = size,
    position = position_nudge(x = -0.25),
    show.legend = FALSE) +
  geom_point(
    data = data_1x1 %>%
      dplyr::filter(x_axis == "2"),
    aes(x = x_axis, y = mean(y_axis)),
    color = colors[2],
    size = size,
    position = position_nudge(x = 0.25),
    show.legend = FALSE) +
  geom_errorbar(
    data = data_1x1 %>%
      dplyr::filter(x_axis == "1"),
    aes(x = x_axis, y = mean(y_axis), ymin = mean(y_axis)-plotrix::std.error(y_axis), ymax = mean(y_axis)+plotrix::std.error(y_axis)),
    color = colors[1],
    width = 0.1, linewidth = 0.8,
    position = position_nudge(x = -0.25),
    show.legend = FALSE) +
  geom_errorbar(
    data = data_1x1 %>%
      dplyr::filter(x_axis == "2"),
    aes(x = x_axis, y = mean(y_axis), ymin = mean(y_axis)-plotrix::std.error(y_axis), ymax = mean(y_axis)+plotrix::std.error(y_axis)),
    color = colors[2],
    width = 0.1, linewidth = 0.8,
    position = position_nudge(x = 0.25), 
    show.legend = FALSE) +
  # gghalves::geom_half_boxplot(
  #   data = data_1x1 %>% dplyr::filter(x_axis == "1"),
  #   aes(x = x_axis, y = y_axis),
  #   color = colors[1],
  #   fill = fills[1],
  #   position = position_nudge(x = -0.3),
  #   side = "r",
  #   outlier.shape = NA,
  #   center = TRUE,
  #   errorbar.draw = FALSE,
  #   width = 0.2,
  #   alpha = alpha,
  #   show.legend = FALSE) + 
  # gghalves::geom_half_boxplot(
  #   data = data_1x1 %>%
  #     dplyr::filter(x_axis == "2"),
  #   aes(x = x_axis, y = y_axis),
  #   color = colors[2],
  #   fill = fills[2],
  #   position = position_nudge(x = 0.2),
  #   side = "r",
  #   outlier.shape = NA,
  #   center = TRUE,
  #   errorbar.draw = FALSE,
  #   width = 0.2,
  #   alpha = alpha,
  #   show.legend = FALSE) +
  gghalves::geom_half_violin(
    data = data_1x1 %>% dplyr::filter(x_axis == "1"),
    aes(x = x_axis, y = y_axis),
    color = colors[1],
    fill = fills[1],
    position = position_nudge(x = -0.35),
    side = "l",
    alpha = alpha,
    show.legend = FALSE) +
  gghalves::geom_half_violin(
    data = data_1x1 %>% dplyr::filter(x_axis == "2"),
    aes(x = x_axis, y = y_axis),
    color = colors[2],
    fill = fills[2],
    position = position_nudge(x = 0.35),
    side = "r",
    alpha = alpha,
    show.legend = FALSE) +
  
  scale_x_continuous(
    breaks = c(1, 2),
    labels = c("Non-painful", "Painful"),
    limits = c(0, 3)) +
  scale_y_continuous(n.breaks = 10, limits = c(-41, 41)) +
  xlab("Conditioning stimulus") +
  ylab(expression(paste(Delta, " Test stimulus pain rating (late \U2212 early)"))) +
  ggtitle("Early vs. late test pain ratings") +
  theme_classic() +
  theme(
    text = element_text(size = 20),
    #axis.text.x=element_text(size=rel(1)),
    axis.text.x = element_text(size = 18),
    axis.text.y = element_text(size = 18),
    axis.text = element_text(colour = 'black'),
    plot.title = element_text(face = "bold", size = 18, hjust = 0.5)
  )

figure_1x1

raincloud_2

#ggsave("C:/Data/CPM-Pressure/data/CPM-Pressure-01/Pilot-02/cpm_effect_N13.png", width = 8.5, height = 10, units = "cm")
