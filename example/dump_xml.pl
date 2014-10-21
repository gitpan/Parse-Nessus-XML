#!/usr/bin/perl
use Parse::Nessus::XML;
use Data::Dumper;

my $scan   = Parse::Nessus::XML->new( $ARGV[0] );
my $ByVuln = {};

foreach my $result ( $scan->results ) {

    print "Results for $result->{host}->{name} ($result->{host}->{ip})\n";

    foreach my $port ( @{ $result->{ports}->{port} } ) {
        $port->{information} = [ $port->{information} ]
          unless ref $port->{information} eq 'ARRAY';
        print
"$result->{host}->{name}, port $port->{portid} ($port->{service}->{name}):\n\n";

        foreach my $hit ( @{ $port->{information} } ) {
            print "Severity: $hit->{severity}\n";
            $hit->{data} =~ s/\t//g;
            print $hit->{data} . "\n";
            print "--------------------------------\n";

            # Put it in the ByVuln list.
            unless ( defined $ByVuln->{ $hit->{id} } ) {
                $ByVuln->{ $hit->{id} }{description} = $hit->{data};
            }
            push @{ $ByVuln->{ $hit->{id} }{hosts} },
              "* $result->{host}->{name} ($result->{host}->{ip})";
        }

        print "--- End port $port->{portid} ----\n\n";
    }

    print "----- End of host $result->{host}->{name} -----------\n\n";
}

foreach my $ID ( keys %$ByVuln ) {

    next unless $ID;

    my $vuln = $scan->plugin($ID);
    print "Vulnerability: " . $vuln->name . "\n";
    print "Risk: " . $vuln->risk . "\n";
    print "Summary: " . $vuln->summary . "\n";
    print "Vuln IDs: " . $vuln->cve_id . ', ' . $vuln->cve_id . "\n";

    print "Found on the following machines: \n";
    print join "\n", @{ $ByVuln->{$ID}->{hosts} };
    print "\n\nSample description: " . $ByVuln->{$ID}->{description} . "\n";
    print
      "(See by-machine report for the results for each particular server)\n";
    print "--------------------------------\n\n";
}

