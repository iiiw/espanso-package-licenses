#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use 5.010;
use FindBin;

# Use the modified version of YAML::Tiny in the tools directory.
use lib "$FindBin::Bin/../tools/YAML-Tiny/lib";
use YAML::Tiny;

# Patterns                                                  -- matches              -- captures         -- example          - result
my $pat_filename_id = qr/([\w.-]+?)\.txt/;                  # filename              id (== basename)    'Apache-2.0.txt'    'Apache-2.0'
my $pat_indent      = qr/\{\{(?:t_)?indent(\d{1,2})\}\}/;   # indent placeholder    number of spaces    '{{t_indent4}}'     4
my $pat_concat      = qr/\{\{t_concat\}\}/;                 # concat marker                             '{{t_concat}}'
my $pat_cursor      = qr/\$\|\$/;                           # cursor marker                             '$|$'
my $pat_owner       = qr/\{\{owner\}\}/;                    # owner placeholder                         '{{owner}}'
my $pat_year        = qr/\{\{year\}\}/;                     # year placeholder                          '{{year}}'

sub main;
main();

# The script gets the path to the package.yml (match file) and tests if the
# hardcoded license headers match their online counterparts.
sub main {
    my $path = $ARGV[0];

    die <<USAGE if not defined $path;
$FindBin::Script: not enough arguments
usage:  $FindBin::Script <path>
        path    path to package.yml file
USAGE

    my $yaml = YAML::Tiny->read($path);
    my @license_headers = grep { $_->{trigger} =~ /^:lh/ } @{$yaml->[0]->{matches}};
    my @license_texts   = grep { $_->{trigger} =~ /^:l[a-z]{3}\d?$/ } @{$yaml->[0]->{matches}};
    my %license_map     = map  { $_->{trigger} => $_ } @license_texts;

    for (@license_headers) {
        # Get the license text corresponding to the header.
        ( my $key = $_->{trigger} ) =~ s/^:lh/:l/;
        next unless exists $license_map{$key};

        my $entry = $license_map{$key};
        my $id    = license_id($entry);

        # Download the full text of the license.
        my $dl    = curl_cmd($entry);
        my $str_a = qx( $dl );
        die "calling system curl failed with error: ${^CHILD_ERROR_NATIVE}"
            if ${^CHILD_ERROR_NATIVE};

        # Modify the hardcoded header to get rid of additional markup and whitespace.
        my $str_b = $_->{replace};
        $str_b    = tr_year($str_b);
        $str_b    = tr_owner($str_b);
        $str_b    = tr_concat($str_b);
        $str_b    = tr_indent($str_b);
        $str_b    = trim_cursor($str_b);

        # The license header $str_b must be part of the license text $str_a.
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

# Set up the curl command to download from the spdx repository.
sub curl_cmd {
    my $id = license_id(shift);
    return "curl -LSs https://raw.githubusercontent.com/" .
        "spdx/license-list-data/master/text/" .
        $id . ".txt";
}

# Restore line continuations.
sub tr_concat {
    ( my $str = shift ) =~ s/\s+$pat_concat/ /g;
    return $str;
}

# Restore indentation.
sub tr_indent {
    my $str = shift;
    ( my $cnt ) = ( $str =~ /$pat_indent/ );
    $str =~ s/$pat_indent/' ' x $cnt/eg;
    return $str;
}

# Restore the owner placeholder.
sub tr_owner {
    ( my $str = shift ) =~ s/$pat_owner/<owner>/g;
    if ($str =~ /Apache License, Version 2\.0/) {
        $str =~ s/<owner>/[name of copyright owner]/;
    } elsif ($str =~ /GNU General Public License/) {
        $str =~ s/<owner>/<name of author>/;
    }
    return $str;
}

# Restore the year placeholder.
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
