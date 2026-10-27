use v6.d;

unit module Math::Optimization;

use Math::Backends::COIN-OR;
use Math::SparseMatrix;
use Data::TypeSystem::Predicates;

sub numeric-vector($value, Str:D $name --> Array:D) {
    die "$name must be a positional collection." unless $value ~~ Positional:D;
    my @result = $value.Array;
    die "$name must contain only real numbers." unless @result.all ~~ Real:D;
    return @result;
}


proto sub matrix-rows($matrix, Int:D $columns --> Array:D) {*}

multi sub matrix-rows(Math::SparseMatrix:D $matrix, Int:D $columns --> Array:D) {
    return matrix-rows($matrix.dense-matrix, $columns);
}

multi sub matrix-rows(@matrix, Int:D $columns --> Array:D) {
    # Should anything special be done here for optimization purposes?
    # Can a sparse matrix be just handed over to COIN-OR, or whatever backend?
    return @matrix;
}

sub constraint-data($value, Int:D $rows --> Hash:D) {
    die "b has {$value.elems} entries; expected $rows"
    unless $value.elems == $rows;

    my @rhs;
    my @senses;
    for $value.List.kv -> $index, $constraint {
        if $constraint ~~ Positional:D {
            die "constraint $index must contain (rhs, sense)" unless $constraint.elems == 2;
            my ($rhs, $sense) = $constraint.List;
            
            die "right-hand side of constraint $index must be real" unless $rhs ~~ Real:D;
            
            die "constraint sense at index $index must be 1, 0, or -1"
            unless $sense ~~ Int:D && $sense == any(1, 0, -1);
            
            @rhs.push($rhs);
            @senses.push($sense);
        }
        else {
            die "right-hand side of constraint $index must be real" unless $constraint ~~ Real:D;
            @rhs.push($constraint);
            @senses.push(1);
        }
    }

    return %(rhs => @rhs.Array, senses => @senses.Array);
}

sub bounds-data($value, Int:D $columns --> Hash:D) {
    my @lower = 0 xx $columns;
    my @upper = Inf xx $columns;
    return %(lower => @lower.Array, upper => @upper.Array)
    if $value ~~ Whatever || !$value.defined;

    if $value ~~ Real:D {
        @lower = $value xx $columns;
    }
    else {
        die 'Bounds must be a lower bound, a positional collection, or Whatever.'
        unless $value ~~ Positional:D;

        die "Bounds has {$value.elems} entries; expected $columns."
        unless $value.elems == $columns;

        if $value.elems && $value[0] ~~ Positional:D {
            for $value.List.kv -> $index, $bound {
                die "bound $index must contain (lower, upper)" unless $bound.elems == 2;
                (@lower[$index], @upper[$index]) = $bound.List;
            }
        }
        else {
            @lower = $value.Array;
        }
    }
    for ^$columns -> $index {
        die "Lower bound $index must be real or -Inf." unless @lower[$index] ~~ Real:D;
        die "Upper bound $index must be real or Inf." unless @upper[$index] ~~ Real:D;
        die "Lower bound exceeds upper bound at index $index." if @lower[$index] > @upper[$index];
    }
    return %(lower => @lower.Array, upper => @upper.Array);
}

sub domains-data($value, Int:D $columns --> Array:D) {
    my @domains = $value ~~ Str:D ?? ($value xx $columns) !! do {
        die 'Domains must be a domain name or positional collection.'
        unless $value ~~ Positional:D;
        
        die "Domains has {$value.elems} entries; expected $columns."
        unless $value.elems == $columns;

        $value.Array;
    };

    die 'Domains must contain only Reals or Integers.'
    unless @domains.all eq any('Reals', 'Integers');

    return @domains.Array;
}

#| Minimize c.x subject to the supplied linear constraints and variable bounds.
sub linear-programming(
    $c,
    $m,
    Positional:D $b,
    $bounds = Whatever,
    $domains = 'Reals',
    Str:D :$method = 'simplex',
    :$tolerance = Whatever,
    --> Array:D
) is export {
    my @c = numeric-vector($c, 'c');
    die 'The first argument must not be empty.' unless @c.elems;

    die 'Method must be "simplex", "dual-simplex", or "interior-point".'
    unless $method eq any('simplex', 'dual-simplex', 'interior-point');

    die 'Tolerance must be a positive real number or Whatever.'
    unless $tolerance ~~ Whatever || ($tolerance ~~ Real:D && $tolerance > 0);

    die 'The second argument is expected to be a sparse matrix or a dense matrix.'
    unless $m ~~ Math::SparseMatrix:D || is-matrix($m);

    my @rows = matrix-rows($m, @c.elems);
    # [[],] is the documented sentinel for a problem that has bounds but no matrix constraints.
    @rows = [] if !$b.elems && @rows.elems == 1 && @rows[0].elems == 0;
    for @rows.kv -> $row-number, @row {
        die "Row $row-number of m has {@row.elems} entries; expected {@c.elems}."
        unless @row.elems == @c.elems;
    }
    my %constraints = constraint-data($b, @rows.elems);
    my %bounds = bounds-data($bounds, @c.elems);
    my @domains = domains-data($domains, @c.elems);

    my %problem =
        :@c,
        :@rows,
        |%constraints,
        |%bounds,
        :@domains,
        :$method;

    %problem<tolerance> = $tolerance
    unless $tolerance ~~ Whatever;

    return solve-linear-program(%problem);
}
