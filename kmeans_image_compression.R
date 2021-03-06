# install.packages("imager")
# install.packages("dplyr")
# install.packages("data.table")
library(imager)
library(dplyr)
library(data.table)

# Load pic
beach <- load.image("beach.jpg")

# See dimensions
dim(beach)

# Plot
plot(beach)

# Make dataframe
df_beach <- as.data.frame(beach)

# Seperate colors red, blue, and green
red <- filter(df_beach, cc == 1) %>% select(value) %>% rename(red = value)
blue <- filter(df_beach, cc == 2) %>% select(value) %>% rename(blue = value)
green <- filter(df_beach, cc == 3) %>% select(value) %>% rename(green = value)

# make color dataframe which will be clustered with kmeans
df_original_colors = data.frame(red, blue, green)

# perfom K-means
k <- 10
max_iter <- 50
K_findings = kmeans(df_original_colors, centers = k, iter.max = max_iter, nstart = 30, algorith="MacQueen")

# Assign pixel to closest color cluster
df_original_colors[,"cluster"] <- K_findings$cluster
# or df_original_colors$cluster <- K_findings$cluster

# Make dataframe of all clusters with their kmeans centroid center values
df_kmeans_clusters = data.frame(cluster = 1:nrow(K_findings$centers), 
                            red_cluster = K_findings$centers[ ,"red"],
                            blue_cluster = K_findings$centers[ ,"blue"],
                            green_cluster = K_findings$centers[ , "green"])

# Match the pixel location with the assigned color cluster for compression. 
# Using data.table is a very efficient way to do this; although an index must be 
# made first because the order is not retained. This can also be done with the join 
# function with the argument type = "inner" which also retains the order.
# df_all_colors <- join(df_original_colors, df_kmeans_clusters, type = "inner")
# however, this is slower when dealing with bigger datasets compared to using data.table.
# This script uses the data.table function.
df_original_colors[ , "index"] <- seq.int(nrow(df_original_colors))
# or df_original_colors$index <- seq.int(nrow(df_original_colors))
dt_original <- data.table(df_original_colors, key = "cluster")
dt_clusters <- data.table(df_kmeans_clusters, key = "cluster")
df_all_colors <- dt_original[dt_clusters] %>% data.frame
df_all_colors <- df_all_colors[order(df_all_colors[, "index"]),] #ordering the rows in the index column
compressed_image <- matrix(df_all_colors$cluster, 
                           nrow = dim(beach)[1], ncol = dim(beach)[2]) # %>% as.cimg %>% plot

# Rebuild dataframe that will be converted to cimg and then plot. 
# dataframe needs columns x,y,cc,value
df_base <- select(df_beach, x, y, cc)
df_color_cluster <- data.frame(value = c(df_all_colors$red_cluster, 
                                         df_all_colors$blue_cluster, 
                                         df_all_colors$green_cluster))
clustered_beach_pic <- data.frame(df_base, df_color_cluster) %>% as.cimg(dim=c(dim(beach)[1],
                                                                               dim(beach)[2],
                                                                               dim(beach)[3], 
                                                                               dim(beach)[4]))

# Plot
plot(clustered_beach_pic)

