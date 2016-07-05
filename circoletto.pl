#!/usr/bin/perl 

$version              = localtime((stat($0))[9]);
$circos_compatibility = '0.69-3';

$| = 1;

use POSIX;
use Getopt::Long;
use Bio::SearchIO;
use Bio::Seq;

$randomer = int(rand(1001)) . $$;
$randomer = sprintf "%010s", $randomer;

$usage = "
# Circoletto - visualising sequence similarity with Circos
# Darzentas N.
# $version
# http://bat.infspire.org

welcome

before you run Circoletto, be sure to:
- have Circos (tested with $circos_compatibility, http://circos.ca/software/download/circos/), BLAST (tested with 2.2.25) in your path, and BioPerl (tested with 1.6.901) installed
- check / edit (in the code) the two paths to Circos and Circos tools - if we cannot find them, we'll print a warning and exit
- if you need to increase the max_sequences > 200, you also need to edit max_ideograms in Circos' housekeeping.conf

circoletto.pl 

    either
--query     or  --q     -> (path to) the queries
--database  or  --db    -> (path to) the database
    or
--blastout  or  --bl    -> (path to) the BLAST output

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

";

my $options_res = GetOptions(
    "query|q:s"                 =>  \$query,
    "database|db:s"             =>  \$database,
    "blastout|bl:s"             =>  \$blastout,
    "out_type:s"                =>  \$out_type,
    "e_value|e-value|evalue:s"  =>  \$e_value,
    "gep:s"                     =>  \$gep,
    "flt!"                      =>  \$flt,
    "best_hit!"                 =>  \$best_hit,
    "best_hit_type:s"           =>  \$best_hit_type,
    "z_by:s"                    =>  \$z_by,
    "w_hits!"                   =>  \$w_hits,
    "untangling_off|tangle!"    =>  \$untangling_off,
    "revcomp_q!"                =>  \$revcomp_q,
    "revcomp_d!"                =>  \$revcomp_d,
    "reverse_qorder!"           =>  \$reverse_qorder,
    "reverse_dorder!"           =>  \$reverse_dorder,
    "reverse_qorient!"          =>  \$reverse_qorient,
    "reverse_dorient!"          =>  \$reverse_dorient,
    "hide_orient_lights!"       =>  \$hide_orient_lights,
    "ribocolours2allow:s"       =>  \$ribocolours2allow,
    "out_size:f"                =>  \$out_size,
    "annotation:s"              =>  \$annotation,
    "score2colour:s"            =>  \$score2colour,
    "annocolour|annotate_by:s"  =>  \$annocolour,
    "invertcolour!"             =>  \$invertcolour,
    "no_labels!"	            =>  \$no_labels,
    "tblastx!"  	            =>  \$tblastx,
    "override!"  	            =>  \$override,
    "ltrphyler!"  	            =>  \$ltrphyler,
    "cpus:f"                    =>  \$cpus,
    "mhits:f"                   =>  \$mhits,
    "online!"  	                =>  \$online
    );


#############################################################
$path2circos      = '/labs/bat/software/circos-0.69-3';     #  path to Circos
$path2circostools = '/labs/bat/software/circos-tools-0.22'; #  path to Circos utilities
#############################################################
if (-e "$path2circos/bin/circos")                       { $path2circos_ok      = 1; } else { print "(!) path to Circos not OK\n"; }
if (-e "$path2circostools/tools/orderchr/bin/orderchr") { $path2circostools_ok = 1; } else { print "(!) path to Circos tools not OK\n"; }
unless ($path2circos_ok && $path2circostools_ok) { print "(!) please edit paths in circoletto.pl and try again - exiting\n"; exit; }

#if (`which blast2`   !~ /blast2/)   { print "(!) cannot find blast2 - exiting\n";   exit; }
#if (`which formatdb` !~ /formatdb/) { print "(!) cannot find formatdb - exiting\n"; exit; }
#
#if (`perl -MBio::SearchIO -e 0` ne '') { print "(!) cannot find Bio::SearchIO - exiting\n"; exit; }
#if (`perl -MBio::Seq -e 0`      ne '') { print "(!) cannot find Bio::Seq - exiting\n";      exit; }


unless ($online) { # ... i.e. offline

    unless ((defined($query) && defined($database)) || defined($blastout)) { die $usage; }
    $pwd       = '';
    $dir       = 'dir  = .';
    if ($override) {                 $factor = 50;   
    } else {                         $factor = 1; }
    $max_sequences          =  200 * $factor;
    $max_ribbons            = 1000 * $factor;
    $max_ribbons2untangle   = 100;
    $max_total_length       = 2000000000; $max_total_length_in_mb = 2000;
    $max_his_data           = 500000;

} else {

    $pwd       = '/labs/bat/www/tools/results/circoletto/';
    $dir       = 'dir = /labs/bat/www/tools/results/circoletto';
    $gep       = '-1';
    if ($override) {                 $factor = 50;   
    } else {                         $factor = 1; }
    $max_sequences          =  200 * $factor;
    $max_ribbons            = 1000 * $factor;
    $max_ribbons2untangle   = 100;
    $max_total_length       = 2000000000; $max_total_length_in_mb = 2000;
    $max_his_data           = 500000;

}

unless (defined $max_label_len) {       $max_label_len = 20; }
unless (defined $out_type) {            $out_type = 'png'; }
unless (defined $e_value) {             $e_value = '1e-10'; }
unless (defined $gep) {                 $gep = '-1'; }
unless (defined $flt) {                 $flt = 0; }
unless (defined $score2colour) {        $score2colour = 'bit'; }
unless (defined $best_hit) {            $best_hit = 0; }
unless (defined $best_hit_type) {       $best_hit_type = 'entry'; }
unless (defined $w_hits) {              $w_hits = 0; }
unless (defined $annocolour) {          $annocolour = 'scores'; }
unless (defined $invertcolour) {        $invertcolour = 0; }
unless (defined $no_labels) {           $no_labels = 0; }
unless (defined $untangling_off) {      $untangling_off = 0; }
unless (defined $revcomp_q) {           $revcomp_q = 0; }
unless (defined $revcomp_d) {           $revcomp_d = 0; }
unless (defined $reverse_qorder) {      $reverse_qorder = 0; }
unless (defined $reverse_dorder) {      $reverse_dorder = 0; }
unless (defined $reverse_qorient) {     $reverse_qorient = 0; }
unless (defined $reverse_dorient) {     $reverse_dorient = 0; }
unless (defined $hide_orient_lights) {  $hide_orient_lights = 0; }
unless (defined $out_size) {            $out_size = '1000p'; } else { $out_size .= 'p'; }
unless (defined $tblastx) {             $tblastx = 0; }
unless (defined $override) {            $override = 0; }
unless (defined $ltrphyler) {           $ltrphyler = 0; }
unless (defined $cpus) {                $cpus = 1; }
unless (defined $ribocolours2allow) {   $ribocolours2allow = "(blue|green|orange|red)"; }
unless (defined $z_by) {                $z_by = "score"; }
if ($ltrphyler && $tblastx) {           $lc_flt = '-U T'; } else { $lc_flt = ''; }

open STDERR, '>/dev/null';

#green    fully opaque
#green_a1 16% transparent
#green_a2 33% transparent
#green_a3 50% transparent
#green_a4 66% transparent
#green_a5 83% transparent
%kolours = (
'query'   , 'vvlgrey',
'database', 'dgrey',
'defdom'  , 'black'
);
%ribocolours = (
'q1'      , 'blue',
'q2'      , 'green',
'q3'      , 'orange',
'q4'      , 'red'
);
%score2colour4report = (
'bit'     , 'bitscore',
'eval'    , 'E-value',
'id'      , '% identity'
);
$greenlight = 'lgreen';
$redlight   = 'lred';

$chr_order = 'chromosomes_order = ';
if ($reverse_qorient || $reverse_dorient) { $chr2rev = 'chromosomes_reverse = '; } else { $chr2rev = ''; }

if (defined($query) && defined($database)) {

    print "(?) going through the FASTA files\n";

    #`perl -pi -e 's/\r//g' $query` unless $online;
    $flag = 0;
    open (FASTA, "$query");
    while (<FASTA>) {
        chomp;
        if (/^>/) {
            $label = (split / /, $_)[0];
# update annotation FASTA loading when you change these
            $label =~ s/^>//;
            $label =~ s/[^\w-.]/_/g;
            $label =~ s/_{1,}/./g;
            $uniq_label = substr($label,0,$max_label_len);
            while (defined($uniq_labels{$uniq_label})) {
                $randomer4label = int(rand(1001));
                $randomer4label = sprintf "%04s", $randomer4label;
                $uniq_label = substr($label,0,$max_label_len-4) . "$randomer4label"; 
            }
            $uniq_labels{$label} = $uniq_label;
            $uniq_labels{$uniq_label} = $uniq_label;
            $original_labels{$uniq_label} = $_;
            $original_labels{$uniq_label} =~ s/^>//;
            $label = $uniq_label;
            ++$query_entries{$label};
            push(@{$ordered{query}}, $label);
            $flag = 1;
        } elsif (/\w/) {
            s/\s//g;
            $sequences{$label} .= $_;
            $flag = 0;
        }
    }
    close FASTA;
    
    foreach $label (keys %query_entries) {
        if (length($sequences{$label}) > 20) {
            $seq = Bio::Seq->new();
            if(! $seq->validate_seq($sequences{$label}) ) {
                print "(!) query $label has invalid sequence - exiting\n"; exit;
            } else {
                $seq->seq($sequences{$label});
    			++$q_seq_types{$seq->alphabet};
            }
        }
    }
    if (keys(%q_seq_types) == 1) {
        foreach $type (keys %q_seq_types) {
            $q_seq_type = $type;
        }
    } else {
        print "(!) your query file apparently has no sequence label(s), or both nucleotide and amino acid sequences,\nor confusing/invalid characters, or too little sequence - exiting\n"; exit;
    }
    
    if ($flag) {                                              print "(!) your query file is incomplete (most probably) - exiting\n"; exit;
    } else {
        if (keys(%query_entries) == 0) {                      print "(!) your query file is either empty or not in right format - exiting\n"; exit;
            } elsif (keys(%query_entries) > $max_sequences) { print "(!) your query file contains too many sequences (" . keys(%query_entries) . " - we allow up to $max_sequences) - exiting\n"; exit;
        } else {                                              print "(=) " . keys(%query_entries) . " entries found in query file\n"; }
    }
    
    if ($q_seq_type eq 'dna' && $revcomp_q) { print "(?) reverse complementing query DNA sequences\n"; }
    $clean = '';
    $#non_uniq_labels = -1;
    foreach $label (sort keys %query_entries) {
        if ($q_seq_type eq 'dna' && $revcomp_q) { $clean_seq = revcomp($sequences{$label});
        } else {                                  $clean_seq = $sequences{$label}; }
                              $clean .= ">$label\n$clean_seq\n";

        if ($query_entries{$label} > 1) {
            push(@non_uniq_labels, $label);
        }
    }
    if (scalar(@non_uniq_labels) > 0) {
        print "(!) the max label length (currently $max_label_len) causes some query sequence labels\n(" . join(", ",@non_uniq_labels) . ") to be redundant... please change the first $max_label_len characters accordingly - exiting\n"; exit;
    }
    
    if ($reverse_qorder) {
        print "(?) reversing order of query ideograms\n";
        @{$ordered{query}} = reverse(@{$ordered{query}});
    }

    open (CLEAN, ">$query.clean");
    print CLEAN $clean;
    close CLEAN;

    if ($query ne $database) {

        $flag = 0;
        #`perl -pi -e 's/\r//g' $database` unless $online;
        open (FASTA, "$database");
        while (<FASTA>) {
            chomp;
            if (/^>/) {
                $label = (split / /, $_)[0];
                $label =~ s/^>//;
                $label =~ s/[^\w-.]/_/g;
                $label =~ s/_{1,}/./g;
                $uniq_label = substr($label,0,$max_label_len);
                while (defined($uniq_labels{$uniq_label})) {
                    $randomer4label = int(rand(1001));
                    $randomer4label = sprintf "%04s", $randomer4label;
                    $uniq_label = substr($label,0,$max_label_len-4) . "$randomer4label"; 
                }
                $uniq_labels{$label} = $uniq_label;
                $uniq_labels{$uniq_label} = $uniq_label;
                $original_labels{$uniq_label} = $_;
                $original_labels{$uniq_label} =~ s/^>//;
                $label = $uniq_label;
                ++$database_entries{$label};
                push(@{$ordered{database}}, $label);
                $flag = 1;
            } elsif (/\w/) {
                s/\s//g;
                unless (defined($query_entries{$label})) {
                    $sequences{$label} .= $_;
                }
                $flag = 0;
            }
        }
        close FASTA;

        foreach $label (keys %database_entries) {
            if (length($sequences{$label}) > 20) {
                $seq = Bio::Seq->new();
                if(! $seq->validate_seq($sequences{$label}) ) {
                    print "(!) database entry $label has invalid sequence - exiting\n"; exit;
                } else {
                    $seq->seq($sequences{$label});
                    ++$d_seq_types{$seq->alphabet};
                }
            }
        }
        if (keys(%d_seq_types) == 1) {
            foreach $type (keys %d_seq_types) {
                $d_seq_type = $type;
            }
        } else {
            print "(!) your database file apparently has no sequence label(s), or both nucleotide and amino acid sequences,\nor confusing/invalid characters, or too little sequence - exiting\n"; exit;
        }

        if ($flag) {                                             print "(!) your database file is incomplete (most probably)\n";
        } else {
            if (keys(%database_entries) == 0) {                  print "(!) your database file is either empty or not in right format - exiting\n"; exit;
            } elsif (keys(%database_entries) > $max_sequences) { print "(!) your database file contains too many sequences (" . keys(%database_entries) . " - we allow up to $max_sequences) - exiting\n"; exit;
            } else {                                             print "(=) " . keys(%database_entries) . " entries found in database file\n"; }
        }

        if ($d_seq_type eq 'dna' && $revcomp_d) { print "(?) reverse complementing database DNA sequences\n"; }
        $clean = '';
        $#non_uniq_labels = -1;
        foreach $label (sort keys %database_entries) {
            if ($d_seq_type eq 'dna' && $revcomp_d) { $clean_seq = revcomp($sequences{$label});
            } else {                                  $clean_seq = $sequences{$label}; }
                                  $clean .= ">$label\n$clean_seq\n";

            if ($database_entries{$label} > 1) {
                push(@non_uniq_labels, $label);
            }
        }
        if (scalar(@non_uniq_labels) > 0) {                      print "(!) the max label length (currently $max_label_len) causes some database sequence labels\n(" . join(", ",@non_uniq_labels) . ") to be redundant... please change the first $max_label_len characters accordingly - exiting\n"; exit; }

        if ($reverse_dorder) {
            print "(?) reversing order of database ideograms\n";
            @{$ordered{database}} = reverse(@{$ordered{database}});
        }
    
        open (CLEAN, ">$database.clean");
        print CLEAN $clean;
        close CLEAN;

    } else {
        print "(?) query and database seem the same (filename and/or content), we assume you're running an all against all\n";
        $d_seq_type = $q_seq_type;
    }

    if (keys(%sequences) > $max_sequences) {
        print "(!) you have too many sequences in total (" . keys(%sequences) . " - we allow up to $max_sequences) - exiting\n"; exit;
    }
    $max_hits_per_query = sprintf "%.0f", $max_ribbons / keys(%sequences);
    $lensum = 0;
    foreach $label (keys %sequences){
        $lengths{$label} = length($sequences{$label});
        $lensum += length($sequences{$label});
    }
    %sequences = ();


    if ($q_seq_type eq 'dna' && $d_seq_type eq 'dna') {
        $seq_type4formatdb = 'F';
        $database4formatdb2check = "$database.clean.nsq";
        if ($tblastx) {
            if ($lensum > $max_total_length/200 && !$tblastx) {
                print "(!) running tBLASTx with your sequences may overload our server,\neither load less data (<".($max_total_length_in_mb/200)."Mb) or tBLASTx-it-yourself and come back - exiting\n"; exit;
            } elsif ($lensum > $max_total_length/500 && !$tblastx) {
                print "(!) running tBLASTx with only one CPU due to your largish dataset - may take a while\n";
                $cpus = 1;
            }
            $program = 'tblastx';
        } else {
            $program = 'blastn';
        }
    } elsif ($q_seq_type eq 'protein' && $d_seq_type eq 'protein') {
        $seq_type4formatdb = 'T';
        $database4formatdb2check = "$database.clean.psq";
        $program = 'blastp';
    } elsif ($q_seq_type eq 'dna' && $d_seq_type eq 'protein') {
        $seq_type4formatdb = 'T';
        $database4formatdb2check = "$database.clean.psq";
        $program = 'blastx';
    } elsif ($q_seq_type eq 'protein' && $d_seq_type eq 'dna') {
        $seq_type4formatdb = 'F';
        $database4formatdb2check = "$database.clean.nsq";
        $program = 'tblastn';
    }
    print "(?) formatdb is running\n";
    my $formatdb = `nice formatdb -i $database.clean -p $seq_type4formatdb -l $database.clean.formatdb.log`;
    $status = $? >> 8; unless ($status==0) { print "(!) there was an error running formatdb on your database - exiting\n"; exit; }
    if ($flt) {$flt = 'T';
    } else {   $flt = 'F'; }
    $blastout = "$pwd" . "cl$randomer.blasted";
    if ($best_hit) {
        $v4blast = 1;
        $b4blast = 1;
    } else {
        if (defined($mhits)) {
            $v4blast = $mhits;
            $b4blast = $mhits;
        } else {
            $v4blast = $max_sequences;
            $b4blast = $max_sequences;
        }
    }
    print "(?) $program is running with -F $flt -e $e_value -E $gep -v $v4blast -b $b4blast $lc_flt\n";
    my $blast      = `nice blastall -p $program -i $query.clean -d $database.clean -F $flt -e $e_value -E $gep -v $v4blast -b $b4blast -a $cpus $lc_flt > $blastout`;
    $status = $? >> 8; unless ($status==0) { print "(!) there was an error running $program with your files - exiting\n"; exit; }

}

print "(?) going through the BLAST output\n";
#`perl -pi -e 's/\r//g' $blastout` unless $online;
$grep4queries = `grep -c '^Query=' $blastout`;
chomp $grep4queries;
unless ($grep4queries =~ /\d/ && $grep4queries > 0) { print "(!) could not find any queries, or BLAST output is in wrong format - exiting\n"; exit; }
$max_hits_per_query = sprintf "%.0f", $max_ribbons / $grep4queries;
%hsp = ();
my $in = new Bio::SearchIO(-format => 'blast', 
                           -file   => "$blastout");
while( my $result = $in->next_result ) {
    $blastout_query = $result->query_name;
    $uniq_label = substr($blastout_query,0,$max_label_len);
    if (defined($uniq_labels{$uniq_label})) {
        $blastout_query = $uniq_labels{$uniq_label};
    } else {
        $blastout_query =~ s/[^\w-.]/_/g;
        $blastout_query =~ s/_{1,}/./g;
        $uniq_label = substr($blastout_query,0,$max_label_len);
        while (defined($uniq_labels{$uniq_label})) {
            $randomer4label = int(rand(1001));
            $randomer4label = sprintf "%04s", $randomer4label;
            $uniq_label = substr($blastout_query,0,$max_label_len-4) . "$randomer4label"; 
        }
        $uniq_labels{$blastout_query} = $uniq_label;
        $uniq_labels{$uniq_label} = $uniq_label;
        $original_labels{$blastout_query} = $result->query_name;
        $blastout_query = $uniq_label;
    }
    if ($blastout_query =~ /\w/) {
        $lengths{$blastout_query} = $result->query_length;
        unless (defined($query_entries{$blastout_query})) {
            push(@{$ordered{query}}, $blastout_query);
        }
        $query_entries{$blastout_query} = 1;
        while( my $hit = $result->next_hit ) {
            $blastout_hit = $hit->name;
            $uniq_label = substr($blastout_hit,0,$max_label_len);
            if (defined($uniq_labels{$uniq_label})) {
                $blastout_hit = $uniq_labels{$uniq_label};
            } else {
                $blastout_hit =~ s/[^\w-.]/_/g;
                $blastout_hit =~ s/_{1,}/./g;
                $uniq_label = substr($blastout_hit,0,$max_label_len);
                while (defined($uniq_labels{$uniq_label})) {
                    $randomer4label = int(rand(1001));
                    $randomer4label = sprintf "%04s", $randomer4label;
                    $uniq_label = substr($blastout_hit,0,$max_label_len-4) . "$randomer4label"; 
                }
                $uniq_labels{$blastout_hit} = $uniq_label;
                $uniq_labels{$uniq_label} = $uniq_label;
                $original_labels{$blastout_hit} = $hit->name;
                $blastout_hit = $uniq_label;
            }
            if ($blastout_hit =~ /\w/) {
                $lengths{$blastout_hit} = $hit->length;
                unless (defined($database_entries{$blastout_hit})) {
                    push(@{$ordered{database}}, $blastout_hit);
                }
                $database_entries{$blastout_hit} = 1;
                while( my $hithsp = $hit->next_hsp ) {
                    if ($blastout_query eq $blastout_hit && $hithsp->hsp_length/$lengths{$blastout_query} <= 0.5 ) { $go = 1;
                    } elsif ($blastout_query ne $blastout_hit) {                                                     $go = 1;
                    } else {                                                                                         $go = 0; }
                    if ($go) {
                        if ($score2colour eq 'eval') {
                            if ($hithsp->evalue == 0) {
                                $score = 181;
                            } else {
                                $conv2e = sprintf "%.0e", $hithsp->evalue;
                                @split = split("e-", $conv2e);
                                $score = "$split[1].$split[0]";
                            }
                        } elsif ($score2colour eq 'bit') { $score = $hithsp->bits;
                        } elsif ($score2colour eq 'id') {  $score = $hithsp->percent_identity;
                        } else {                           $score = $hithsp->bits; }
                        $qstart = $hithsp->start('query');
                        $qend = $hithsp->end('query');
                        $qstrand = $hithsp->strand('query');
                        $hstrand = $hithsp->strand('hit');
                        if ($hstrand == 0 || $hstrand == 1) {
                            $hstart = $hithsp->start('hit');
                            $hend = $hithsp->end('hit');
                        } elsif ($hstrand == -1) {
                            $hend = $hithsp->start('hit');
                            $hstart = $hithsp->end('hit');
                        }
                        $mem{all}{$blastout_query}{$score}{$blastout_hit}{"$qstart $qend"}{"$hstart $hend"} = $hithsp->hsp_length;
                        $entries_per_set{all}{$blastout_query} = 1;
                        $entries_per_set{all}{$blastout_hit} = 1;
                        $alnlens{all}{$hithsp->hsp_length} = 1;
                        $scores{all}{$score} += $hithsp->hsp_length;
                        ++$hsp{all};
                        ++$hsp_per_query{$blastout_query};
                        if ($hsp_per_query{$blastout_query} <= $max_hits_per_query) {
                            $mem{max}{$blastout_query}{$score}{$blastout_hit}{"$qstart $qend"}{"$hstart $hend"} = $hithsp->hsp_length;
                            $entries_per_set{max}{$blastout_query} = 1;
                            $entries_per_set{max}{$blastout_hit} = 1;
                            $alnlens{max}{$hithsp->hsp_length} = 1;
                            $scores{max}{$score} += $hithsp->hsp_length;
                            ++$hsp{max};
                        }
                    }
                }
            }
        }
    }
}
unless (defined($query) && defined($database)) {
    if (keys(%query_entries) == 0) {                     print "(!) could not find any queries, or BLAST output is in wrong format - exiting\n"; exit;
    } elsif (keys(%query_entries) > $max_sequences) {    print "(!) there are too many queries (" . keys(%query_entries) . " - we allow up to $max_sequences) - exiting\n"; exit;
    } else {                                             print "(=) " . keys(%query_entries) . " queries found\n"; }

    if (keys(%database_entries) == 0) {                  print "(!) could not find any database entries, or BLAST output is in wrong format - exiting\n"; exit;
    } elsif (keys(%database_entries) > $max_sequences) { print "(!) there are too many database entries (" . keys(%database_entries) . " - we allow up to $max_sequences) - exiting\n"; exit;
    } else {                                             print "(=) " . keys(%database_entries) . " database entries found\n"; }

    if (keys(%lengths) > $max_sequences) {               print "(!) you have too many entries in total (" . keys(%lengths) . " - we allow up to $max_sequences) - exiting\n"; exit; }
    
    if ($reverse_qorder) {
        print "(?) reversing order of query ideograms\n";
        @{$ordered{query}} = reverse(@{$ordered{query}});
    }
    if ($reverse_dorder) {
        print "(?) reversing order of database ideograms\n";
        @{$ordered{database}} = reverse(@{$ordered{database}});
    }
}

if ($hsp{all} == 0) {
    print "(!) no hits found so maybe you can try different datasets or a more relaxed E-value - exiting\n"; exit;
} elsif ($hsp{all} > $max_ribbons) {
    print "(!) $hsp{all} local alignments are too many (we allow up to $max_ribbons for clarity),\n\tso please consider stricter E-value or smaller input datasets\n";
    print "(?) in the meantime, we are switching to $max_hits_per_query hits per query\n";
    if ($hsp{max} > $max_ribbons) {
        print "(!) $hsp{max} local alignments are still too many (we allow up to $max_ribbons) - exiting\n"; exit;
    } else {
        $set2consider = 'max';
    }
} else {
    $set2consider = 'all';
}

$lensum2show = 0;
foreach $label (keys %{$entries_per_set{$set2consider}}) { $lensum2show += $lengths{$label}; }
if ($lensum2show > $max_total_length) { print "(!) the total length of your sequences to show is more than $max_total_length_in_mb megabases (currently $lensum2show bp) - exiting\n"; exit; }
$orient_light_width = int($lensum2show * 0.004);

if (defined($annotation)) {
    print "(?) loading annotation\n";
    open (ANNOTATION, "$annotation");
    while (<ANNOTATION>) {
        if (!/^\#/ && /\w/) {
            chomp;
            @tabs = (split /\s+/);
            $label = shift(@tabs);
            $label = (split / /, $_)[0];
# always update from above
            $label =~ s/^>//;
            $label =~ s/[^\w-.]/_/g;
            $label =~ s/_{1,}/./g;
            if (defined($uniq_labels{$label})) {
                $label = $uniq_labels{$label};
            } else {
                $label = substr($label,0,$max_label_len);
            }
            if (defined($lengths{$label})) {
                $kolour = shift(@tabs);
                if ($kolour ne '-') {
                    $annotations{$label}{ideo_colour} = $kolour;
                }
                foreach $tab (@tabs) {
                    if ($tab =~ /:/) {
                        $domcol = (split /:/, $tab)[1];
                        $tab = (split /:/, $tab)[0];
                    } else {
                        $domcol = $kolours{'defdom'};
                    }
                    $domfrom = (split /-/, $tab)[0];
                    if ($domfrom < 0) {
                        $domfrom = 0;
                    }
                    $domto = (split /-/, $tab)[1];
                    if ($domto > $lengths{$label}) {
                        $domto = $lengths{$label};
                    }
                    if ($domfrom < $domto) {
                        $annotations{$label}{domains}{$domfrom}{to} = $domto;
                        $annotations{$label}{domains}{$domfrom}{col} = $domcol;
                    }
                }
            }
        }
    }
    close ANNOTATION;
    if (keys(%annotations) > 0) { print "(=) annotation loaded for " . keys(%annotations) . " entries\n";
    } else {                      print "(!) no annotation loaded although you provided a file, please check\n"; }
}

$uid = 0;
foreach $entry (sort {$b<=>$a} keys %{$alnlens{$set2consider}}) { $maxalnlen = $entry; last; }
foreach $score (sort {$b<=>$a} keys %{$scores{$set2consider}}) {  $maxscore  = $score; last; }
$cold = 0; $warm = 0; $hot = 0;
foreach $score (keys %{$scores{$set2consider}}) {
    $scoreratio = $score / $maxscore;
    if (    $scoreratio <= 0.5) { $cold += $scores{$set2consider}{$score};
    } else {
        if ($scoreratio > 0.75) { $hot  += $scores{$set2consider}{$score}; }
                                  $warm += $scores{$set2consider}{$score};
    }
}
print "(?) creating ribbons from $hsp{$set2consider} local alignments\n";
if ($annocolour ne 'scores' && $invertcolour) { print "(!) cannot colour ribbons by both invertion and ideogram/domain/rainbow colours - exiting\n"; exit;
} elsif ($annocolour eq 'query') {              print "(?) colouring ribbons by query ideogram/domain colours and $score2colour4report{$score2colour}\n";
} elsif ($annocolour =~ /query_rainbow/) {      print "(?) colouring ribbons by query rainbow colours and $score2colour4report{$score2colour}\n";
} elsif ($annocolour eq 'database') {           print "(?) colouring ribbons by database ideogram/domain colours and $score2colour4report{$score2colour}\n";
} elsif ($annocolour =~ /database_rainbow/) {   print "(?) colouring ribbons by database rainbow colours and $score2colour4report{$score2colour}\n";
} elsif ($invertcolour) {                       print "(?) colouring ribbons by invertion and $score2colour4report{$score2colour}\n";
} else {                                        print "(?) colouring ribbons by $score2colour4report{$score2colour}\n"; }
if ($z_by eq 'score') {                         print "(?) depth-ordering ribbons by score, highest-scoring at the top\n";
} elsif ($z_by eq 'score_rev') {                print "(?) depth-ordering ribbons by reverse score, lowest-scoring at the top\n";
} elsif ($z_by eq 'alnlen') {                   print "(?) depth-ordering ribbons by alignment length, longest at the top\n";
} else {                                        print "(?) depth-ordering ribbons by reverse alignment length, shortest at the top\n"; }
$hiscolours2allow = "(blue|green|orange|red)";
                                                print "(?) checking histogram data\n";
if ($cold > $max_his_data) {
    if ($warm > $max_his_data) {
        if ($hot > $max_his_data) {             print "(!) too much histogram data - disabling\n";                        $hiscolours2allow = 'black';
        } else {                                print "(!) too much histogram data, will only consider red ribbons\n";    $hiscolours2allow = 'red'; }
    } else {                                    print "(!) too much histogram data, will only consider 'warm' ribbons\n"; $hiscolours2allow = '(orange|red)'; }
}
unless ($ribocolours2allow eq "(blue|green|orange|red)") { print "(?) showing only $ribocolours2allow ribbons, histograms are not affected\n"; }
open (LINKS, ">$blastout.links") || die "Cannot create $blastout.links";
foreach $query (keys %{$mem{$set2consider}}) {
    $entries_w_hits{$query} = 1;
    $per_query = 0;
    %best_hit_entries = ();
    foreach $score (sort {$b<=>$a} keys %{$mem{$set2consider}{$query}}) {
                 $scoreratio = $score / $maxscore;
        if (     $scoreratio <= 0.25) {                        $colour = $ribocolours{q1};
        } elsif ($scoreratio >  0.25 && $scoreratio <= 0.5) {  $colour = $ribocolours{q2};
        } elsif ($scoreratio >  0.5  && $scoreratio <= 0.75) { $colour = $ribocolours{q3};
        } else {                                               $colour = $ribocolours{q4}; }
                                                          $best_colour = $out_type eq 'png' ? $colour . "_a1" : "black_a1";
        foreach $database (keys %{$mem{$set2consider}{$query}{$score}}) {
            if (($best_hit && $best_hit_type eq 'entry' && defined($best_hit_entries{$database})) || keys(%best_hit_entries)==0 || !$best_hit) {
                $best_hit_entries{$database} = 1;
                $entries_w_hits{$database} = 1;
                foreach $qaln (keys %{$mem{$set2consider}{$query}{$score}{$database}}) {
                    $a_from = (split / /, $qaln)[0];
                    $a_to   = (split / /, $qaln)[1];
                    if ($per_query == 0) { # i.e. best score
                        if ($annocolour ne 'scores' || $invertcolour) { $stroker = ",stroke_color=$colour"."_a1".",stroke_thickness=2";
                        } else {                                        $stroker = ",stroke_color=$best_colour,stroke_thickness=2"; }
                    } else {
                        if ($annocolour ne 'scores' || $invertcolour) { $stroker = ",stroke_color=$colour"."_a2".",stroke_thickness=1";
                        } else {                                        $stroker = "";
                            #$a_ratio = abs($a_to - $a_from) / $lensum2show;
                            #if ($a_ratio < 0.005) {                     $stroker = ',stroke_thickness=0';
                            #} else {                                    $stroker = ",stroke_color=$ribocolours{stroke},stroke_thickness=1"; }
                        }
                    }
                    foreach $daln (keys %{$mem{$set2consider}{$query}{$score}{$database}{$qaln}}) {
                        $b_from = (split / /, $daln)[0];
                        $b_to   = (split / /, $daln)[1];
                        if ($z_by =~ /score/) {
                            if ($z_by eq 'score') {  $z = $score;
                            } else {                 $z = $maxscore - $score; }
                        } else {
                            if ($z_by eq 'alnlen') { $z = $mem{$set2consider}{$query}{$score}{$database}{$qaln}{$daln};
                            } else {                 $z = $maxalnlen - $mem{$set2consider}{$query}{$score}{$database}{$qaln}{$daln}; }
                        }
                        use bignum;
                        $z = $z + 0;
                        no bignum;
                        $ribocolour = $colour . "_a3";
                        if ($annocolour =~ /query/) {
                            if (defined($annotations{$query}{ideo_colour})) { $ribocolour = $annotations{$query}{ideo_colour} . "_a3";
                            } else {                                          $ribocolour = $kolours{query} . "_a3"; }
                            foreach $dom_from (sort {$a<=>$b} keys %{$annotations{$query}{domains}}) {
                                $buffer = (abs($dom_from - $annotations{$query}{domains}{$dom_from}{to}) + 1) * 0.25;
                                if ($b_from >= ($dom_from - $buffer) && $b_to > $dom_from && $b_from < $annotations{$query}{domains}{$dom_from}{to} && $b_to <= ($annotations{$query}{domains}{$dom_from}{to} + $buffer)) {
                                    $ribocolour = $annotations{$query}{domains}{$dom_from}{col} . "_a3";
                                    last;
                                }
                            }                            
                        } elsif ($annocolour =~ /database/) {
                            if (defined($annotations{$database}{ideo_colour})) { $ribocolour = $annotations{$database}{ideo_colour} . "_a3";
                            } else {                                             $ribocolour = $kolours{database} . "_a3"; }
                            foreach $dom_from (sort {$a<=>$b} keys %{$annotations{$database}{domains}}) {
                                $buffer = (abs($dom_from - $annotations{$database}{domains}{$dom_from}{to}) + 1) * 0.25;
                                if ($b_from >= ($dom_from - $buffer) && $b_to > $dom_from && $b_from < $annotations{$database}{domains}{$dom_from}{to} && $b_to <= ($annotations{$database}{domains}{$dom_from}{to} + $buffer)) {
                                    $ribocolour = $annotations{$database}{domains}{$dom_from}{col} . "_a3";
                                    last;
                                }
                            }                            
                        }
                        if ($colour =~ /$hiscolours2allow/) {
                            if ($a_from > $a_to) { for ($i=$a_to;$i<=$a_from;$i++) { ++$histogram{$query}{$i}{$colour}; }
                            } else {               for ($i=$a_from;$i<=$a_to;$i++) { ++$histogram{$query}{$i}{$colour}; }}
                        }
                        if ($b_from > $b_to) {
                            $inverter = ',twist=1';
                            if ($invertcolour) { $ribocolour = 'lime_a3'; }
                            $dblink = "$database $b_to $b_from";
                            if ($colour =~ /$hiscolours2allow/) { for ($i=$b_to;$i<=$b_from;$i++) { ++$histogram{$database}{$i}{$colour}; }}
                        } else {
                            $inverter = ',flat=1';
                            if ($invertcolour) { $ribocolour = 'black_a3'; }
                            $dblink = "$database $b_from $b_to";
                            if ($colour =~ /$hiscolours2allow/) { for ($i=$b_from;$i<=$b_to;$i++) { ++$histogram{$database}{$i}{$colour}; }}
                        }
                        if ($ribocolour =~ /$ribocolours2allow/ || $stroker =~ /$ribocolours2allow/) {
                            print LINKS "$query $qaln $dblink color=$ribocolour,z=$z,radius=0.98r$stroker$inverter\n";
                            ++$uid;
                        }
                        ++$per_query;
                    }
                }
            }
        }
        if ($best_hit && $best_hit_type eq 'local') { last; }
    }
}
close LINKS;
%mem = ();

if ($hide_orient_lights) { print "(?) hiding orientation lights\n"; }

if ($reverse_qorient) {    print "(?) reversing orientation of query ideograms\n"; }
open (KARYOTYPE, ">$blastout.karyotype") || die "Cannot create $blastout.karyotype";
foreach $entry (@{$ordered{query}}) {
    if (($w_hits && defined($entries_w_hits{$entry})) || !$w_hits) {
        if (defined($lengths{$entry}) && $lengths{$entry} > 0 && $entry =~ /\w/) {
            $chr_order .= "$entry,";
            if (defined($annotations{$entry}{ideo_colour})) { print KARYOTYPE "chr - $entry $entry 0 $lengths{$entry} $annotations{$entry}{ideo_colour}\n";
            } else {                                          print KARYOTYPE "chr - $entry $entry 0 $lengths{$entry} $kolours{query}\n"; }
            $ultimately_shown{$entry} = 1;
            if (defined($annotations{$entry}{domains})) {
                $domid = 1;
                foreach $from (sort {$a<=>$b} keys %{$annotations{$entry}{domains}}) {
                    print KARYOTYPE "band $entry dom$domid dom$domid $from $annotations{$entry}{domains}{$from}{to} $annotations{$entry}{domains}{$from}{col}\n";
                    ++$domid;
                }
            }
            if ($reverse_qorient) { $chr2rev .= "$entry,"; }
            unless ($hide_orient_lights) {
                if ($orient_light_width >= $lengths{$entry}/2 || $orient_light_width == 0) { $orient_light_width2use = int($lengths{$entry}/2);
                } else {                                                                     $orient_light_width2use = $orient_light_width; }
                print KARYOTYPE "band $entry beg beg 0 $orient_light_width2use $greenlight\n";
                print KARYOTYPE "band $entry end end ".($lengths{$entry}-$orient_light_width2use)." $lengths{$entry} $redlight\n";
            }
        } else {print "(!) a query entry has been problematic - ignoring\n"; }
    }
}

if ($reverse_dorient) { print "(?) reversing orientation of database ideograms\n"; }
$chr_radius = 'chromosomes_radius = '; #hs1:0.8r;a:0.9r;d:0.8r
foreach $entry (@{$ordered{database}}) {
    if (($w_hits && defined($entries_w_hits{$entry})) || !$w_hits) {
        if (defined($lengths{$entry}) && $lengths{$entry} > 0 && $entry =~ /\w/) {
            unless (defined($query_entries{$entry})) {
                $chr_order  .= "$entry,";
                $chr_radius .= "$entry:0.92r;";
                if (defined($annotations{$entry}{ideo_colour})) { print KARYOTYPE "chr - $entry $entry 0 $lengths{$entry} $annotations{$entry}{ideo_colour}\n";
                } else {                                          print KARYOTYPE "chr - $entry $entry 0 $lengths{$entry} $kolours{database}\n"; }
                $ultimately_shown{$entry} = 1;
                if (defined($annotations{$entry}{domains})) {
                    $domid = 1;
                    foreach $from (sort {$a<=>$b} keys %{$annotations{$entry}{domains}}) {
                        print KARYOTYPE "band $entry dom$domid dom$domid $from $annotations{$entry}{domains}{$from}{to} $annotations{$entry}{domains}{$from}{col}\n";
                        ++$domid;
                    }
                }
                if ($reverse_dorient) { $chr2rev .= "$entry,"; }
                unless ($hide_orient_lights) {
                    if ($orient_light_width >= $lengths{$entry}/2 || $orient_light_width == 0) { $orient_light_width2use = int($lengths{$entry}/2);
                    } else {                                                                     $orient_light_width2use = $orient_light_width; }
                    print KARYOTYPE "band $entry beg beg 0 $orient_light_width2use $greenlight\n";
                    print KARYOTYPE "band $entry end end ".($lengths{$entry}-$orient_light_width2use)." $lengths{$entry} $redlight\n";
                }
            }
        } else { print "(!) a database entry has been problematic - ignoring\n"; }
    }
}
chop $chr_order;
chop $chr_radius;
chop $chr2rev;
close KARYOTYPE;

if ($w_hits) {
    $chr = 'chromosomes = ';
    print "(?) only " . keys(%entries_w_hits) . " entries with hits will be shown\n";
    foreach $entry (sort keys %entries_w_hits) { $chr .= "$entry;"; } chop $chr;
} else {                                         $chr = 'chromosomes_display_default = yes'; }

if ($best_hit) {
    if ($best_hit_type eq 'entry') { print "(?) only $uid best local alignments will be shown (= all local alignments of each best hit)\n";
    } else {                         print "(?) only $uid best local alignments will be shown (= single best local alignment for each best hit)\n"; }
}

open (ORILABELS, ">$blastout.original_labels") || die "Cannot create $blastout.original_labels";
$orilabels = '';
foreach $label (sort keys %original_labels) {
    if (defined($ultimately_shown{$label})) {
        if ($original_labels{$label} ne $label) { $orilabels .= "$original_labels{$label}\t$label\n"; }
    }
}
if ($orilabels =~ /\w/) { print ORILABELS "# original and Circoletto, tab-delimited (which might not be apparent if original label has whitespace)\n$orilabels"; }
close ORILABELS;

print "(?) creating histogram\n" if %histogram;
@sorted_colours = (
'red',
'orange',
'green',
'blue',
);
$max4his = 0;
foreach $label (keys %histogram) {
    foreach $i (keys %{$histogram{$label}}) {
        $tmp = '';
        $sum = 0;
        foreach $colour (@sorted_colours[0..$#sorted_colours]) {
            if (!defined($histogram{$label}{$i}{$colour})) { $histogram{$label}{$i}{$colour} = 0; }
            $tmp .= "$histogram{$label}{$i}{$colour}.0,";
            $sum +=  $histogram{$label}{$i}{$colour};
        }
        chop $tmp;
        if ($tmp =~ /\d/) { $hismem{$label}{$tmp}{$i} = 1; }
        if ($max4his <= $sum) { $max4his = $sum; }
    }
}
open (HIS, ">$blastout.his") || die "Cannot create $blastout.his";
foreach $label (sort keys %hismem) {
    foreach $numbers (keys %{$hismem{$label}}) {
        $from = 'na';
        $prev = 'na';
        foreach $coord (sort {$a<=>$b} keys %{$hismem{$label}{$numbers}}) {
            if ($from eq 'na') { $from = $coord; }
            if ($prev ne 'na' && ($coord > ($prev + 1) || $coord < ($prev - 1))) {
                print HIS "$label $from $prev $numbers\n";
                $from = $coord;
            }
            $prev = $coord;
        }
        print HIS "$label $from $prev $numbers\n";
    }
}
close HIS;
%his_mem = ();
$axis_thickness = 1;
$axis_spacing   = int($max4his / 4);
if ($axis_spacing == 0) {
    $axis_thickness = 0;
    $axis_spacing   = 1000;
}

unless ($untangling_off) {
    if ($reverse_qorder || $reverse_dorder) { print "(!) you have selected to reverse ideogram order, skipping untangling the $uid ribbons\n";
    } else {
        if (keys(%lengths) <= 2) {            print "(!) skipping untangling the $uid ribbons for less than 3 sequences\n";
        } elsif ($uid <= $max_ribbons2untangle) {
            print "(?) untangling the $uid ribbons\n";
            $untangle = `nice perl $path2circostools/tools/orderchr/bin/orderchr -links $blastout.links -karyotype $blastout.karyotype > $blastout.chr_order`;
            open (ORDER, "$blastout.chr_order") || die "Cannot read $blastout.chr_order";
            while (<ORDER>) {
                if (/chromosomes_order/) {
                    chomp;
                    $chr_order = $_;
                }
            }
            close ORDER;
        } else { print "(!) $uid ribbons will take too long to untangle (we allow up to $max_ribbons2untangle) - skipping\n"; }
    }
} else {         print "(?) untangling of ribbons has been switched off\n"; }


if ($annocolour =~ /rainbow/) {
    if ($annocolour =~ /grey/)  { $rainbow_palette = 'grey'; } else { $rainbow_palette = 'colour'; }
    if ($annocolour =~ /query/) { $rainbow_on = 'query';     } else { $rainbow_on = 'database'; }
    print "(?) drawing a $rainbow_palette rainbow based on the $rainbow_on\n";
    $rainbow_length = 0;
    @split_chr = (split /,/, (split / = /,$chr_order)[1]);
    foreach $chr (@split_chr) {
        if ($rainbow_on eq 'query' && $query_entries{$chr} || $rainbow_on eq 'database' && $database_entries{$chr}) {
            $rainbow_transl{$chr} += $rainbow_length;
            $rainbow_length       += $lengths{$chr};
        }
    }
    open (LINKS, "$blastout.links") || die "Cannot read $blastout.links";
    while (<LINKS>) {
        chomp;
        @split_link = (split /\s/);
        if (     $rainbow_on eq 'query'    && $query_entries{$split_link[0]})    { $rainbow_colour = ceil( (($rainbow_transl{$split_link[0]} + ($split_link[1]+$split_link[2])/2) / $rainbow_length) / (1/7) );
        } elsif ($rainbow_on eq 'database' && $database_entries{$split_link[3]}) { $rainbow_colour = ceil( (($rainbow_transl{$split_link[3]} + ($split_link[4]+$split_link[5])/2) / $rainbow_length) / (1/7) ); }
        $rainbow_colour = "$rainbow_palette-rainbow-".$rainbow_colour.'_a2';
        s/color=[^,]+,/color=$rainbow_colour,/;
        $rainbow_links .= "$_\n";
    }
    close LINKS;
    open (LINKS, ">$blastout.links") || die "Cannot create $blastout.links";
    print LINKS $rainbow_links;
    close LINKS;
}

if ($no_labels) {
    print "(?) labels have been switched off\n";
	$show_label = "no";
} else {
    $show_label = "yes";
    $label_size = 11;
    if (      $out_size eq '500p')  { $label_size += -1;
    } elsif ( $out_size eq '1000p') { $label_size +=  1;
    } elsif ( $out_size eq '2000p') { $label_size +=  2; }
    if ($out_type eq 'svg') {         $label_size +=  1; }
    $label_size .= 'p';
}

@blastreport2split = (split '/',$blastout);
$cleanblastreport = pop(@blastreport2split);
$record_limit = $max_ribbons * 2;
open (CONF, ">$blastout.conf") || die "Cannot create $blastout.conf";
print CONF "
<<include etc/housekeeping.conf>>
<<include etc/colors_fonts_patterns.conf>>

<colors>
red                 = 247, 42, 66
green               = 51, 204, 94
blue                = 54, 116, 217
orange              = 255, 136, 0
lime                = 186, 255, 0

#colour-rainbow-1   = 248, 12, 18
#colour-rainbow-2   = 238, 17, 0
#colour-rainbow-3   = 255, 51, 17
#colour-rainbow-4   = 255, 68, 34
#colour-rainbow-5   = 255, 102, 68
#colour-rainbow-6   = 255, 153, 51
#colour-rainbow-7   = 254, 174, 45
#colour-rainbow-8   = 204, 187, 51
#colour-rainbow-9   = 208, 195, 16
#colour-rainbow-10  = 170, 204, 34
#colour-rainbow-11  = 105, 208, 37
#colour-rainbow-12  = 34, 204, 170
#colour-rainbow-13  = 18, 189, 185
#colour-rainbow-14  = 17, 170, 187
#colour-rainbow-15  = 68, 68, 221
#colour-rainbow-16  = 51, 17, 187
#colour-rainbow-17  = 59, 12, 189
#colour-rainbow-18  = 68, 34, 153

# Red web color Hex#FF0000
# Orange color wheel Orange Hex#FF7F00
# Yellow web color Hex#FFFF00
# Green X11 Electric Green HTML/CSS “Lime” Color wheel green Hex#00FF00
# Blue web color Hex#0000FF
# Indigo Electric Indigo Hex#4B0082
# Violet Electric Violet Hex#8B00FF
colour-rainbow-1    = 255, 0, 0
colour-rainbow-2    = 255, 127, 0
colour-rainbow-3    = 255, 255, 0
colour-rainbow-4    = 0, 255, 0
colour-rainbow-5    = 0, 0, 255
colour-rainbow-6    = 75, 0, 130
colour-rainbow-7    = 143, 0, 255

grey-rainbow-1      = 230, 230, 230
grey-rainbow-2      = 200, 200, 200
grey-rainbow-3      = 170, 170, 170
grey-rainbow-4      = 140, 140, 140
grey-rainbow-5      = 110, 110, 110
grey-rainbow-6      = 80, 80, 80 
grey-rainbow-7      = 50, 50, 50 
</colors>

<ideogram>
<spacing>
default             = 0.006r
break               = 10u
axis_break_at_edge  = no
axis_break          = no
axis_break_style    = 1
</spacing>
thickness           = 12p
stroke_thickness    = 1
stroke_color        = black
fill                = yes
fill_color          = lgrey
radius              = 0.66r
show_label          = $show_label
label_with_tag      = yes
label_font          = condensed
label_color         = grey
label_radius        = dims(ideogram,radius) + 0.104r
label_size          = $label_size
band_stroke_thickness = 0
show_bands          = yes
fill_bands          = yes
</ideogram>

show_ticks          = yes
show_tick_labels    = no
<ticks>
radius              = dims(ideogram,radius_outer)
multiplier          = 1e-6
<tick>
spacing             = 100u
rspacing            = 0.1
spacing_type        = relative
size                = 5p
thickness           = 1p
color               = vvvvdgrey
show_label          = no
label_size          = 10p
label_offset        = 5p
format              = %d
</tick>
</ticks>

karyotype           = $blastout.karyotype

<image>
$dir
file                = $cleanblastreport.$out_type
radius              = $out_size
background          = white
angle_offset        = -90
24bit               = yes
auto_alpha_colors   = yes
auto_alpha_steps    = 5
</image>

chromosomes_units   = 1
$chr
$chr_order
$chr_radius
$chr2rev

<links>
ribbon              = yes
<link>
show                = yes
file                = $blastout.links
record_limit        = $record_limit
</link>
</links>

<plots>
<plot>
type                = histogram
file                = $blastout.his
extend_bin          = no
color               = white
fill_color          = red,orange,green,blue
fill_under          = yes
thickness           = 0,0,0,0
min                 = 0
r0                  = 1.015r
r1                  = 1.092r
<axes>
<axis>
color               = lgrey
thickness           = $axis_thickness
spacing             = $axis_spacing
</axis>
</axes>
</plot>
</plots>
";
close CONF;

print "(?) running Circos\n";
$circos = `nice perl $path2circos/bin/circos -noparanoid -conf $blastout.conf`;
print $circos unless $online;
if (-e "$blastout.$out_type") { print "(=) done: $blastout.$out_type $blastout\n";
} else {                        print "(!) there was an error running Circos (no output detected) - exiting\n"; exit; }


sub revcomp {
    my $seq = reverse $_[0];
    $seq =~ tr/ACGTacgt/TGCAtgca/;
    return $seq;
}
