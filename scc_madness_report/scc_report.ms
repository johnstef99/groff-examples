.\" config
.nr PS 12
.nr FM 0.5i
.nr GROWPS 2
.nr PSINCR 3p
.nr FL \n[LL]
.nr FGPS \n[PS]-2

.OH '-\En[%]-''\E*[TITLE]'
.EH '\E*[TITLE]''-\En[%]-'

.de PT
.ie \\n%=1 .if \\n[pg*P1] .tl \\*[pg*OH]
.el \{\
.	ie o .tl \\*[pg*OH]
.	el .tl \\*[pg*EH]
.\}
.sp -1
\l'6i\[ul]'
..

.nr FigCount 1

.de figure
. ps \n[FGPS]
. nop Figure \\n[FigCount]: \\$^
. ps \n[PS]
.nr FigCount +1
..

.EQ
delim $$
define forall '\[fa]'
define memof  '\[mo]'
.EN

.R1
discard BXYZ
no-accumulate
.R2


.ds TITLE SCC Coloring Algorithm in parallel with C

.\" cover
.TL
\*[TITLE]
.AU
Ioannis Stefanidis - 9587
.AI
Aristotel University of Thessaloniki
.sp 6p
.C
29 November 2022
.AB no
For this assignment we were asked to find all the \fBStrongly Connected
Components (SCC) in a directed graph\fR. The goal was to implement the Coloring
Algorithm, which can be executed in parallel. The algorithm was implemented in C
with 3 different frameworks/libraries OpenCilk, OpenMP and pthread.
.AE

.\" beginning of document
.SH 1
Data Structure
.PP
The graphs were provided to us by \fISuiteSparse Matrix Collection\fR
.[
matrix collection
.]
in a sorted COO matrix format. Given the above, I stored the graph in CSC format
(Compressed Sparse Column) by reading the file line by line. By doing that and
not storing the Adjacency Matrix to create the CSC or the CSR matrices I managed
to read graphs with file-sizes much greater than my available RAM.
.LP
Having only the CSC left me with 2 options. The first one was to transpose the
CSC to get the CSR, which I did and it worked well for graphs with a relatively
small amount of edges. But doing that for graphs with 1.4B edges was too
time-consuming and also meant that I would have to allocate 2 times the memory
of the CSC. So I ended up with the second option which was to modify the
coloring algorithm to only use the in-degree edges of a vertice.
.LP
For the graph representation (\fCstruct Graph\fR) I decided to use the CSC
matrix and 2 arrays with \fCnumber_of_vertices\fR length to keep track of the
scc_id of each vertice and which vertices I have removed during the trimming and
the coloring.

.SH 1
Parallelization
.SH 2
Trimming in parallel
.PP
To trim the graph having only the in-degree edges of each vertice meant that I
had to go through each edge $(u,v) memof ^ E' forall ^ u ^ memof ^ V$ and mark
that vertice $u$ has an in-degree edge and vertice $v$ has an out-degree edge
($E'$ is the set of incoming edges and $V$ are all the graph's vertices). After
doing that I had to go through each vertice and check if it has zero in or out
edges to trim it. Both of these loops can be executed in parallel one after the
other. Although at the first loop we can encounter a race condition in the case
where there are edges $({u sub 1}, {v sub 1})$, $({u sub 2}, {v sub 1})$ which
for both we are going to try to write to the $v sub 1$ position of
\fChas_out[]\fR array, there isn't any real problem with that because the
information that the vertice $v sub 1$ has an out-degree edge is going to be
saved.
.SH 2
Coloring and BFS in parallel
.PP
The original coloring algorithm
.[
  coloring bfs
.]
that we were asked to implement uses the outgoing edges to determine if the
color of a vertice should change. On the other hand, I only use the incoming
edges, so the color of a vertice $u$ can be determined by this function
$color(u) = min(color(u), color(v)) ^ forall (u,v) ^ memof ^ E'$.
This function should run in loop until there are not further change to colors,
to attain that, I kept a boolean \fCcolor_changed\fR outside of the while loop.
Propagating the colors in parallel results in a race condition on the
\fCcolor_changed\fR boolean, but once again, there is no problem with that race
because the loop will run again as intended, no matter which thread will turn
the \fCcolor_changed\fR to true (for OpenCilk reducers had to be used to avoid
\fIfalse sharing\fR).
.LP
Continuing with running the BFS in parallel for each unique color, we aren't
going to encounter any race condition here. Because every BFS is going to have a
different starting vertice $u sub entry$ and it's going to write at
\fCremoved[$v$]\fR$forall v : color(v)==color({u sub entry})$.

.SH 1
Results
.PP
.KS
At the following table we can see all the graphs that were used for testing and
the number of vertices, edges and SCC for each one.
.DS C
.TS
tab(|);
|l|c|c|c|
|l|r|r|r|.
_
Graph's Name          | Vertices |    Edges   |   SCC  
_
_
celegansneural        |      297 |       2345 |      57
foldoc                |    13356 |     120238 |      71
language              |   399130 |    1216334 |    2456
eu-2005               |   862664 |   19235140 |   90768
wiki-topcats          |  1791489 |   28511807 |       1
sx-stackoverflow      |  2601977 |   36233450 |  953658
wikipedia-20060925    |  2983494 |   37269096 |  975731
wikipedia-20061104    |  3148440 |   39383235 | 1040035
wikipedia-20070206    |  3566907 |   45030389 | 1203340
wb-edu                |  9845725 |   57156537 | 4269022
indochina-2004        |  7414866 |  194109311 | 1749052
uk-2002               | 18520486 |  298113762 | 3887634
arabic-2005           | 22744080 |  639999458 | 4000414
uk-2005               | 39459925 |  936364282 | 5811041
twitter7              | 41652230 | 1468365182 | 8044728
_
.TE
.figure Table of graphs used for testing (sorted by the number of edges).
.DE
.KE
.KS
Now let's take a look for each implementation of the coloring algorithm how much
time was needed to find all the Strongly Connected Components:
.DS C
.TS
decimalpoint(.) nospaces tab(|);
|l|c|c|c|c|
|l|n|n|n|n|.
_
Graph's Name       |     Serial |   OpenCilk |     OpenMP |    Pthread
=
celegansneural     |      0.101 |      1.465 |      1.901 |      1.172
foldoc             |      2.034 |      2.735 |      3.125 |      3.408
language           |     74.904 |     29.379 |     35.710 |     34.884
eu-2005            |    456.182 |    192.661 |    222.757 |    221.364
wiki-topcats       |   5480.700 |   1601.571 |   1963.331 |   1913.419
sx-stackoverflow   |   1015.416 |    654.957 |    696.468 |    637.399
wikipedia-20060925 |   5409.858 |    2674.38 |   4023.632 |   4014.157
wikipedia-20061104 |   4307.067 |   2038.979 |   2887.391 |   2906.421
wikipedia-20070206 |   4312.090 |   2314.812 |   3053.161 |   3074.681
wb-edu             |  75944.155 |  19273.456 |  23687.500 |  21796.886
indochina-2004     |  25178.474 |   8448.959 |  11949.300 |  11550.546
uk-2002            |  56302.432 |  20127.728 |  21624.896 |  21219.984
arabic-2005        |  49314.916 |  17951.261 |  18427.179 |  18349.330
uk-2005            | 178898.744 |  62696.625 |  61866.468 |  69041.439
twitter7           | 538467.272 | 365122.715 | 414258.941 | 446038.842
_
.TE
.figure Table of execution time in milliseconds of each implementation for each
\s[\n[FGPS]]graph (machine used: Macbook Pro M1 16GB 1TB).\s[\n[PS]]
.DE
.KE
.LP
In most of the cases the fastest implementation is \fBOpenCilk\fR (see figure
\n[FigCount]) and that's reasonable for the following reasons. It's obvious that
is going to be faster than the serial implementation because we get more workers
doing the same amount of work, without any mutaxes, so no thread needs to wait
for an other to finish. Why though OpenCilk runs faster than OpenMP and Pthread
for the majority of the graphs?
.LP
To get the answer we need to understand how OpenMP and my Pthread implementation
manage the distribution of work between their threads. In both implementations
each time we need something to be done in parallel we spawn a new group of
threads to divide the work $W$ to $W/P$ where P is the number of threads, we
then wait for all the threads to finish (sync) and we exit the threads. That
means in case of a for loop with $V$ amount of iterations, each thread is going
to run $T = V/P$ amount of iterations, so the first thread is going to run for
$i ^ memof ^ [0:T-1]$ the second for $i ^ memof ^ [T: 2T-1]$ etc.. At this point
the problem is clear, what happens if a thread finishes all it's work? Well it
just going to do nothing until all the other threads are finished.
.LP
OpenCilk on the hand, uses what they call a \fIWork-Stealing Scheduler\fR.
.[
  scheduler
.]
What that does is, after the initial distribution of work to each thread, if a
thread finishes all it's work it selects randomly an other thread and "steals"
some work from it. So basically OpenCilk does a dynamic load balancing at
runtime. That's why on the largest graph \fItwitter\fR OpenCilk can get ahead
for a whole 1 minute.
.G1
frame invis ht 2 wid 5 left solid bot solid
#ticks bottom off
label left "Relative Time" left 0.2
#label bottom "Number of edges" left 0.2
grid bottom ticks off from 1 to 15 by 1

draw openCilk solid color "red"
draw openMP dashed color "blue"
draw pthread dashed color "brown"

copy "data/times.d" thru {
  pic A:Frame.Origin + (x_gg($1),0)
  pic B:Frame.Origin + (x_gg($1+0.5), -0.5/3)
  pic line from A to B "$2" ljust aligned below

  maxx = max($4, $5)
  maxx = max(maxx, $6)
  next openCilk at $1, $4/maxx
  next openMP   at $1, $5/maxx
  next pthread  at $1, $6/maxx
}

# legend
lx  = 2.2   # legend x
ly  = 0.75  # legend y
lyg = 0.03  # legend gap
lxg = 0.5   # legend gap

copy until "DONE" thru {
  line color "$3" $2 from lx, $1 to lx+lxg, $1
  $4 size -2 ljust at lx+lxg*1.1, $1
}
ly       solid  red   "OpenCilk"
ly-lyg   dashed blue  "OpenMP"
ly-2*lyg dashed brown "Pthread"
DONE
.G2
.sp 3.5
.CD
.figure Relative time graph for the parallel implementations.
.DE
.LP
Finally something worth mentioning is that for small graphs like the first two,
doing the extra work of creating threads and distributing work, get us worst
performance than running it in a single thread. Or in the case of the graph
.I foldoc
we can see that there is an optimal number of cores (see figure \n[FigCount]).
.KS
.G1
gw = 1.7
gh = 2/3 * gw

graph A
frame invis ht gh wid gw left solid bot solid
label left "Time (in ms)" left .25
label bot "Number of threads"
draw solid
copy "data/opencilk_celegansneural.csv"
ticks bot out at 1, 2, 4, 6, 8
label top "\fBcelegansneural\fR" down 0.25

graph B with .Frame.w at A.Frame.e +(1.25,0)
frame invis ht gh wid gw left solid bot solid
label left "Time (in ms)" left .25
label bot "Number of threads"
ticks bot out at 1, 2, 4, 6, 8
draw solid
copy "data/opencilk_foldoc.csv"
label top "\fBfoldoc\fR" down 0.25
.G2
.DS C
.figure Execution time per number of threads used.
.DE
.KE

.B1
.CD
The source code for this assignment is available at:
.br
.I "https://github.com/johnstef99/scc_madness"
.DE
.B2
