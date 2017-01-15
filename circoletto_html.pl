#!/usr/bin/perl -w
$| = 1;

use CGI;  
use File::Basename;

$randomer = int(rand(1001)) . $$;
$randomer = sprintf "%010s", $randomer;

$names{official} = 'Circoletto';
$names{unix} = 'circoletto';
$names{description} = 'visualising sequence similarity with Circos';
$safe_filename_characters = "a-zA-Z0-9_.-";  
$upload_dir = "/labs/bat/www/tools/results/$names{unix}";
$results_filename = "$upload_dir/out$randomer";

#%elites = (
#'noone', '1'
#);

print "Content-type: text/html; charset=iso-8859-1\n\n";
$html2print = qq(
<html>
<head>

<pre>
<link rel="stylesheet" href="/css/blueprint/screen.css" type="text/css" media="screen, projection, print"/>
<link rel="stylesheet" href="/css/css4circoletto.css" type="text/css" />
</pre>

<title>$names{official} @ the BAT cave | results</title>
</head>
<body>

<div class="container" style="opacity:0.92;filter:alpha(opacity=92)">

<!--Header of the Page-->
<div id="header" class="span-24 last" style="background-color:white">
<h1 style="text-align:center">$names{official}</h1>
<h2 style="text-align:center">$names{description}</h2>
</div>

<!-- MAIN CONTENT -->
<div id="content" class="span-24 last">
<fieldset>
<p style="text-align:left">

);
print $html2print;

undef($/); # read whole file into a variable    

$CGI::POST_MAX = 1024 * 20000;
$CGI::DISABLE_UPLOADS = 0; # 1 disables uploads, 0 enables uploads

$cgi = new CGI;
#$elite              = $cgi->param( "elite" ); # || error( $cgi, "no query FASTA received" );
#if (defined($elites{$elite})) {
#	$CGI::POST_MAX = 1024 * 40000;
#}
$cgi->cgi_error and error( $cgi, "error transferring file: " . $cgi->cgi_error );
$querytext          = $cgi->param( "querytext" ); # || error( $cgi, "no query FASTA received" );
$databasetext       = $cgi->param( "databasetext" ); # || error( $cgi, "no database FASTA received" );
$query              = $cgi->param( "queryfile" ); # || error( $cgi, "no query FASTA received" );
$database           = $cgi->param( "databasefile" ); # || error( $cgi, "no database FASTA received" );
$blastout           = $cgi->param( "blastout" ); # || error( $cgi, "no BLAST output received" );
if (defined $querytext    && $querytext    =~ /href ?=/) { error( $cgi, "if you are not a spammer, remove href tag and have another go" ); }
if (defined $databasetext && $databasetext =~ /href ?=/) { error( $cgi, "if you are not a spammer, remove href tag and have another go" ); }
if ($query && $querytext) { error( $cgi, "you have provided query in both text and file format - reset the form if you have to" ); }
if ($database && $databasetext) { error( $cgi, "you have provided database in both text and file format - reset the form if you have to" ); }
if (($query || $querytext) && ($database || $databasetext) && $blastout) { error( $cgi, "please either provide two FASTA files, or a BLAST output (you currently provide all three!) - reset the form if you have to" ); }
unless ((($query || $querytext) && ($database || $databasetext) && !$blastout) || (!$query && !$querytext && !$database && !$databasetext && $blastout)) { error( $cgi, "please either provide two FASTA files, or a BLAST output - reset the form if you have to" ); }
$e_value            = $cgi->param( "e_value" );
$flt                = $cgi->param( "flt" );
$best_hit           = $cgi->param( "best_hit" );
$best_hit_type      = $cgi->param( "best_hit_type" );
$w_hits             = $cgi->param( "w_hits" );
$no_labels          = $cgi->param( "no_labels" );
$score2colour       = $cgi->param( "score2colour" );
$scoreratio2colour  = $cgi->param( "scoreratio2colour" );
$abscolour          = $cgi->param( "abscolour" );
$maxB1              = $cgi->param( "maxB1" );
$maxG2              = $cgi->param( "maxG2" );
$maxO3              = $cgi->param( "maxO3" );
$untangling_off     = $cgi->param( "untangling_off" );
$revcomp_q		    = $cgi->param( "revcomp_q" );
$revcomp_d	        = $cgi->param( "revcomp_d" );
$reverse_qorder     = $cgi->param( "reverse_qorder" );
$reverse_dorder     = $cgi->param( "reverse_dorder" );
$reverse_qorient    = $cgi->param( "reverse_qorient" );
$reverse_dorient    = $cgi->param( "reverse_dorient" );
$out_type           = $cgi->param( "out_type" );
$out_size           = $cgi->param( "out_size" );
$annotationtext     = $cgi->param( "annotationtext" );
$annotation         = $cgi->param( "annotationfile" );
$annocolour			= $cgi->param( "annocolour" );
$invertcolour       = $cgi->param( "invertcolour" );
$allowbluerib       = $cgi->param( "allowbluerib" );
$allowgreenrib      = $cgi->param( "allowgreenrib" );
$alloworangerib     = $cgi->param( "alloworangerib" );
$allowredrib        = $cgi->param( "allowredrib" );
$z_by               = $cgi->param( "z_by" );
$hide_orient_lights = $cgi->param( "hide_orient_lights" );
$tblastx            = $cgi->param( "tblastx" );
if ($annotation && $annotationtext) { error( $cgi, "you have provided annotation in both text and file format - reset the form if you have to" ); }

unless (defined($abscolour)) {			$abscolour4script = '';			} else { $abscolour4script			= '--abscolour'; }
unless (defined($flt)) {				$flt4script = '';				} else { $flt4script 				= '--flt'; }
unless (defined($best_hit)) {			$best_hit4script = '';			} else { $best_hit4script 			= "--best_hit --best_hit_type $best_hit_type"; }
unless (defined($w_hits)) {				$w_hits4script = '';			} else { $w_hits4script 			= '--w_hits';}
unless (defined($no_labels)) {			$no_labels4script = '';			} else { $no_labels4script 			= '--no_labels';}
unless (defined($untangling_off)) {		$untangling_off4script = '';	} else { $untangling_off4script 	= '--untangling_off';}
unless (defined($revcomp_q)) {			$revcomp_q4script = '';			} else { $revcomp_q4script 			= '--revcomp_q';}
unless (defined($revcomp_d)) {			$revcomp_d4script = '';			} else { $revcomp_d4script 			= '--revcomp_d';}
unless (defined($reverse_qorder)) {		$reverse_qorder4script = '';	} else { $reverse_qorder4script 	= '--reverse_qorder';}
unless (defined($reverse_dorder)) {		$reverse_dorder4script = '';	} else { $reverse_dorder4script 	= '--reverse_dorder';}
unless (defined($reverse_qorient)) {    $reverse_qorient4script = '';	} else { $reverse_qorient4script 	= '--reverse_qorient';}
unless (defined($reverse_dorient)) {    $reverse_dorient4script = '';	} else { $reverse_dorient4script 	= '--reverse_dorient';}
unless (defined($tblastx)) {			$tblastx4script = '';			} else { $tblastx4script 			= '--tblastx';}
unless (defined($invertcolour)) {		$invertcolour4script = '';		} else { $invertcolour4script 		= '--invertcolour';}
unless (defined($hide_orient_lights)) { $hide_orient_lights4script = '';} else { $hide_orient_lights4script = '--hide_orient_lights';}
$ribocolours2allow = '';
$ribocolours2allow4script = '';
if (defined $allowbluerib) {	$ribocolours2allow .= 'blue|'; }
if (defined $allowgreenrib) {	$ribocolours2allow .= 'green|'; }
if (defined $alloworangerib) {	$ribocolours2allow .= 'orange|'; }
if (defined $allowredrib) {		$ribocolours2allow .= 'red|'; }
if ($ribocolours2allow !~ /\w/) {
    error( $cgi, "please leave at least one colour of ribbons to show" );
} else {
    chop $ribocolours2allow;
    $ribocolours2allow = "'($ribocolours2allow)'";
    unless ($ribocolours2allow eq '(blue|green|orange|red)') {
        $ribocolours2allow4script = "--ribocolours2allow $ribocolours2allow";
    }
}

if ($query =~ /[$safe_filename_characters]/) {

    $query =~ s/ /_/g;  
    ( $name, $path, $extension ) = fileparse ( $query );
    $filename = $name . $extension;  
    $filename =~ s/[^$safe_filename_characters]//g;  
    if ( $filename =~ /^([$safe_filename_characters]+)$/ ) {  
        $filename = $1;
    } else {  
        error( $cgi, "filename contains invalid characters (we allow $safe_filename_characters)" );
    }
    $upload_filehandle = $cgi->upload("queryfile");
    open ( UPLOADFILE, ">$upload_dir/$filename$randomer" ) or die "$!";  
    while ( <$upload_filehandle> ) {  
        print UPLOADFILE;
    }
    close UPLOADFILE;
    $query = $filename;

    ++$version2run;

} elsif (defined($querytext) && $querytext ne '') {

    $query = 'query';
    $filename = $query;
    open ( UPLOADFILE, ">$upload_dir/$filename$randomer" ) or die "$!";  
    print UPLOADFILE $querytext . "\n";
    close UPLOADFILE;
    
    ++$version2run;

}

if ($database =~ /[$safe_filename_characters]/) {

    $database =~ s/ /_/g;  

    if ($query ne $database) {
        ( $name, $path, $extension ) = fileparse ( $database );  
        $filename = $name . $extension;  
        $filename =~ s/[^$safe_filename_characters]//g;  
        if ( $filename =~ /^([$safe_filename_characters]+)$/ ) {  
            $filename = $1;
        } else {
            error( $cgi, "filename contains invalid characters (we allow $safe_filename_characters)" );  
        }  
        $upload_filehandle = $cgi->upload("databasefile");  
        open ( UPLOADFILE, ">$upload_dir/$filename$randomer" ) or die "$!";  
        while ( <$upload_filehandle> ) {  
            print UPLOADFILE;
        }
        close UPLOADFILE;
        $database = $filename;
    }
    
    ++$version2run;
    
} elsif (defined($databasetext) && $databasetext ne '') {

    if ($querytext eq $databasetext) {
        $database = 'query';
    } else {
        $database = 'database';
        $filename = $database;
        open ( UPLOADFILE, ">$upload_dir/$filename$randomer" ) or die "$!";  
        print UPLOADFILE $databasetext . "\n";
        close UPLOADFILE;
    }
    
    ++$version2run;

}

if ($blastout =~ /[$safe_filename_characters]/) {

    $blastout =~ s/ /_/g;  
    ( $name, $path, $extension ) = fileparse ( $blastout );
    $filename = $name . $extension;  
    $filename =~ s/[^$safe_filename_characters]//g;  
    if ( $filename =~ /^([$safe_filename_characters]+)$/ ) {  
        $filename = $1;
    } else {  
        error( $cgi, "filename contains invalid characters (we allow $safe_filename_characters)" );  
    }
    $upload_filehandle = $cgi->upload("blastout");
    open ( UPLOADFILE, ">$upload_dir/$filename$randomer" ) or die "$!";  
    while ( <$upload_filehandle> ) {  
        print UPLOADFILE;
    }
    close UPLOADFILE;
    $blastout = $filename;
    
    ++$version2run;

}

if (defined($annotation) && $annotation =~ /[$safe_filename_characters]/) {
    
    $annotation =~ s/ /_/g;  
    ( $name, $path, $extension ) = fileparse ( $annotation );  
    $filename = $name . $extension;  
    $filename =~ s/[^$safe_filename_characters]//g;  
    if ( $filename =~ /^([$safe_filename_characters]+)$/ ) {  
        $filename = $1;
    } else {  
        error( $cgi, "filename contains invalid characters (we allow $safe_filename_characters)" );  
    }  
    $upload_filehandle = $cgi->upload("annotationfile");  
    open ( UPLOADFILE, ">$upload_dir/$filename$randomer" ) or die "$!";  
    while ( <$upload_filehandle> ) {  
        print UPLOADFILE;
    }
    close UPLOADFILE;
    `perl -pi -e 's/\r//g' $upload_dir/$annotation$randomer`;
    $annotation4script = "--annotation $upload_dir/$annotation$randomer";
    
} elsif (defined($annotationtext) && $annotationtext =~ /\w/) {

    $annotation = 'annotation';
    $filename = $annotation;
    open ( UPLOADFILE, ">$upload_dir/$filename$randomer" ) or die "$!";  
    print UPLOADFILE $annotationtext . "\n";
    close UPLOADFILE;
    $annotation4script = "--annotation $upload_dir/$annotation$randomer";

} else {
    $annotation4script = '';
}
if (defined($annocolour))  { $annotation4script .= " --annocolour $annocolour"; }

#if (defined($elites{$elite})) {
#	print "<label>elite version enabled</label></br>";
#        $html2print .= "<label>elite version enabled</label></br>";
##} else {
##	print "<label>hello $elite - who are you?</label></br>";
##        $html2print .= "<label>hello $elite - who are you?</label></br>";
#}
print "<label>running $names{official} - please wait...</label></br>";
$html2print .= "<label>running $names{official} - please wait...</label></br>";

$log = "/labs/bat/www/tools/logs/$names{unix}.log";
$max_time = 300;
$max_mem  = 2000000000;

$cpus = 4;

if ($version2run == 2) {

    `perl -pi -e 's/\r//g' $upload_dir/$query$randomer`;
    `perl -pi -e 's/\r//g' $upload_dir/$database$randomer`;
	$circoletto_command = "circoletto.pl --online --cpus $cpus --query $upload_dir/$query$randomer --database $upload_dir/$database$randomer --out_type $out_type --e_value $e_value $tblastx4script $flt4script $best_hit4script $w_hits4script $no_labels4script --score2colour $score2colour --scoreratio2colour $scoreratio2colour $abscolour4script --maxB1 $maxB1 --maxG2 $maxG2 --maxO3 $maxO3 $untangling_off4script $revcomp_q4script $revcomp_d4script $reverse_qorder4script $reverse_dorder4script $reverse_qorient4script $reverse_dorient4script --out_size $out_size $annotation4script $invertcolour4script $ribocolours2allow4script --z_by $z_by $hide_orient_lights4script";
    `perl /labs/bat/www/tools/cgi-bin/limitresources.pl --command "nice perl $circoletto_command" --log $log --seconds $max_time --memory $max_mem > $results_filename &`;
    
} elsif ($version2run == 1) {

    `perl -pi -e 's/\r//g' $upload_dir/$blastout$randomer`;
	$circoletto_command = "circoletto.pl --online --cpus $cpus --blastout $upload_dir/$blastout$randomer --out_type $out_type $best_hit4script $w_hits4script $no_labels4script --score2colour $score2colour --scoreratio2colour $scoreratio2colour $abscolour4script --maxB1 $maxB1 --maxG2 $maxG2 --maxO3 $maxO3 $untangling_off4script $revcomp_q4script $revcomp_d4script $reverse_qorder4script $reverse_dorder4script $reverse_qorient4script $reverse_dorient4script --out_size $out_size $annotation4script $invertcolour4script $ribocolours2allow4script --z_by $z_by $hide_orient_lights4script";
    `perl /labs/bat/www/tools/cgi-bin/limitresources.pl --command "nice perl $circoletto_command" --log $log --seconds $max_time --memory $max_mem > $results_filename &`;

} else { error( $cgi, "we seem to have multiple input data - reset the form if you have to" ); }

         print "\n<pre>\n";
$html2print .= "\n<pre>\n";
$circoletto_progress = '';
$done = 0;
$naptime = 0.1;
while ($circoletto_progress !~ /done/){
    select(undef, undef, undef, $naptime);
    open (OUT, "<$results_filename") or die "cannot read output: $!\n";
    $circoletto_progress = <OUT>;
    @split_progress = (split /\n/, $circoletto_progress);
    foreach $line (@split_progress) {
        unless (defined($printed{$line})) {
            if ($line =~ /done/) {
                @split_line = (split / /, $line);
                @split_circos = (split /\//, $split_line[2]);
                $circos_output = pop @split_circos;
                @split_blast = (split /\//, $split_line[3]);
                $blast_output = pop @split_blast;
                $done = 1;
            } elsif ($line =~ /ERROR/ || $line =~ /exiting/) {
                         print "$line</br>";
                $html2print .= "$line</br>";
                goto MOVEON;
            } else {
                         print "$line</br>";
                $html2print .= "$line</br>";
            }
            $printed{$line} = 1;
        }
    }
    close OUT;
}
MOVEON:
         print "\n</pre>\n";
$html2print .= "\n</pre>\n";
if ($done) {

	$blast4html = '';
    if      ($version2run == 2) { $blast4html = "<label><a href=\"\/circoletto_results\/$blast_output\">see the BLAST output</a></label></br>";
    } elsif ($version2run == 1) { $blast4html = "<label>see the BLAST output you <a href=\"\/circoletto_results\/$blast_output\">uploaded</a></label></br>"; }

    if (defined($reverse_qorient)) {		$qclockwisely = "anticlockwisely";
    } else {						 		$qclockwisely = "clockwisely"; }
    if (defined($reverse_dorient)) { 		$dclockwisely = "anticlockwisely";
    } else {				         		$dclockwisely = "clockwisely"; }
    unless (defined($hide_orient_lights)) { $follow_the_lights = ", or follow the orientation lights from green to red";
    } else {        						$follow_the_lights = ''; }
# Red web color Hex#FF0000
# Orange color wheel Orange Hex#FF7F00
# Yellow web color Hex#FFFF00
# Green X11 Electric Green HTML/CSS “Lime” Color wheel green Hex#00FF00
# Blue web color Hex#0000FF
# Indigo Electric Indigo Hex#4B0082
# Violet Electric Violet Hex#8B00FF	
    if ($annocolour =~ /rainbow_colour/) { $colours = qq(<u>colours</u>: 7-colour rainbow, i.e. (in order) <span style="color:#FF0000">red</span>, <span style="color:#FF7F00">orange</span>, <span style="color:#FFFF00">yellow</span>, <span style="color:#00FF00">green</span>, <span style="color:#0000FF">blue</span>, <span style="color:#4B0082">indigo</span>, <span style="color:#8B00FF">violet</span></br>); } else { $colours = ''; }

	$namechanges = '';
	if (-e "$blast_output.original_labels" && -s "$blast_output.original_labels" > 0) {
		$namechanges = qq(<label><a href=\"\/circoletto_results\/$blast_output.original_labels\">see the sequence name changes</a> Circoletto may had to make</label></br>);
	}	

    $html2print .= qq(
    <i>Circoletto is a generic tool and it cannot 'understand' what your data mean or imply - interpretation is up to you.</br>
    We show inversions per segment (i.e. reverse-complementary or plus/minus segments) by twisting ribbons,</br>
	&nbsp;&nbsp;and inversions in the order of the segments by ...not crossing the ribbons (unless you reverse the orientation of ideograms).</br>
    When you get used to it all, and read the sequences in the correct orientation and the ribbons in the right order,</br>
    &nbsp;&nbsp;the colouring + ordering + twisting + crossing of ribbons should show you what is going on.</i></br>
	</br>
	<u>command line</u>:</br>
	<span style="word-wrap:break-word;font-family:monospace">$circoletto_command</span></br>
	</br>
    <u>orientations</u>: <b>$qclockwisely</b> for <b>query</b> sequences, <b>$dclockwisely</b> for <b>database</b> sequences$follow_the_lights</br>
	<i>&nbsp;&nbsp;tip: for contig assembly check and for 2-3 sequences with multiple ribbons, it usually helps to reverse orientation of query OR database sequences</i></br>
	$colours 
    <a href="/circoletto_results/$circos_output"><img src="/circoletto_results/$circos_output" style="max-width:500px; max-height:500px;"/></a></br>
    $blast4html
	$namechanges
	</br>
    if you want, you could either save the results locally, or bookmark the above URLs since they are kept for a while
    );
} else {
    $html2print .= qq(
    </br></br>
	something is not right... please try again, try something different, or <a href="http://bat.infspire.org/contactus/contact_form/index.php" onClick="return popup(this, 'contact the BAT cave')">contact us</a>
    );
}

$html2print .= qq(
</fieldset>

<p class="small quiet terms" style="text-align:right">
hosted at the <a href="http://bat.infspire.org/" target="_blank"> Bioinformatics Analysis Team / BAT</a>
</p>

</div>
</div>

</body>
</html>

);

open (PAGE2GET, ">$upload_dir/$randomer.html") or die "cannot create output: $!\n";
print PAGE2GET $html2print;
close PAGE2GET;
#print "Location: http://tools.bat.infspire.org/circoletto_results/$circos_output.html\n\n";
#$cgi->redirect(-uri=>qq[http://tools.bat.infspire.org/circoletto_results/$circos_output.html], -status=>302);
print "<META HTTP-EQUIV=refresh CONTENT=\"0;URL=http://tools.bat.infspire.org/circoletto_results/$randomer.html\">\n";

exit;

sub error {
    my( $cgi, $reason ) = @_;
    
    print $cgi->header( "text/html" ),
          $cgi->start_html( "error @ the BAT cave" ),
          $cgi->h1( "error @ the BAT cave" ),
          $cgi->p( "your upload was not processed because the following error occured: " ),
          $cgi->p( $cgi->i( $reason ) ),
          $cgi->end_html;
    exit;
}
