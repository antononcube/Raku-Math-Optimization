use v6.d;

unit module Math::Backends::COIN-OR;

use COIN-OR;

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

    die "COIN-OR did not prove an optimal solution (status {$model.status})"
    unless $model.solve;

    return $model.solution;
}
