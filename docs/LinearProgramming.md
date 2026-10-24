# `linear-programming`

----

## Usage

### `linear-programming(c,m,b)`

finds a vector `x` that minimizes the quantity `c.x` subject to the constraints `m.x ≥ b` and `x ≥ 0`.

### `linear-programming(c,m,[(b[0],s[0]),(b[1],s[1]), ...])`

finds a vector x that minimizes `c.x` subject to `x ≥ 0` and linear constraints specified by the matrix `m` and the pairs `(b[i],s[i])`. 
For each row `m[i]` of `m`, the corresponding constraint is `m[i].x ≥ b[i]` if `s[i]==1`, or `m[i].x == b[i]` if `s[i]==0`, or `m[i].x ≤ b[i]` if `s[i]==-1`.

### `linear-programming(c,m,b,l)`

minimizes `c.x` subject to the constraints specified by `m` and `b` and `x ≥ l`.

### `linear-programming(c,m,b,[l[0],l[1],...])`

minimizes `c.x` subject to the constraints specified by `m` and `b` and `x[i] ≥ l[i]`.

### `linear-programming(c,m,b,[(l[0],u[0]),(l[1],u[1]),...])`

minimizes `c.x` subject to the constraints specified by `m` and `b` and `l[i] ≤ x[i] ≤ u[i]`.

### `linear-programming(c,m,b,lu,dom)`

takes the elements of x to be in the domain `dom`, either "Reals" or "Integers".

### `linear-programming(c,m,b,lu,[dom[0],dom[1],...])`

takes `x[i]` to be in the domain `dom[i]`.

## Details and Options

* All entries in the vectors `c` and `b` and the matrix `m` must be real numbers.
* The bounds `l[i]` and `u[i]` must be real numbers or `Infinity` or `-Infinity`.
* `None` is equivalent to specifying no bounds.
* `linear-programming` gives exact rational number or integer results if its input consists of exact rational numbers.
* `linear-programming` returns unevaluated if no solution can be found.
* `linear-programming` finds approximate numerical results if its input contains approximate numbers. The option `tolerance` specifies the tolerance to be used for internal comparisons. The default is `tolerance =>> Whatever`, which does exact comparisons for exact numbers, and uses tolerance `1e-6` for approximate numbers.
* `SparseArray` objects can be used in `linear-programming`.
* With `method => "interior-point"`, `linear-programming` uses interior point methods.

---

## Basic Examples

Minimize `x+y`, subject to constraint `x + 2 * y ≥ 3` and implicit non-negative constraints:

```raku
use Math::Optimization;

linear-programming([1, 1], [(1, 2),], [3,])
```
```
# [0 1.5]
```

`linear-optimization` can be used instead of `linear-programming`: 

```raku, eval=FALSE
linear-optimization('x + y', ('x + 2 * y >= 3', 'x >= 0', 'y >= 0'), <x y>)
```

Solve the problem with equality constraint `x + 2 * y = 3` and implicit non-negative constraints:

```raku
linear-programming([1, 1], [(1, 2),], [(3, 0),])
```
```
# [0 1.5]
```

Use `linear-optimization` to solve the problem:

```raku, eval=FALSE
linear-optimization('x + y', ('x + 2 y == 3', 'x >= 0', 'y >= 0'), <x y>)
```

Solve the problem with equality constraint `x + 2 * y ≤ 3`  and implicit non-negative constraints:

```raku
linear-programming([1, 1], [(1, 2),], [(3, -1),])
```
```
# [0 0]
```

Use `linear-optimization` to solve the problem:

```raku, eval=FALSE
linear-optimization('x + y', ('x + 2 y ≤ 3', 'x >= 0', 'y >= 0'), <x y>)
```

----

## Scope

Minimize `x + y`, subject to constraint `x + 2 * y ≥ 3` and lower bounds `x ≥ -1`, `y ≥ -1`:

```raku
linear-programming([1, 1], [(1, 2),], [3,], [-1, -1])
```
```
# [-1 2]
```

Minimize `x + y`, subject to constraint `x + 2 * y ≥ 3` and lower bounds `2 ≥ x ≥ -1`, `1 ≥ y ≥ -1`:

```raku
linear-programming([1, 1], [(1, 2),], [3,], [[-1, 2], [-1, 1]])
```
```
# [1 1]
```

Minimize `2 * x - 3 * y `, subject to constraint `-x - 2 * y ≤ 3` and upper bounds `x ≤ 1`, `y ≤ 1`:

```raku
linear-programming([2, -3], [(-1, -2),], [[3, -1], ], [[-Inf, 1], [-Inf, 1]])
```
```
# [-5 1]
```

Minimize `x + y`, subject to constraint `5 * x + 2 * y ≥ 3` and implicit non-negative constraints:

```raku
linear-programming([1, 1], [[5, 2],], [3])
```
```
# [0.6 0]
```

Minimize `2 * x + 3 * y` subject to bounds `x ≥ -1` and `y ≥ -2` only:

```raku
linear-programming([2, 3], [[],], [], [-1, -2])
```
```
# [-1 -2]
```

Solve the same kind of problem, but with both variables integers:

```raku
linear-programming([1.0, 1.0], [[5.0, 2.0],], [3.0,], Whatever, 'Integers')
```
```
# [1 0]
```

Solve the same problem, but with the first variable an integer:

```raku
linear-programming([1, 1], [[5, 2],], [3,], Whatever, <Integers Reals>)
```
```
# [1 0]
```

---

## Options

### Method

Here is a constraint matrix:

```raku
sub dense-matrix(Int:D $n, Int:D $m) {
    (^$n).map(-> $i {
        (^$m).map(-> $j {
            $j == $i ?? 1e0 !! $j == $i + 1 ?? 2e0 !! 0e0
        }).Array
    }).Array
}
```
```
# &dense-matrix
```

`"interior-point"` is faster than `"simplex"`:

```raku
my $start = now;
linear-programming((1 ... 200).Array, dense-matrix(100, 200), (1 ... 100).Array, method => "simplex");
my $end = now;
"Timing {$end - $start} s"
```
```
# Timing 0.046603606 s
```

```raku
my $start = now;
linear-programming((1 ... 200).Array, dense-matrix(100, 200), (1 ... 100).Array, method => "interior-point");
my $end = now;
"Timing {$end - $start} s"
```
```
# Timing 0.036862876 s
```

### Tolerance

If an approximated solution is sufficient, a loose Tolerance option makes the solution process faster:

```raku
my $start = now;
linear-programming((1 ... 200).Array, dense-matrix(100, 200), (1 ... 100).Array, method => "simplex", tolerance => 1e-6);
my $end = now;
"Timing {$end - $start} s"
```
```
# Timing 0.035995874 s
```

```raku
my $start = now;
linear-programming((1 ... 200).Array, dense-matrix(100, 200), (1 ... 100).Array, method => "simplex", tolerance => 1);
my $end = now;
"Timing {$end - $start} s"
```
```
# Timing 0.035387664 s
```

---

## Neat Examples

This expresses the Klee–Minty problem of dimension n in `linear-programming` syntax:

```raku
sub KleeMinty(Int:D $n) {
    my @c = (1 .. $n).map({ -(10 ** $n) - $_ }).Array;

    my @m = (1 .. $n).map(-> $i {
        my @row = $i > 1
                ?? (1 .. ($i - 1)).map({ 2 * (10 ** $i) - $_ }).Array
                !! [];

        @row.push(1);
        @row.append(0 xx ($n - $i));
        @row.Array
    }).Array;

    my @b = (1 .. $n).map(-> $i {
        [100 ** $i - 1, -1]
    }).Array;

    [@c, @m, @b]
}
```
```
# &KleeMinty
```

The simplex algorithm converges very quickly:

```raku
my $start = now;
linear-programming(|KleeMinty(9), );
my $end = now;
"Timing {$end - $start} s"
```
```
# Timing 0.003006215 s
```

But with a larger matrices but the "simplex" and "interior-point" methods do not converge: 

```raku
my $start = now;
linear-programming(|KleeMinty(16), method => 'simplex');
my $end = now;
"Timing {$end - $start} s"
```
```
#ERROR: COIN-OR did not prove an optimal solution (status -1)
# Nil
```