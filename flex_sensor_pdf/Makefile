.SUFFIXES: .jpg .eps .ms .ps .pdf

IMAGES=$(shell ls *.jpg | sed 's/.jpg/.eps/g')
all: $(IMAGES) flex_sensor.pdf

.jpg.eps:
	convert $< $@

.ms.ps:
	groff -Geptk -ms -Tps $< > $@

.ps.pdf:
	ps2pdf $< > $@

clean:
	rm *.pdf *.eps
