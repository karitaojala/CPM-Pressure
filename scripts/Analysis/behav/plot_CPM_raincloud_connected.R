library(raincloudplots)

cpm_data <- read.csv(file = 'C:/Data/CPM-Pressure/data/CPM-Pressure-01/Pilot-02/cpm_data.csv')
  
df_1x1 <- data_1x1(
  array_1 = cpm_data$Control,
  array_2 = cpm_data$Experimental,
  jit_distance = 0.0001,
  jit_seed = 321)

raincloud_2 <- raincloud_1x1_repmes(
  data = df_1x1,
  colors = (c('goldenrod1', 'darkorange1')),
  fills = (c('goldenrod1', 'darkorange1')),
  line_color = 'gray',
  line_alpha = .9,
  size = 3,
  alpha = .6,
  align_clouds = FALSE) +
  
  scale_x_continuous(breaks=c(1,2), labels=c("Not painful", "Painful"), limits=c(0, 3)) +
  scale_y_continuous(n.breaks = 10, limits=c(0,100)) +
  xlab("Conditioning stimulus intensity") + 
  ylab("Test stimulus pain rating (VAS)") +
  ggtitle("Conditioned Pain Modulation") +
  theme_classic() + 
  theme(text = element_text(size = 10), axis.text = element_text(colour = 'black'), plot.title=element_text(face="bold", size=12, hjust = 0.5))

raincloud_2

ggsave("C:/Data/CPM-Pressure/data/CPM-Pressure-01/Pilot-02/cpm_effect_N13.png", width = 8.5, height = 10, units = "cm")
