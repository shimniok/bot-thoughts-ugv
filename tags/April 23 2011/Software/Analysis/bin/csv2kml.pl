#!/usr/bin/perl -w
#
# csv2kml.pl - Convert CSV marker files from AFCTrailMap and related iPhone apps to KML
# 
# Copyright 2009, Chris Leger, Earthrover Software.  Free for all uses without restriction.
#

$HEADER = "---BEGIN_CSV---";
$FOOTER = "---END_CSV---";

$for_real = 1;
$quiet = 1;
$verbose = 0;

for $file (@ARGV) {
  if ($file eq "-h" ||
      $file eq "--help" ||
      $file eq "-help") {
    usage();
  }
  process_csv($file);
}

sub process_csv {
  my $csvfile = $_[0];
  my $kmlfile;
  my $row;

  ($kmlfile = $csvfile) =~ s/\.csv$//g;
  $kmlfile .= ".kml";

  my @rows = read_csv_new($csvfile);

  open(KMLFILE, ">$kmlfile") || die "can't write $kmlfile\n";

  print KMLFILE <<END
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
  <Document>
    <name>My markers</name>
        <Style id=\"normal\">
          <IconStyle>
            <Icon>
              <href>http://maps.google.com/mapfiles/kml/pal4/icon29.png</href>
            </Icon>
          </IconStyle>
        </Style>
END
;
  for $row (@rows) {
    print KMLFILE <<END
      <Placemark>
        <name>$row->{name}</name>
        <open>1</open>
        <visibility>1</visibility>
        <styleUrl>normal</styleUrl>
        <LookAt>
  	  <latitude>$row->{latitude}</latitude>
	  <longitude>$row->{longitude}</longitude>
          <altitude>0</altitude>
          <range>100</range>
          <tilt>0</tilt>
          <heading>0</heading>
        </LookAt>
        <description>
        <![CDATA[
	     $row->{date}
	     <p>
	     $row->{description}
	   ]]>
        </description>
        <Point>
          <altitudeMode>relativeToGround</altitudeMode>
          <coordinates>$row->{longitude},$row->{latitude},0</coordinates>
        </Point>
      </Placemark>     
END
;
  }
  print KMLFILE "\n</Document>\n</kml>\n";
  close(KMLFILE);
}

sub read_csv {
  my $first = 1;
  my $num_fields = 0;
  my $linenum = 0;
  my $filename;
  my $num_entries;
  my $i;
  my $error;
  my @entries;
  my @fields;
  
  my @rows;

  for $filename (@_) {
    if ($verbose > 0) {
      print "\n### reading CSV file $filename...\n";
    }

    $first = 1;
    $num_fields = 0;
    $linenum = 0;
    open(INFILE, $filename) || die "Can't open csv file $filename for input"; 

    while (<INFILE>) {
      last if (/$HEADER/);
    }

    while (<INFILE>) {
      last if (/$FOOTER/);
      $linenum++;
      chomp;
      s/^\s*//g;
      next if (!$_);
      if ($first) {
	if (/^#/) {
	  if ($verbose > 0) {
	    print "$_\n";
	  }
	  next;
	} else {
	  @fields = split(/,/);
	  $num_fields = @fields;
	  $first = 0;
	}
      } else {
	@entries = split(/,/);
	$num_entries = @entries;
	if ($num_entries != $num_fields) {
	  print STDERR "file $filename, line $linenum:\n";
	  print STDERR " Line has $num_entries fields; need $num_fields\n: $_";
	  $error = 1;
	}
	my %row;
	for $i (0..$#fields) {
	  $row{$fields[$i]} = $entries[$i];
	}
	push (@rows, \%row);
      }
    }
    close INFILE;

    if ($verbose > 0) {
      my $num_rows = @rows;
      print "### Read $num_rows items with $num_fields fields each.\n";
      print "### done reading CSV file $filename.\n\n";
    }
    die "Errors found reading CSV file $filename; exiting\n" if ($error);
  }
  return @rows;
}

sub build_hash {
  my $row_ref = $_[0];
  my $key = $_[1];
  my $row;
  my $this_key;
  my %hash;

  for $row (@$row_ref) {
    $this_key = $row->{$key};
    $hash{$this_key} = $row;
  }

  return %hash;
}



sub my_system {
  if ($for_real) {
    system("$_[0]");
  }
  if (!$for_real || !$quiet) {
    print "$_[0]\n";
  }
}

sub print_hash_arr {
  my $hash_ref;
  my $desc = shift(@_);
  my $key;

  print "\n####### $desc ########\n";

  for $hash_ref (@_) {
    print "==============\n";
    for $key (keys %$hash_ref) {
      print "  $key = $$hash_ref{$key}\n";
    }
  }
}


sub read_csv_new {
  my $first = 1;
  my $num_fields = 0;
  my $linenum = 0;
  my $filename;
  my $num_entries;
  my $i;
  my $error;
  my @entries;
  my @fields;
  my @rows;

  for $filename (@_) {
    if ($verbose > 0) {
      print "\n### reading CSV file $filename...\n";
    }

    $first = 1;
    $num_fields = 0;
    $linenum = 0;
    $quote_arg = 0;
    @args = ();
    open(INFILE, $filename) || die "Can't open csv file $filename for input"; 

    while (<INFILE>) {
      last if (/$HEADER/);
    }

    while (<INFILE>) {
      last if (/$FOOTER/);
      if ($first) {
	chomp;
	if (/^#/) {
	  if ($verbose > 0) {
	    print "$_\n";
	  }
	  next;
	} else {
	  @fields = split(/,/);
	  $num_fields = @fields;
	  $first = 0;
	} 
      } else {
	if (!$quote_arg) {
	  # do some cleanup if we're not in a quoted arg
	  @args = ();
	  next if (/^#/);  # skip comment lines
	  if (/^\,/) {
	    # if the first character on the line was a comma, add a space to produce
	    # an empty arg.
	    $_ = " " . $_;
	  }
	}
	
	# do initial split by commas
	my @temp_args = split(/\,/);
	
	while (@temp_args) {
	  $arg = shift(@temp_args);
	  if ($quote_arg) {
	    # in a quoted argument.  concatenate.
	    $quote_arg .= $arg;
	    if ($arg =~ /\"/) {
	      chomp($quote_arg);
	      push(@args, $quote_arg);
	      $quote_arg = 0;
	    }
	  } else {
	    # chomp leading whitespace
	    $arg =~ s/^\s+//g;
	    # if first non-whitespace char is a quote, we're in a quoted arg
	    if ($arg =~ /^\".*\"\s*$/ && $arg !~ /\,/) {
	      # this is a quoted arg without any commas in it
	      $arg =~ s/^\"//;
	      $arg =~ s/\"\s*$//g;
	      chomp($arg);
	      push(@args, $arg);
	    } elsif ($arg =~ /^\"/ && $arg !~ /\"$/) {
	      # starting, and not ending, a quote--don't push this arg yet
	      ($quote_arg = $arg) =~ s/^\s*\"//g;
	    } else {
	      chomp($arg);
	      push (@args, $arg);
	    }
	  } 
	}   
	
	# if we've gottent to the end of the line but are still in a quoted
	# arg, process next line
	next if ($quote_arg);  
	
	my %row;
	for $i (0..$#fields) {
	  $row{$fields[$i]} = $args[$i];
	  print "field: $fields[$i]  arg: '$args[$i]'\n" if ($verbose);
	}
	print "row: " . join (" /// ", %row) . "\n" if ($verbose);
	push (@rows, \%row);
      }
    }
    close INFILE;

    if ($verbose > 0) {
      my $num_rows = @rows;
      print "### Read $num_rows items with $num_fields fields each.\n";
      print "### done reading CSV file $filename.\n\n";
    }
    die "Errors found reading CSV file $filename; exiting\n" if ($error);
  }

  return @rows;
}

sub usage {
  print "usage: $0 <csv-file> [<csv-file> [<csv-file] ...]\n";
  print "\nConvert an Earthrover CSV marker file to KML format.";
}

1;
