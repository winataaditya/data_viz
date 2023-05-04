#Set the environment
#Load library yang dibutuhkan
library(magick)
library(MetBrewer)
library(colorspace)
library(ggplot2)
library(glue)
library(stringr)

#Menggambik gambar yang telah dirender
img <- image_read("data/indonesia_density.png")

#Menentukan warna teks untuk anotasi gambar
text_color <- rev("#33006e")
swatchplot(text_color)

#Definisikan teks yang hendak dimasukkan
annot <- glue("This data visualization shows population density of Indonesia. The Population estimates are bucketed into 400 meter hexagons.") |> 
  str_wrap(45)
anno2 <- glue("Data: Kontur Population by kontur.io (Relased on 2022-06-30") |> 
  str_wrap(45)

#Waktunya masukan anotasi ke dalam gambar
img |> 
  image_annotate("Indonesia Density",
                 gravity = "noth",
                 location = "+0+100",
                 color = text_color,
                 size = 70,
                 weight = 700,
                 font = "Javanese Text") |> 
  image_annotate(annot,
                 gravity = "northeast",
                 location = "+200+200",
                 color = text_color,
                 size = 40,
                 font = "El Messiri") |> 
  image_annotate(annot,
                 gravity = "southwest",
                 location = "+200+200",
                 color = text_color,
                 size = 40,
                 font = "El Messiri") |> 
  image_annotate(glue("Data Visualization by Puja Aditya Winata | ",
                      "With R Programming)"),
                 gravity = "south",
                 location = "+0+100",
                 font = "El Messiri",
                 color = alpha(text_color, .5),
                 size = 30) |> 
  image_write("data/Jawa tengah density/indonesia_final_plot.png")
