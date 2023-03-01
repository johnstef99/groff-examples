.SUFFIXES: .jpg .eps .ms .ps .pdf .grap .ref

REFER="/Users/johnstef/Documents/auth/parallel/scc_madness/report/bibliography.ref"

all: scc_report.pdf

.jpg.eps:
	convert $< $@

.ms.ps:
	REFER=$(REFER) groff -GeptkR -P-pa4 -ms -Tps $< > $@

.ps.pdf:
	ps2pdf $< > $@

clean:
	rm *.pdf *.eps *.ps
