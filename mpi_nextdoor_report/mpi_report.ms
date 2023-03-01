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

.de BL
.IP \(bu 2
..

.nr FigCount 1

.de figure
. ps \n[FGPS]
. ce
. nop Figure \\n[FigCount]: \\$^
. ps \n[PS]
.nr FigCount +1
..

.EQ
delim $$
define forall '\[fa]'
define memof  '\[mo]'
define odot 'special Odot'
.EN

.de Odot
.ds 0s \
\Z'\v'-\\n(0hu/4u'\s-4\[ci]\s+4'\
\Z'\h'0.8n'\\*(0s'\
\h'\\n(0wu+1n'
..

.R1
discard BXYZ
no-accumulate
.R2


.ds TITLE MPI brute-force all-kNN search

.\" cover
.TL
\*[TITLE]
.AU
Ioannis Stefanidis - 9587
.AI
Aristotel University of Thessaloniki
.sp 6p
.C
8 January 2023
.AB no
For this assignment we were asked implement in MPI a distributed brute-force
all-KNN search algorithm for the $k$ nearest neighbors (kNN) of each point in a
dataset.
.AE

.\" beginning of document
.SH 1
Communication in a Ring
.PP
Each MPI process $P sub i$ is reading a part of the provided dataset and it
calculates the distance of its own points from all (other) points and record the
distances and global indices of the $k$ nearest for each of its own points.
While calculating the distances, each process sends it's own points to the next
process and receives the points from the previous process. By doing that
asynchronous we hide the communication costs for these data transfers.
.LP
Having $NP$ number of processes means that after $NP$ iterations of sending and
receiving all processes would have checked their points against the whole
dataset. At this points the host machine (process #0) writes it's own results to
a file and one by one receives and appends the results from all other processes.

.SH 1
kNN Search Algorithm
.SH 2
Finding the distances
.PP
To find the $k$ nearest neighbors for each point we calculate the Euclidean
Distance Matrix $D$, then sort each row (in parallel with opencilk) using
quickselect to get the $k$ smallest distances and finally sort each row from 0
to $k$ using quicksort. To calculate the matrix $D$ the openblas library is used
to multiply the matrix X with Y, where X are the process's points and Y the
points that are cycling through the ring. After that for every point $d sub ij
memof ^ D$ the addition $d sub ij = d sub ij + sum from 0 to d {x sub id sup 2 +
y sub jd sup 2}$ is performed. So the final matrix $D$ can be expressed as
(the $-2$ multiplication is performed by \f[CW]openblas\fR):
.EQ
define XT 'X sup T'
define YT 'Y sup T'
D = (X odot X) 1 sub {d times n} - 2 X YT + (Y odot Y) 1 sub {d times m}
.EN
.SH 2
Keeping track of global indices
.PP
When the matrix $D$ is created we also create a matrix $D sub ind$ to keep track
of the indices. While sorting the $D$ with quickselect and quicksort the same
swaps are preformed on the $D_ind$ matrix, this way we can keep track of the
global indices.

.SH 1
Testing
.PP
To check the correctness of the program regular Cartesian 2D,3D, and 4D grids
were used as inputs. For these grids the first $3 sup d$ neighbors are known for
each point, so the program output for $k=3 sup d$ was compered with the known
neighbors and found equal.

.SH 1
Benchmarking
.PP
To measure the performance and speedup we used the following datasets: 
.BL
MNIST $60"K" times 784$
.BL
2D grid $1"M" times 2$
.BL
3D grid $1"M" times 3$
.BL
4D grid $810"K" times 4$
\
.LP
These grids were generated using the \f[CW]grid\fR executable\*[*] which is
provided with the source code.
.FS
e.g. \s-2\f[CW]./grid 3 100 100 100\fR\s+2 outputs the 3D grid.
.FE
.SH 2
Finding the fastest config
.PP
The AUTH HPC\*[*] provided us maximum of 1024 cpus. Each node in the \fIrome\fR
partition has 128 cpus so to fully take advantage of the Aristotel cluster we
need to use 8 nodes. So we ran 4 tests for each dataset, in each test we
assigned a different amount of cpus to every process. The fastest results of these
tests are shown at the following table (Fig. \n[FigCount]), where $ppn$ is the
number of process per node and $cpp$ is the number of cores per process ($ppn =
128/cpp$).
.FS
HPC website: https://hpc.auth.gr/
.FE
.DS C
.TS
tab(|);
|l|c|c|c|c|c|c|
|l|r|r|r|r|r|r|.
_
Dataset  |    m |   d |  k | $cpp$ | $ppn$ | time(s)
_
_
2D-Grid  |   1M |   2 |  9 |     4 |    32 |     402
3D-Grid  |   1M |   3 | 27 |     4 |    32 |     117
4D-Grid  | 810K |   4 | 81 |     2 |    64 |      62
12D-Grid | 531K |  12 | 10 |     2 |    64 |      13
MNIST    |  60K | 784 |  3 |     8 |    16 |    5.65
_
.TE
.figure Table of the fastest configs for each dataset
.DE
.bp
.LP
By visualizing the results (Fig. \n[FigCount]), we see that creating less
processes per node with greater amount of cpus is slower than more processes
with smaller amount of cpus. Also we notice that for the \fIMNIST\fR dataset
that has much less points than the others but bigger dimension, the fastest
config uses 8 cores per process, that could be because the openblas library the
multiplies $X$($m times d$) with $Y$($n times d$) needs the extra cores.
.G1
frame invis ht 2 wid 5 left solid bot solid
#ticks bottom off
label left "$log(t)$ (ms)" left 0.2
label bottom "Number of cores per proccess"

draw    d3 dashed color    "red"
draw    d4 dashed color   "blue"
draw mnist dashed color  "green"
draw    d2 dashed color "purple"
draw   d12 dashed color   "cyan"

i = 1

copy "data/data.d" thru {
  if i > 1 then {
    if i < 7 then {
      next d3 at $5, log($7)
      grid bottom at $5
    }
  }
  if i > 6 then {
    if i < 12 then {
      next d4 at $5, log($7)
    }
  }
  if i > 11 then {
    if i < 17 then {
      next mnist at $5, log($7)
    }
  }
  if i > 16 then {
    if i < 22 then {
      next d2 at $5, log($7)
    }
  }
  if i > 21 then {
    if i < 27 then {
      next d12 at $5, log($7)
    }
  }
  i = i+1
}

# legend
lx  = 26   # legend x
ly  = 4.95    # legend y
lyg = 0.2  # legend gap
lxg = 1    # legend gap

copy until "DONE" thru {
  line color "$3" $2 from lx, $1 to lx+lxg, $1
  " $4" size -2 ljust at lx+lxg, $1
}
ly       solid purple 2D-Grid
ly-lyg   solid red    3D-Grid
ly-lyg*2 solid blue   4D-Grid
ly-lyg*3 solid cyan   12D-Grid
ly-lyg*4 solid green  MNIST
DONE
.G2
.DS C
.figure Logarithmic execution time for different ammount of cores per proccess
.DE

.SH 2
Finding the most efficient config
.PP
Utilizing all 1024 cpus available give us the best results but lets try to find
the most efficient config by looking at the strong scaling.  In strong scaling,
the problem size is kept constant while the number of nodes is increased.
.G1
line_from = 27
line_to   = 33
draw mnist solid color "green"

frame invis ht 2 wid 5 left solid bot solid
label left "Execution time (s)" left 0.2
label bottom "Number of nodes"

i = 1
copy "data/data.d" thru {
  if i >= line_from then {
    if i <= line_to then {
      next mnist at $2, $7/1000
      grid bottom at $2
    }
  }
  i = i+1
}

# legend
lx  = 7.1 #legend x
ly  = 390 #legend y
lyg = 2   #legend gap
lxg = 0.2 #legend gap

copy until "DONE" thru {
  line color "$3" $2 from lx, $1 to lx+lxg, $1
  " $4" size -2 ljust at lx+lxg, $1
}
ly solid green MNIST
DONE
.G2
.figure Execution time for the MNIST dataset with respect to the number of \
nodes (cpp=8, ppn=1) 
.LP
From the above graph we notice that after 5 nodes the decrease in execution time
levels off, so we can maybe choose 6 nodes as the saturation point for the MNIST
dataset, where adding more nodes doesn't result in significant decrease in
execution time.
.bp
.PP
Because of the unavailability of resources in HPC, finding the saturation point
for each dataset wasn't possible. In the table below (Fig. \n[FigCount]) you can
find all the tests that took place for this assignment (everything ran in the
rome partition of HPC that has \fIAMD EPYC 7662\fR cpus).
.DS C
.TS
tab(|);
|l|c|c|c|c|c|c|c|
|l|r|r|r|r|r|r|r|.
_
Dataset  |    m |   d |  k | Nodes | $cpp$ | $ppn$ | time(s)
_
_
2D-Grid  |   1M |   2 |  9 |     8 |    32 |     4 |   641.4
2D-Grid  |   1M |   2 |  9 |     8 |    16 |     8 |   485.8
2D-Grid  |   1M |   2 |  9 |     8 |     8 |    16 |   420.4
2D-Grid  |   1M |   2 |  9 |     8 |     4 |    32 |   402.6
2D-Grid  |   1M |   2 |  9 |     8 |     2 |    64 |   446.1
3D-Grid  |   1M |   3 | 27 |     8 |    32 |     4 |   352.0
3D-Grid  |   1M |   3 | 27 |     8 |    16 |     8 |   273.7
3D-Grid  |   1M |   3 | 27 |     8 |     8 |    16 |   185.4
3D-Grid  |   1M |   3 | 27 |     8 |     4 |    32 |   117.0
3D-Grid  |   1M |   3 | 27 |     8 |     2 |    64 |   163.4
4D-Grid  | 810K |   4 | 81 |     8 |    32 |     4 |   146.9
4D-Grid  | 810K |   4 | 81 |     8 |    16 |     8 |   105.4
4D-Grid  | 810K |   4 | 81 |     8 |     8 |    16 |    79.9
4D-Grid  | 810K |   4 | 81 |     8 |     4 |    32 |    66.9
4D-Grid  | 810K |   4 | 81 |     8 |     2 |    64 |    62.0
12D-Grid | 531K |  12 | 10 |     8 |    32 |     4 |    29.1
12D-Grid | 531K |  12 | 10 |     8 |    16 |     8 |    23.0
12D-Grid | 531K |  12 | 10 |     8 |     8 |    16 |    22.0
12D-Grid | 531K |  12 | 10 |     8 |     4 |    32 |    18.5
12D-Grid | 531K |  12 | 10 |     8 |     2 |    64 |    13.4
MNIST    |  60K | 784 |  3 |     8 |    32 |     4 |     7.7
MNIST    |  60K | 784 |  3 |     8 |    16 |     8 |     5.9
MNIST    |  60K | 784 |  3 |     8 |     8 |    16 |     5.6
MNIST    |  60K | 784 |  3 |     8 |     4 |    32 |     5.7
MNIST    |  60K | 784 |  3 |     8 |     2 |    64 |     6.7
MNIST    |  60K | 784 |  3 |     2 |     8 |     1 |   388.4
MNIST    |  60K | 784 |  3 |     3 |     8 |     1 |   162.9
MNIST    |  60K | 784 |  3 |     4 |     8 |     1 |   193.4
MNIST    |  60K | 784 |  3 |     5 |     8 |     1 |   153.5
MNIST    |  60K | 784 |  3 |     6 |     8 |     1 |   141.9
MNIST    |  60K | 784 |  3 |     7 |     8 |     1 |   166.8
MNIST    |  60K | 784 |  3 |     8 |     8 |     1 |   130.9
_
.TE
.figure All the runs that were recorded during this assignment.
.DE

.B1
.CD
The source code for this assignment is available at:
.br
.I "https://github.com/johnstef99/mpi-nextdoor"
.DE
.B2
