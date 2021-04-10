#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use 5.010;
use FindBin;

# Use the modified version of YAML::Tiny from the tools directory.
use lib "$FindBin::Bin/../tools/YAML-Tiny/lib";
use YAML::Tiny;

# Patterns                                                  -- matches              -- captures         -- example          - gives
my $pat_filename_id = qr/([\w.-]+?)\.txt/;                  # filename              id (== basename)    'Apache-2.0.txt'    'Apache-2.0'
my $pat_indent      = qr/\{\{(?:t_)?indent(\d{1,2})\}\}/;   # indent placeholder    number of spaces    '{{t_indent4}}'     4
my $pat_concat      = qr/\{\{t_concat\}\}/;                 # concat marker                             '{{t_concat}}'
my $pat_cursor      = qr/\$\|\$/;                           # cursor marker                             '$|$'
my $pat_year        = qr/\{\{year\}\}/;                     # year placeholder                          '{{year}}'

sub main;
main();

# The script gets the path to the espanso package configuration and tests if
# the license headers hardcoded in the configuration match their online
# reference license data.
sub main {
    my $path = $ARGV[0];

    die <<USAGE if not defined $path;
$FindBin::Script: not enough arguments
usage:  $FindBin::Script <path>
        path    path to package.yml configuration
USAGE

    my $yaml = YAML::Tiny->read($path);
    my @license_headers = grep { $_->{trigger} =~ /^:lh/ } @{$yaml->[0]->{matches}};
    my @license_texts   = grep { $_->{trigger} =~ /^:lt/ } @{$yaml->[0]->{matches}};
    my %license_map     = map  { $_->{trigger} => $_     } @license_texts;

    for (@license_headers) {
        # Get the license text entry corresponding to the license header entry.
        ( my $key = $_->{trigger} ) =~ s/^:lh/:lt/;
        next unless exists $license_map{$key};

        my $entry = $license_map{$key};
        my $id    = license_id($entry);

        # The curl command downloads the full text of the license.
        my $curl  = curl_cmd($entry);
        my $str_a = qx( $curl );
        die "calling system curl failed with error: ${^CHILD_ERROR_NATIVE}"
            if ${^CHILD_ERROR_NATIVE};

        my $str_b = $_->{replace};
        $str_b    = tr_year($str_b);
        $str_b    = tr_concat($str_b);
        $str_b    = tr_indent($str_b);
        $str_b    = trim_cursor($str_b);

        # The license header must be part of the license text.
        die <<MESSAGE if index($str_a, $str_b) == -1;
test failed:
    license header ($_->{trigger}) does not match the $id license ($key)
MESSAGE
    }
}

# Extract the SPDX license identifier.
sub license_id {
    my $field = shift->{vars}->[-1]->{params}->{cmd};
    ( my $id ) = $field =~ m<curl -LSs .+?/$pat_filename_id>;
    return $id;
}

# Get the curl command string.
sub curl_cmd {
    my $id = license_id(shift);
    return "curl -LSs https://raw.githubusercontent.com/" .
        "spdx/license-list-data/master/text/" . $id . ".txt";
}

# Restore line continuations (aka concat lines).
sub tr_concat {
    ( my $str = shift ) =~ s/\s+$pat_concat/ /g;
    return $str;
}

# Restore indentation ('translate' the indent placeholder).
sub tr_indent {
    my $str = shift;
    ( my $cnt ) = ( $str =~ /$pat_indent/ );
    $str =~ s/$pat_indent/' ' x $cnt/eg;
    return $str;
}

# Restore ('translate') the year placeholder.
sub tr_year {
    ( my $str = shift ) =~ s/$pat_year/<year>/g;
    if ($str =~ /Apache License, Version 2\.0/) {
        $str =~ s/<year>/[yyyy]/;
    }
    return $str;
}

# Trim the cursor marker.
sub trim_cursor {
    ( my $str = shift ) =~ s/$pat_cursor//;
    return $str;
}
