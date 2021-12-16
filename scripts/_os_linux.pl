## _os_.pl
##
##	for ANDROID
##
## for dependendant hardware platformm
	if( $debug ){ print "\nrun on $^O.\n"; };
	use Android;
	$droid = Android->new();
1;
