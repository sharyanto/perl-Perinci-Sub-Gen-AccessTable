#!perl

# test the generated function

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Test::More 0.96;
require "testlib.pl";

my $table_data = [
    {s=>'a1', s2=>'', s3=>'a' , i=>1 , f=>0.1, a=>[qw//]   , b=>0},
    {s=>'b1', s2=>'', s3=>'aa', i=>2 , f=>0.2, a=>[qw/b/]  , b=>0},
    {s=>'a3', s2=>'', s3=>'aa', i=>4 , f=>1.1, a=>[qw/a b/], b=>1},
    {s=>'a2', s2=>'', s3=>'a' , i=>-3, f=>1.2, a=>[qw/a/]  , b=>1},
];

my $table_spec = {
    columns => {
        s  => ['str*'   => {column_index=>0, }],
        s2 => ['str*'   => {column_index=>1, column_filterable=>0}],
        s3 => ['str*'   => {column_index=>2, column_filterable_regex=>0}],
        i  => ['int*'   => {column_index=>3, }],
        f  => ['float*' => {column_index=>4, }],
        a  => ['array*' => {column_index=>5, column_sortable=>0, }],
        b  => ['bool*'  => {column_index=>6, }],
    },
    pk => 's',
};

test_gen(
    name => 'ordering tests',
    table_data => $table_data,
    table_spec => $table_spec,
    status => 200,
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $spec = $res->[2]{spec};
        my $args = $spec->{args};

        my $fres;

        $fres = $func->(sort=>"x");
        is($fres->[0], 400, "sort on unknown sort fields -> fail");

        $fres = $func->(sort=>"-a");
        is($fres->[0], 400, "sort on unsortable fields -> fail");

        $fres = $func->(sort=>"s", detail=>1);
        subtest "ascending sort" => sub {
            is($fres->[0], 200, "status")
                or diag explain $fres;
            my @r = map {$_->{s}} @{$fres->[2]};
            is_deeply(\@r, [qw/a1 a2 a3 b1/], "sort result")
                or diag explain \@r;
        };

        $fres = $func->(sort=>"-s", detail=>1);
        subtest "descending sort" => sub {
            is($fres->[0], 200, "status")
                or diag explain $fres;
            my @r = map {$_->{s}} @{$fres->[2]};
            is_deeply(\@r, [qw/b1 a3 a2 a1/], "sort result")
                or diag explain \@r;
        };

        $fres = $func->(sort=>"b, -s", detail=>1);
        subtest "multiple fields sort" => sub {
            is($fres->[0], 200, "status")
                or diag explain $fres;
            my @r = map {$_->{s}} @{$fres->[2]};
            is_deeply(\@r, [qw/b1 a1 a3 a2/], "sort result")
                or diag explain \@r;
        };
    },
);

DONE_TESTING:
done_testing();
