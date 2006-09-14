#
#   Copyright (c) 2006 Lindquist Consulting, Inc.
#   All rights reserved. 
#                                                                     
#   Written by Dr. Kent Lindquist, Lindquist Consulting, Inc. 
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#   KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#   WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
#   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
#   OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
#   OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
#   OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
#   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#   This software may be used freely in any way as long as 
#   the copyright statement above is not removed. 

require "getopts.pl" ;
use Datascope;
use orb;
use RRDs;
 
sub inform {
	my( $msg ) = @_;
	
	if( $opt_v ) {
		
		elog_notify( "$msg\n" );
	}

	return;
}

#Fake the trwfname call since it's not in the perldb interface
sub trwfname {
	my( $pattern ) = pop( @_ );
	my( @db ) = @_;

	my( $net, $sta, $chan, $rrdvar ) = 
		dbgetv( @db, "net", "sta", "chan", "rrdvar" );

	my( $relpath, $fullpath );

	$relpath = epoch2str( $time, $pattern );
	$relpath =~ s/{net}/$net/;
	$relpath =~ s/{sta}/$sta/;
	$relpath =~ s/{chan}/$chan/;
	$relpath =~ s/{rrdvar}/$rrdvar/;

	if( $relpath !~ m@^/@ ) {

		my( $tabledir ) = dbquery( @db, dbTABLE_DIRNAME );

		$fullpath = concatpaths( $tabledir, $relpath );

	} else {

		$fullpath = $relpath;
	}

	( $dir, $base, $suffix ) = parsepath( $fullpath );
		
	system( "mkdir -p $dir" );

	$dfile = $base;
	if( $suffix ne "" ) {
		$dfile .= "." . $suffix;
	}

	dbputv( @db, "dir", $dir, "dfile", $dfile );

	return $fullpath;
}

sub archive_dlsvar {
	my( $net, $sta, $dls_var, $time, $val ) = @_;

	my( $key ) = "$net:$sta:$dls_var";

	my( $rrd );

	if( ! defined( $Rrd_files{$key} ) || ! -e "$Rrd_files{$key}" ) {

		my( $start_time ) = $time - $Stepsize_sec;

		my( @dbt ) = @Db;
		$dbt[3] = dbaddnull( @Db );

		dbputv( @dbt,
			"net", $net,
			"sta", $sta,
			"rrdvar", $dls_var,
			"time", $start_time );

		$rrd = trwfname( @dbt, $Rrdfile_pattern );

		my( $datasource ) = 
			"DS:$dls_var:$Dls_vars{$dls_var}{'dsparams'}";

		inform( "Creating rrdfile $rrd\n" ); 

		RRDs::create( "$rrd", 
				"-b", "$start_time", 
				"-s", "$Stepsize_sec",
				"$datasource", @{$Dls_vars{$dls_var}{'rras'}} ); 

		$Rrd_files{$key} = $rrd;

	} else {
		
		$rrd = $Rrd_files{$key};
	}

	RRDs::update( $rrd, "$time:$var" );

	return;
}

$Pf = "orb2rrd.pf";
$match = ".*/pf/st";
$pktid = 0;
$time = -9999999999.999;

if ( ! &Getopts('s:f:p:m:vV') || @ARGV != 2 ) { 

    	die ( "Usage: orb2rrd [-vV] [-s statefile] [-p pffile] " .
	      "[-m match] [-f from] orb dbcache\n" ) ; 

} else {
	
	$orbname = $ARGV[0];
	$dbcache = $ARGV[1];
}

elog_init( $0, @ARGV );

if( $opt_V ) {
	
	$opt_v++;
}

if( $opt_p ) {
	
	$Pf = $opt_p;
}

if( $opt_m ) {
	
	$match = $opt_m;
}

$orb = orbopen( $orbname, "r&" );

if( $orb < 0 ) {

	die( "Failed to open orb '$orbname' for reading\n" );
}

orbselect( $orb, $match );

if( $opt_f && ( ! $opt_s || ! -e "$opt_s" ) ) {
	
	$pktid = orbposition( $orb, $opt_f );

	inform( "Positioned to packet $pktid" );

} elsif( $opt_f ) {

	elog_complain( "Ignoring -f in favor of existing state-file\n" );
}

if( $opt_s ) {

	$stop = 0;
	exhume( $opt_s, \$stop, 15 );
	orbresurrect( $orb, \$pktid, \$time  );
	orbseek( $orb, "$pktid" );
}

@Db = dbopen( $dbcache, "r+" );

if( $Db[0] < 0 ) {

	die( "Failed to open cache database '$dbcache'. Bye.\n" );

} else {

	@Db = dblookup( @Db, "", "rrdcache", "", "" );

	if( $Db[1] < 0 ) {
		
		die( "Failed to lookup 'rrdcache' table in '$dbcache'. Bye.\n" );
	}
}

@dbt = dbsubset( @Db, "endtime == NULL" );

for( $dbt[3] = 0; $dbt[3] < dbquery( @dbt, dbRECORD_COUNT ); $dbt[3]++ ) {
	
	( $net, $sta, $rrdvar ) = dbgetv( @dbt, "net", "sta", "rrdvar" );

	$path = dbextfile( @dbt );

	$Rrd_files{"$net:$sta:$rrdvar"} = $path;
}

$Rrdfile_pattern = pfget( $Pf, "rrdfile_pattern" );
$Stepsize_sec = pfget( $Pf, "stepsize_sec" );
@lines = @{pfget( $Pf, "dls_vars" )};

foreach $line ( @lines ) {

	my( $dls_var, $dsparams, @myrras ) = split( /\s+/, $line );

	$Dls_vars{$dls_var}{'dsparams'} = $dsparams;
	$Dls_vars{$dls_var}{'rras'} = \@myrras;
}

for( ; $stop == 0 ; ) {

	($pktid, $srcname, $time, $packet, $nbytes) = orbreap( $orb );

	if( $opt_s ) {

		bury();
	}

	($result, $pkt) = unstuffPkt( $srcname, $time, $packet, $nbytes ); 

	if( $result ne "Pkt_pf" ) {

		inform( "Received a $result, skipping\n" );
		next;
	}

	$msg = "Received a parameter-file '$srcname' at " . strtime( $time );

	if( $opt_V ) {
		$msg .= ":\n" . pf2string( $pkt->pf ) . "\n\n";
	} else {
		$msg .= "\n";
	}

	inform( $msg );

	%mypktpf = %{pfget( $pkt->pf(), "dls" )};

	$time = int( $time );

	$dls_var = "br24"; #SCAFFOLD

	foreach $element ( keys %mypktpf ) {
	  foreach $dls_var ( keys %Dls_vars ) {

		( $net, $sta ) = split( '_', $element );

		$val =  $mypktpf{$element}{$dls_var};

		archive_dlsvar( $net, $sta, $dls_var, $time, $val );
	   }
	}
}
