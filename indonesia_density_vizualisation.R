#Set the Environment
install.packages("sf")
install.packages("raster")
install.packages("tidyverse")
install.packages("stars")
install.packages("MetBrewer")
install.packages("colorspace")
library(remote)
remotes::install_github("https://github.com/tylermorganwall/rayshader")
remotes::install_github("https://github.com/tylermorganwall/rayrender")
library(rayrender)
library(rayshader)
library(colorspace)
library(MetBrewer)
library(stars)
library(raster)
library(sf)
library(tidyverse)


#Read Contur Data
data <- st_read("data/kontur_population_ID_20220630.gpkg")

#Read shapefile of Indoneisa maps
idn <- readRDS("gadm36_IDN_1_sf.rds")

#Get Indonesia shapefile
names(idn)
unique(idn$NAME_0)
id <- idn |> 
  filter(NAME_0 == "Indonesia") |> 
  st_transform(crs = st_crs(data))

# check with map
id |> 
  ggplot() +
  geom_sf()

# do intersection on data to limit kontur to Indonesia
st_id <- st_intersection(data, id)

# define aspect ratio based on bounding box
bb <- st_bbox(st_id)

bottom_left <- st_point(c(bb[["xmin"]], bb[["ymin"]])) |> 
  st_sfc(crs = st_crs(data))

bottom_right <- st_point(c(bb[["xmax"]], bb[["ymin"]])) |> 
  st_sfc(crs = st_crs(data))

# check by plotting points

id |> 
  ggplot() +
  geom_sf() +
  geom_sf(data = bottom_left) +
  geom_sf(data = bottom_right, color = "red")

width <- st_distance(bottom_left, bottom_right)

top_left <- st_point(c(bb[["xmin"]], bb[["ymax"]])) |> 
  st_sfc(crs = st_crs(data))

height <- st_distance(bottom_left, top_left)

# handle conditions of width or height being the longer side

if(height > width){
  h_ratio <- 1
  w_ratio <- width/height
} else{
  w_ratio <- 1
  h_ratio <- height/width
}

# convert to raster so we can then convert to matrix
size <- 2000
id_rast <- st_rasterize(st_id, 
                              nx = floor(size * w_ratio),
                              ny = floor(size * h_ratio))

mat <- matrix(id_rast$population, 
              nrow = floor(size * w_ratio),
              ncol = floor(size * h_ratio))

# create color palette
pal <- "miami"

c1 <- mixcolor(alpha = seq(from = 0, to = 1, by = .25), color1 =  hex2RGB("#00efff"), 
               color2 = hex2RGB("#ffffff")) |> 
  hex()
c2 <- mixcolor(alpha = seq(from = 0, to = 1, by = .25), color1 =  hex2RGB("#ff4992"), 
               color2 = hex2RGB("#ffffff")) |> 
  hex()

colors <- c(c1[1:4], rev(c2[1:4]))
swatchplot(colors)

texture <- grDevices::colorRampPalette(colors, 4)(256)
swatchplot(texture)


# plot that 3d thing!
rgl::close3d()
mat |> 
  height_shade(texture = texture) |> 
  plot_3d(heightmap = mat, 
          # This is my preference, I don't love the `solid` in most cases
          solid = FALSE,
          soliddepth = 0,
          # You might need to hone this in depending on the data resolution;
          # lower values exaggerate the height
          z = 100/4,
          # Set the location of the shadow, i.e. where the floor is.
          # This is on the same scale as your data, so call `zelev` to see the
          # min/max, and set it however far below min as you like.
          shadowdepth = 0,
          # Set the window size relatively small with the dimensions of our data.
          # Don't make this too big because it will just take longer to build,
          # and we're going to resize with `render_highquality()` below.
          windowsize = c(800,800), 
          # This is the azimuth, like the angle of the sun.
          # 90 degrees is directly above, 0 degrees is a profile view.
          phi = 90, 
          zoom = 1, 
          # `theta` is the rotations of the map. Keeping it at 0 will preserve
          # the standard (i.e. north is up) orientation of a plot
          theta = 0, 
          background = "white") 

# Use this to adjust the view after building the window object
render_camera(phi = 45, zoom = .75, theta = 20)

outfile <- "data/indonesia_density.png"

{
  start_time <- Sys.time()
  cat(crayon::cyan(start_time), "\n")
  if (!file.exists(outfile)) {
    png::writePNG(matrix(1), target = outfile)
  }
  render_highquality(
    filename = outfile,
    interactive = FALSE,
    lightdirection = rev(c(120, 120, 130, 130)),
    lightcolor = c(colors[7], "white", colors[2], "white"),
    lightintensity = c(750, 100, 1000, 100),
    lightaltitude = c(10, 80, 10, 80),
    samples = 450,
    width = 1400,
    height = 1400
  )
  end_time <- Sys.time()
  diff <- end_time - start_time
  cat(crayon::cyan(diff), "\n")
}


