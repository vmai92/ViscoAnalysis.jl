# Theoretical Background

This page summarises the physics and mathematics behind the algorithms implemented
in ViscoAnalysis.jl.

---

## 1. Linear viscoelasticity and complex modulus

A linear viscoelastic material subject to a sinusoidal strain
``\varepsilon(t) = \varepsilon_0 \, e^{i\omega t}``
responds with a sinusoidal stress
``\sigma(t) = \sigma_0 \, e^{i(\omega t + \varphi)}``.
The ratio defines the **complex modulus**:

```math
E^*(\omega) = \frac{\sigma_0}{\varepsilon_0} e^{i\varphi}
            = E_1(\omega) + i\, E_2(\omega)
```

where:
- ``E_1 = |E^*|\cos\varphi`` is the **storage modulus** (elastic part),
- ``E_2 = |E^*|\sin\varphi`` is the **loss modulus** (viscous part),
- ``\varphi`` is the **phase angle** (loss angle),
- ``|E^*| = \sqrt{E_1^2 + E_2^2}`` is the **complex modulus norm**.

DMA experiments directly measure ``|E^*|`` and ``\varphi`` at discrete frequencies
and temperatures.

---

## 2. Time-temperature superposition

Bituminous materials are **thermorheologically simple**: a change in temperature is equivalent to a shift in the frequency axis.  This is expressed by the
**shift factor** ``a_T``:

```math
E^*(\omega, T) = E^*(\omega \cdot a_T(T), T_{\text{ref}})
```

---

### Cole-Cole and Black diagrams

These are standard representation planes for comparing different materials or
temperature conditions independently of the frequency axis:

| Diagram | x-axis | y-axis | 
|---------|--------|--------|
| **Cole-Cole** | ``E_1`` (storage modulus) | ``E_2`` (loss modulus) |
| **Black** | ``\varphi`` (phase angle) | ``E^*`` (modulus norm) |

Both are parametrised by frequency; a perfect thermorheologically simple material produces a unique curve independent of temperature.

The continuity of these curves enables verification of the validity of the time–temperature equivalence principle

---

## 3. Master curve construction

The validation of the Time–Temperature Superposition principle allows for the construction of a master curve.

### Kramers-Kronig verification

For a linear viscoelastic material, the real and imaginary parts of ``E^*`` are not independent — they are related by the **Kramers-Kronig relations**. A practical consequence (Booij & Thoone, 1982) is:

```math
\frac{\varphi(\omega)}{90°} \approx \frac{d\log|E^*|}{d\log\omega}
```

ViscoAnalysis computes both sides numerically and displays them on a scatter plot.
Points lying close to the identity line ``y = x`` indicate consistent, reliable
viscoelastic measurements.

### Determination of shift factor ``a_T``

The shift factor ``a_T`` are computed incrementally from one temperature to the next using the phase angle and the modulus gradient:

```math
\log(a_T(T_i, T_{\text{ref}})) = \frac{\pi}{2}
\left(
  \sum_{k=i}^{k=\text{ref}}
  \frac{\log\!\left(|E^*(T_k,\omega)|\right) - \log\!\left(|E^*(T_{k+1},\omega)|\right)}
       {{\varphi_{\text{avr}}}^{T_{k,k+1}}}
\right)
```


### Williams-Landel-Ferry (WLF) equation

The shift factor follows the empirical WLF law:

```math
\log_{10}(a_T) = \frac{-C_1 \,(T - T_{\text{ref}})}{C_2 + T - T_{\text{ref}}}
```

The constants ``C_1`` and ``C_2`` are identified by nonlinear least-squares fitting
(using [LsqFit.jl](https://github.com/JuliaNLSolvers/LsqFit.jl)) from the
experimentally-derived shift factors.

### Change of reference temperature

WLF coefficients at one reference temperature can be exactly converted to another:

```math
C_2^{\text{new}} = C_2^{\text{old}} + (T_{\text{new}} - T_{\text{old}})
\qquad
C_1^{\text{new}} = C_1^{\text{old}} \,\frac{C_2^{\text{old}}}{C_2^{\text{new}}}
```

### Master curve

Applying the WLF shift to all isotherms sweeps collapses them onto a single
**master curve** at ``T_{\text{ref}}``:

```math
\omega_{\text{red}} = \omega \cdot a_T(T)
```

where ``\omega_{\text{red}}`` is the **reduced angular frequency** — the measured
angular frequency ``\omega`` shifted to the reference temperature ``T_{\text{ref}}``.

---

## 3. Rheological models

All three models are written in the **complex (Laplace) domain** with
``p = i\omega``.

### 3.1 2S2P1D model

The **2 Springs, 2 Parabolic elements, 1 Dashpot** model (Olard & Di Benedetto, 2003)
uses 7 parameters:

```math
E^*(p) = E_\infty + \frac{E_0 - E_\infty}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h} + \dfrac{1}{p\,\beta\,\tau}}
```

### 3.2 1S2P1D model

The **1 Spring** variant removes the high-frequency spring, so ``E_\infty`` is
absorbed into the denominato numerics (effectively ``E_\infty = 0`` for the
standalone spring term), using 6 parameters:

```math
E^*(p) = \frac{E_0}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h} + \dfrac{1}{p\,\beta\,\tau}}
```

### 3.3 Huet-Sayegh model

The **Huet-Sayegh** model (Huet, 1963; Sayegh, 1965) drops the dashpot (``\beta \to \infty``),
giving 6 parameters:

```math
E^*(p) = E_\infty + \frac{E_0 - E_\infty}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h}}
```

---

## 4. Model identification strategy

All three models are identified by **global optimisation** of a weighted least-squares objective computed on the complex master curve:

```math
J = \sum_k \Delta\log\omega_k \left|1 - \frac{E^*(\omega_k)}{E^*_{\text{exp}}(\omega_k)}\right|^2
```

The ``\Delta\log\omega`` weight ensures that every decade of frequency contributes equally regardless of the number of measurement points it contains.

| Model | Optimiser | Max evaluations | Constraint |
|-------|-----------|-----------------|-----------|
| 2S2P1D | NLopt `:LN_SBPLX` (Nelder-Mead simplex) | 100 000 | ``k < h`` |
| 1S2P1D | NLopt `:LN_NELDERMEAD` | 500 000 | ``k < h`` |
| Huet-Sayegh | NLopt `:LN_NELDERMEAD` | 500 000 | ``k < h`` |

---

## References

- Olard, F., & Di Benedetto, H. (2003). *General "2S2P1D" model and relation between the
  linear viscoelastic behaviours of bituminous binders and mixes*. Road Materials and
  Pavement Design, 4(2), 185–224.
- Huet, C. (1963). *Étude par une méthode d'impédance du comportement viscoélastique des
  matériaux hydrocarbonés*. PhD thesis, Université de Paris.
- Sayegh, G. (1965). *Contribution à l'étude des propriétés viscoélastiques des bitumes
  purs et des bétons bitumineux*. PhD thesis, Université de Paris.
- Chailleux, E., Ramond, G., Such, C., & de La Roche, C. (2006). *A mathematical-based
  master-curve construction method applied to complex modulus of bituminous materials*.
  Road Materials and Pavement Design, 7(sup1), 75–92.
- Williams, M. L., Landel, R. F., & Ferry, J. D. (1955). *The temperature dependence of
  relaxation mechanisms in amorphous polymers and other glass-forming liquids*. Journal of
  the American Chemical Society, 77(14), 3701–3707.
- Booij, H. C., & Thoone, G. P. J. M. (1982). *Generalization of Kramers-Kronig transforms
  and some approximations of relations between viscoelastic quantities*. Rheologica Acta,
  21(1), 15–24.
