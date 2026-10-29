use v6.d;

unit module Math::Backends::COIN-OR;

use COIN-OR;

sub load-sparse-problem($model, %problem --> Nil) {
    my $matrix = %problem<sparse-matrix>;
    my $csc = $matrix.to-csc($matrix.core-matrix);

    my @row-lower;
    my @row-upper;
    for %problem<senses>.kv -> $row, $sense {
        my $rhs = %problem<rhs>[$row];
        @row-lower.push($sense == -1 ?? -Inf !! $rhs);
        @row-upper.push($sense == 1 ?? Inf !! $rhs);
    }

    my @integer-columns;
    for %problem<domains>.kv -> $column, $domain {
        @integer-columns.push($column) if $domain eq 'Integers';
    }

    $model.load-problem(
        columns => $csc.ncol,
        rows => $csc.nrow,
        starts => $csc.col-ptr,
        indexes => $csc.row-index,
        values => $csc.values,
        column-lower => %problem<lower>,
        column-upper => %problem<upper>,
        objective => %problem<c>,
        row-lower => @row-lower,
        row-upper => @row-upper,
        integer-columns => @integer-columns,
    );
}

# Translate Math::Optimization's normalized problem representation into
# the small, deliberately solver-oriented API exposed by COIN-OR.
sub solve-linear-program(%problem --> Array:D) is export {
    my $model = Model.new(:name<Math::Optimization>);
    LEAVE $model.close;

    $model.log-level(0);
    $model.minimize;

    # CBC applies an LP method as part of branch-and-bound itself for MIPs.
    # In addition, its C interface does not safely accept primalSimplex for a
    # mixed-integer model on all supported CBC builds.
    my $is-mip = %problem<domains>.grep(* eq 'Integers').elems;
    $model.lp-method(%problem<method>) unless $is-mip;

    if %problem<tolerance>:exists {
        my $tolerance = %problem<tolerance>;
        $model.primal-tolerance($tolerance);
        $model.dual-tolerance($tolerance);
        $model.integer-tolerance($tolerance) if $is-mip;
    }

    if %problem<sparse-matrix>:exists {
        load-sparse-problem($model, %problem);
    } else {
        for ^%problem<c>.elems -> $column {
            $model.add-column(
                "x$column",
                :lower(%problem<lower>[$column]),
                :upper(%problem<upper>[$column]),
                :objective(%problem<c>[$column]),
                :integer(%problem<domains>[$column] eq 'Integers'),
            );
        }

        my %sense = 1 => '>=', 0 => '=', -1 => '<=';
        for %problem<rows>.kv -> $row-number, @row {
            my @columns;
            my @coefficients;
            for @row.kv -> $column, $coefficient {
                next if $coefficient == 0;
                @columns.push($column);
                @coefficients.push($coefficient);
            }
            $model.add-row(
                "r$row-number",
                @columns,
                @coefficients,
                %sense{%problem<senses>[$row-number]},
                %problem<rhs>[$row-number],
            );
        }
    }

    die "COIN-OR did not prove an optimal solution (status {$model.status})"
    unless $model.solve;

    return $model.solution;
}
