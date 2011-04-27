#!/usr/bin/perl

$i = 0;
while (<>) {
  s/[\r\n\s]//g;

  $HIST{$_}++;

  $sum += $_;
  $i++;
}
$count = $i;

$avg = $sum / $i;

$var = 0;
for ($i=-40; $i <= 40; $i++) {
  print $i, ",", $HIST{$i}, "\n";
  $var += $HIST{$i}/$count * ($i - $avg)^2;
}

$stddev = sqrt($var);

print ",,,Average, $avg\n,,,Variance, $var\n,,,StdDev, $stddev\n";
