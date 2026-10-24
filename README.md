# Math::Optimization

Raku package for mathematical optimization algorithms.

---

## Installation

Make sure the Raku package ["COIN-OR"](https://github.com/antononcube/Raku-COIN-OR), [AAp1], is installed.

Install from Zef ecosystem:

```
zef install Math::Optimization
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-Math-Optimization.git
```

---

## Usage examples

### `linear-programming`

Minimize `x + y`, subject to constraint `x + 2 * y ≥ 3` and lower bounds `2 ≥ x ≥ -1`, `1 ≥ y ≥ -1`:

```raku
linear-programming([1, 1], [(1, 2),], [3,], [[-1, 2], [-1, 1]])
```
```
# [1 1]
```

See more examples in the Markdown document ["LinearProgramming.md"](./docs/LinearProgramming.md).
(Obtained by executing ["LinearProgramming-work.md"](./docs/LinearProgramming-work.md) by the script `file-code-chunks-eval` 
provided by the package ["Text::CodeProcessing"](https://github.com/antononcube/Raku-Text-CodeProcessing), [AAp2].)

---

## References

[AAp1] Anton Antonov, 
[COIN-OR, Raku package](https://github.com/antononcube/Raku-COIN-OR),
(2026),
[GitHub/antononcube](https://github.com/antononcube).

[AAp2] Anton Antonov,
[Text::CodeProcessing, Raku package](https://github.com/antononcube/Raku-Text-CodeProcessing),
(2026),
[GitHub/antononcube](https://github.com/antononcube).