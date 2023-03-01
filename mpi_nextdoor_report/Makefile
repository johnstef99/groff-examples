.SUFFIXES: .jpg .eps .ms .ps .pdf .grap .ref

REFER="/Users/johnstef/Documents/auth/parallel/mpi_nextdoor/report/bibliography.ref"

all: mpi_report.pdf

.jpg.eps:
	convert $< $@

.ms.ps:
	REFER=$(REFER) groff -GeptkR -P-pa4 -ms -Tps $< > $@

.ps.pdf:
	ps2pdf $< > $@

clean:
	rm *.pdf *.eps *.ps
