

## First version of `linear-programming`

```text
Tell me the implementation steps of the sub `linear-programming` described in "./docs/LinearProgramming.md"
in the module "Math::Optimization".
The directory "./lib/Math/Backends" is used to have the "COIN-OR" backend, that uses the Raku package "COIN-OR".
```

## Sparse constraint matrices

```text
The Raku package "COIN-OR" supports the use of constraint matrices given as sparse matrices.
The corresponding method of the class `COIN-OR::Model` is `load-problem`.
The Raku package "Math::SparseMatrix" has a conversion method `to-csc`.
When the sub `linear-programming` of this package is given a `Math::SparseMatrix:D` object as 
a second argument then `load-problem` should be used by COIN-OR's backend.
Tell me your plan to implement this -- do not implement anything yet.
```       