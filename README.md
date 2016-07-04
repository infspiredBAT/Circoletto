# Circoletto
visualising sequence similarity with Circos

</br>
Online server at http://bat.infspire.org/tools/circoletto/
</br>
We also provide the CGI script and the HTML page, both of which will need some work to make them work for you.
</br></br>
<pre>
before you run Circoletto, be sure to:
- have Circos (tested with $circos_compatibility, http://circos.ca/software/download/circos/), BLAST (tested with 2.2.25) in your path, and BioPerl (tested with 1.6.901) installed
- check / edit (in the code) the two paths to Circos and Circos tools - if we cannot find them, we'll print a warning and exit
- if you need to increase the max_sequences > 200, you also need to edit max_ideograms in Circos' housekeeping.conf

circoletto.pl 

   either
--query     or  --q     -> (path to) the queries
--database  or  --db    -> (path to) the database
   or
--blastout  or --bl     -> (path to) the BLAST output

   other (optional) arguments
--best_hit              -> set to show only best hit per query
--best_hit_type         -> best hit type, 'entry' to show all HSPs per best hit [default], or 'local' to show single best HSP
--w_hits                -> set if you want to show only entries with BLAST hits
--z_by                  -> depth-order ribbons by 'score' (highest at top) [default] / 'score_rev' / 'alnlen' (longest at top) / 'alnlen_rev'
--e_value               -> E-value [default: 1e-10]
--gep                   -> gap extension penalty, set to >=2 if you need to constrain it e.g. for genomic data [default: -1]
--flt                   -> set to enable pre-filtering of query sequences
--html_out              -> set to provide BLAST HTML output (runs BLAST again...)
--no_labels             -> set to switch off labels
--out_size              -> set radius of output in pixels, so set to '1000' for a 2000x2000 output [default: 1000]
--out_type              -> output type, either 'svg', or 'png' [default]
--score2colour          -> score to colour ribbons with, 'bit' for bitscore [default], or 'eval' for E-value, or 'id' for % identity
--annotation            -> user provided annotation file, see 'example_annotation.txt'
--annocolour            -> colour ribbons by 'query' or 'database' default ideogram colours or annotation (see --annotation), or by 'query_rainbow_(colour|grey)' or 'database_rainbow_(colour|grey)'
--invertcolour          -> set to colour ribbons by SEQUENCE (i.e. not ORDER) invertion (or reverse complementarity or plus/minus), normal in black, inverted in lime
--untangling_off        -> set to turn off ribbon untangling
--revcomp_q             -> set to reverse complement query DNA sequences
--revcomp_d             -> set to reverse complement database DNA sequences
--reverse_qorder        -> set to reverse ORDER of query sequences, may help clarity
--reverse_dorder        -> set to reverse ORDER of database sequences, may help clarity
--reverse_qorient       -> set to reverse ORIENTATION of query sequences which then need to be read anticlockwisely, may help clarity
--reverse_dorient       -> set to reverse ORIENTATION of database sequences which then need to be read anticlockwisely, may help clarity
--hide_orient_lights    -> set to hide orientation lights at edges of ideograms, read from green (=beginning) to red (=end)
--ribocolours2allow     -> blue, green, orange, red in a format like this (including parentheses) '(green|orange)' or '(blue)' - histograms are not affected
--tblastx               -> run 6-frame tBLASTx for DNA vs DNA
--cpus                  -> number of CPUs to use with BLAST
</pre>
