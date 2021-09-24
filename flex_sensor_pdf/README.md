# Flex Sensor PDF example

In this example I am using groff with a custom postscript
[circuitslib](https://github.com/johnstef99/circuitslib-pic) library I created
to draw simple circuits with groff. You have to download it separately. I am
also using grap (the `-G` flag) preprocessor to draw the graphs you see in the
pdf.

The [Makefile](Makefile) is very simple, it converts all jpgs to eps (filetype
that groff supports) using imagemagic(`convert`) and then uses `groff` to create a
postscript file that finally is passed to `ps2pdf` to generate the pdf file.
