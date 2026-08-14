# Ne500 minimum species

A continuous formula for the minimum number of species a country needs to
monitor in order to report the CBD Headline Indicator A.4 (*proportion of
populations with an effective population size greater than 500*) at an
acceptable level of accuracy.

```
n = n₀ · N / (N − 1 + n₀)        with  n₀ = (k · σ / T)²  =  122.34
```

| Symbol | Meaning | Value |
|---|---|---|
| `N` | species pool size (all species to be represented) | per taxon |
| `n` | species to monitor | the answer |
| `σ` | SD of species-level indicator values | 0.394826 |
| `T` | tolerated deviation on the 0–1 indicator scale | 0.05 |
| `k` | criterion constant, in units of standard error | 1.40069 |
| `n₀` | requirement for an infinitely large pool | 122.34 |

`σ` is the only quantity taken from data. `T` is a choice. `k` follows
mathematically once a criterion is chosen.

---

## Why this repository exists

Hébert, Pollock and Hoban (2026, *Biological Conservation* 317: 111824) is the
only study that answers how much monitoring the Ne > 500 indicator needs. Their
Fig. 6 reports the requirement in bins of 100 species: 56 % for pools under 100
species, 31 % for pools around 200, 23 % for pools of 300 and above.

Binned values are awkward to apply nationally. A pool of 299 species receives
31 % and a pool of 301 species receives 23 %, an eight point gap for a two
species difference. There is also no value shown for pools between 100 and 200
species. Korea's eleven taxonomic groups range from 30 to 712 species, so five
bars cannot be applied consistently.

This repository derives the same requirement as a continuous function of pool
size, using the same criterion and the same tolerance as the original study.

---

## Relationship to Hébert et al. (2026)

The original code and outputs are at
[katherinehebert/Ne_scenarios](https://github.com/katherinehebert/Ne_scenarios)
(MIT License). This repository does **not** modify or redistribute that code.

| | Hébert et al. (2026) | This repository |
|---|---|---|
| Source data | 583 species-level indicator values | same |
| Tolerance `T` | 0.05 | same |
| Criterion | mean + SD of the absolute error | same |
| Method | Monte Carlo, 15 million draws | finite-population sample-size formula |
| Output | five binned bars | continuous function of `N` |
| Pool-size ceiling | 583, or 5000 with a bootstrapped pool | none |

Continuous application was agreed with the corresponding author.

The two output files from the original repository are used here **for
validation only** (`R/06`, `R/07`). They are not needed to derive the formula.

---

## Method in three steps

1. **σ from the data.** The 583 species-level indicator values of
   Mastretta-Yanes et al. (2024b) have a standard deviation of 0.394826. All 583
   values are used, so this is a measurement rather than an estimate.
2. **k from the criterion.** The absolute sampling error follows a half-normal
   distribution, whose mean and SD are fixed multiples of the standard error:
   `√(2/π) = 0.79788` and `√(1−2/π) = 0.60281`. The criterion of Hébert et al.
   is their sum, so `k = 1.40069`. No data enters this step.
3. **n₀, then the finite-population correction.** Setting `k · SE ≤ T` and
   solving for `n` gives `n₀ = (kσ/T)² = 122.34` for an infinite pool, and
   `n = n₀N/(N−1+n₀)` for a finite one.

Because `n₀` is an upper bound, the required *count* saturates near 123 species
however large the pool grows, while the required *percentage* keeps falling.
This is why a percentage is a poor unit for comparing taxa of different sizes.

---

## Validation

| Check | Method | Result |
|---|---|---|
| Normal approximation holds | Draw samples directly from the 583 values, no formula, 5 pool sizes | within 1 species |
| Matches published results | 100 pool sizes from Fig. 6 output | mean difference −0.7 species, 94 % within 5 |
| Holds beyond 583 species | 222 points from Fig. S7 output (`N` = 584–5000) | mean difference +0.36 species, 94 % within 5 |

The residual scatter is Monte Carlo noise in the original simulations, not error
in the formula: Hébert et al. drew each species pool once per pool size.

---

## Repository layout

```
R/
  00_setup.R            packages, paths, settings
  01_download_data.R    fetch the three source files
  02_sigma.R            σ from the 583 indicator values
  03_constants.R        k, and n₀
  04_formula.R          the formula, as a reusable function
  05_validate_mc.R      validation 1: direct sampling from raw data
  06_validate_hebert.R  validation 2: against Fig. 6 output
  07_validate_largeN.R  validation 3: against Fig. S7 output, N > 583
  08_figures.R          figures
  09_apply_korea.R      worked example: eleven Korean taxonomic groups
data/
  korea_species_pools.csv
```

Run the scripts in order. Each one is self-contained and can be read on its own;
`00_setup.R` and `04_formula.R` are sourced by the others as needed. There is no
pipeline script, because the point of the repository is the derivation and its
checks rather than a batch job.

To apply the method elsewhere, only `R/04_formula.R` is needed:

```r
source("R/04_formula.R")
n_species_needed(N = 712)                      # 105
n_species_needed(N = 712, k = qnorm(0.975))    # 180, for a 95 % criterion
```

---

## Assumptions

- **σ is borrowed.** 0.394826 comes from a nine country, eleven taxon pool. It is
  not Korea specific and not taxon specific. The design of the original study is
  to provide a value usable where national data are insufficient, which is the
  situation almost everywhere.
- **The criterion is not a 95 % bound.** Mean plus SD corresponds to about 84 %
  coverage of the absolute error. The phrase "5 % risk of error" in the paper
  refers to the *size* of the tolerated error, not the frequency of exceeding it.
  Both criteria are reported here.
- **Only species selection error is covered.** The paper's Steps 1 and 2
  (population level thresholding, and sampling populations within a species)
  contribute further error that is not added in here or in the original study.
- **The Korean pools are Red List assessed species.** They are used as a proxy
  for the full national pools; assessed species are not a random sample of all
  species with respect to the indicator.

---

## Citation

If you use this repository, please cite the two underlying sources:

> Hébert, K., Pollock, L., Hoban, S. (2026) How much monitoring is needed to
> reliably track progress towards genetic diversity targets?
> *Biological Conservation* 317: 111824. https://doi.org/10.1016/j.biocon.2026.111824

> Mastretta-Yanes, A. et al. (2024) Multinational evaluation of genetic diversity
> indicators for the Kunming-Montreal Global Biodiversity Framework.
> *Ecology Letters* 27: e14461. Data: https://doi.org/10.5061/dryad.bk3j9kdkm

---

## Funding

National Institute of Biological Resources (NIBR), Republic of Korea.
Project NIBR202605102.

## License

MIT
