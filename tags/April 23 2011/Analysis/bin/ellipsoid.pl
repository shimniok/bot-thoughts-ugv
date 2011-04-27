#!/usr/bin/perl

open(FIN, "<$ARGV[0]") || die "can't open: $ARGV[0]";

$label{0} = "X";
$label{1} = "Y";
$label{2} = "Z";

$count = 0;
while (<FIN>) {
    s/^\s+//;
    @data = split(/\s+/);
    
    
    for ($i = 0; $i < 3; $i++) {
#		print "$i ", $data[$i], "\n";
	$sum[$i] += $data[$i];
	$max[$i] = $data[$i] if ($data[$i] > $max[$i]);
	$min[$i] = $data[$i] if ($data[$i] < $min[$i]);
    }
    $count++;
}

for ($i = 0; $i < 3; $i++) {
    $med[$i] = ($max[$i]+$min[$i])/2.0;
    printf STDERR "%smax = %6.2f  %smin = %6.2f %soff = %6.2f\n",
    $label{$i}, $max[$i], $label{$i}, $min[$i], $label{$i}, $med[$i];
    $max[$i] -= $med[$i];
    $min[$i] -= $med[$i];
    $max = $max[$i] if ($max[$i] > $max);
    $min = $min[$i] if ($min[$i] < $min);
}
close FIN;

printf STDERR "Max  = %6.2f  Min  = %6.2f\n", $max, $min;

for ($i = 0; $i < 3; $i++) {
    $scale[$i]=$max/$max[$i];
    printf STDERR "%ssca = %6.2f  ", $label{$i}, $max/$max[$i];
}
printf STDERR "\n";


seek FIN, 0, SEEK_SET;
while (<FIN>) {   
    s/^\s+//;
    next if (/^X/);
    @data = split(/\s+/);
    
    for ($i = 0; $i < 3; $i++) {
	$data[$i] -= $med[$i];
	$data[$i] *= $scale[$i];
	printf "%.2f ", $data[$i];
    }
    print "\n";
}


exit;

