#!perl

# test spec generation and the generated spec

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Test::More 0.96;
require "testlib.pl";

my ($table_data, $table_spec) = gen_test_data();

test_gen(
    name => 'pk must be in columns',
    table_data => [],
    table_spec => {
        columns => {
            a => ['int*' => {column_index=>0, }],
        },
        pk => 'b',
    },
    status => 400,
);

test_gen(
    name => 'pk must exist in table_spec',
    table_data => [],
    table_spec => {
        columns => {
            a => ['int*' => {column_index=>0, }],
        },
    },
    status => 400,
);

test_gen(
    name => 'columns must exist in table_spec',
    table_data => [],
    table_spec => {
    },
    status => 400,
);

test_gen(
    name => 'fields in sort must exist in columns',
    table_data => [],
    table_spec => {
        columns => {
            a => ['int*' => {column_index=>0, }],
        },
    },
    status => 400,
);

test_gen(
    name => 'field clash with argument',
    table_data => [],
    table_spec => {
        columns => {
            random => ['int*'  => {column_index=>0, }],
        },
        pk => 'random',
    },
    status => 200,
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $spec = $res->[2]{spec};
        my $args = $spec->{args};
        ok( $args->{random}, "random arg generated");
        ok(!$args->{min_random}, "min_random arg not generated");
        ok(!$args->{max_random}, "max_random arg not generated");
        ok( $args->{random_field}, "random_field arg generated");
        ok( $args->{min_random_field}, "min_random_field arg generated");
        ok( $args->{max_random_field}, "min_random_field arg generated");
    },
);

test_gen(
    name => 'field clash with argument (fail)',
    table_data => [],
    table_spec => {
        columns => {
            random => ['int*'  => {column_index=>0, }],
            random_field => ['int*'  => {column_index=>0, }],
        },
        pk => 'random',
    },
    status => 400,
);

test_gen(
    name => 'spec generation tests',
    table_data => [],
    table_spec => $table_spec,
    status => 200,
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $spec = $res->[2]{spec};
        my $args = $spec->{args};
        ok($args->{b}, "boolean filter arg 'b' generated");

        ok($args->{i}, "int filter arg 'i' generated");
        ok($args->{max_i}, "int filter arg 'min_i' generated");
        ok($args->{min_i}, "int filter arg 'max_i' generated");

        ok($args->{f}, "float filter arg 'f' generated");
        ok($args->{min_f}, "float filter arg 'min_f' generated");
        ok($args->{max_f}, "float filter arg 'max_f' generated");

        ok($args->{has_a}, "array filter arg 'has_a' generated");
        ok($args->{lacks_a}, "array filter arg 'lacks_a' generated");

        ok($args->{s}, "string filter arg 's' generated");
        ok($args->{s_contain}, "string filter arg 's_contain' generated");
        ok($args->{s_not_contain}, "string filter arg 's_not_contain' gen'd");
        ok($args->{s_match}, "string filter arg 's_match' generated");
        ok($args->{s_not_match}, "string filter arg 's_not_match' generated");

        ok(!$args->{s2}, "string filter arg 's2' not generated");
        ok(!$args->{s2_contain},
           "string filter arg 's2_contain' not generated");
        ok(!$args->{s2_not_contain},
           "string filter arg 's2_not_contain' not generated");
        ok(!$args->{s2_match}, "string filter arg 's2_match' not generated");
        ok(!$args->{s2_not_match},
           "string filter arg 's2_not_match' not generated");

        ok($args->{s3}, "string filter arg 's3' generated");
        ok($args->{s3_contain}, "string filter arg 's3_contain' generated");
        ok($args->{s3_not_contain},
           "string filter arg 's3_not_contain' generated");
        ok(!$args->{s3_match}, "string filter arg 's3_match' not generated");
        ok(!$args->{s3_not_match},
           "string filter arg 's3_not_match' not generated");
    },
);

test_gen(
    name => 'default_sort',
    table_data => $table_data,
    table_spec => $table_spec,
    other_args => {default_sort=>"s"},
    status => 200,
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $spec = $res->[2]{spec};
        my $args = $spec->{args};

        my $fres;
        $fres = $func->(detail=>1);
        subtest "default_sort s" => sub {
            is($fres->[0], 200, "status")
                or diag explain $fres;
            my @r = map {$_->{s}} @{$fres->[2]};
            is_deeply(\@r, [qw/a1 a2 a3 b1/], "sort result")
                or diag explain \@r;
        };
    },
);

DONE_TESTING:
done_testing();
