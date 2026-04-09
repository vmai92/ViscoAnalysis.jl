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

## 2. Time-temperature superposition (WLF)

Bituminous materials are **thermorheologically simple**: a change in temperature
is equivalent to a shift in the frequency axis.  This is expressed by the
**shift factor** ``a_T``:

```math
E^*(\omega, T) = E^*(\omega \cdot a_T(T), T_{\text{ref}})
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

Applying the WLF shift to all isothermal sweeps collapses them onto a single
**master curve** at ``T_{\text{ref}}``:

```math
\omega_{\text{red}} = \omega \cdot a_T(T)
```

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

| Parameter | Symbol | Description |
|-----------|--------|-------------|
| `Einf` | ``E_\infty`` | Glassy (high-frequency) modulus [MPa] |
| `E0` | ``E_0`` | Static (zero-frequency) modulus [MPa] |
| `delta` | ``\delta`` | Shape parameter |
| `tauE` | ``\tau_E`` | Characteristic relaxation time [s] |
| `k` | ``k`` | Low-frequency parabolic exponent (``0 < k < h``) |
| `h` | ``h`` | High-frequency parabolic exponent (``k < h \leq 1``) |
| `beta` | ``\beta`` | Dashpot coefficient |

**Limiting behaviour:**
- ``\omega \to 0``: ``E^* \to E_0`` (purely elastic, low stiffness)
- ``\omega \to \infty``: ``E^* \to E_\infty`` (glassy, high stiffness)

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

Because there is no dashpot, this model predicts zero phase angle at very low
frequencies and cannot represent long-term creep.

### 3.4 Generalised Maxwell model

The **Generalised Maxwell** (Prony series) model is also available for use with
custom spring-dashpot chains:

```math
E^*(p) = \sum_{i} \frac{E_i\, p\,\tau_i}{1 + p\,\tau_i}
```

---

## 4. Model identification strategy

All three models are identified by **global optimisation** of a weighted
least-squares objective computed on the complex master curve:

```math
J = \sum_k \Delta\log\omega_k \left|1 - \frac{E^*(\omega_k)}{E^*_{\text{exp}}(\omega_k)}\right|^2
```

The ``\Delta\log\omega`` weight ensures that every decade of frequency contributes
equally regardless of the number of measurement points it contains.

| Model | Optimiser | Max evaluations | Constraint |
|-------|-----------|-----------------|-----------|
| 2S2P1D | NLopt `:LN_SBPLX` (Nelder-Mead simplex) | 100 000 | ``k < h`` |
| 1S2P1D | NLopt `:LN_NELDERMEAD` | 500 000 | ``k < h`` |
| Huet-Sayegh | NLopt `:LN_NELDERMEAD` | 500 000 | ``k < h`` |

---

## 5. Kramers-Kronig verification

For a linear viscoelastic material, the real and imaginary parts of ``E^*`` are
not independent — they are related by the **Kramers-Kronig relations**.
A practical consequence (Booij & Thoone, 1982 — the "BT2" approximation) is:

```math
\frac{\varphi(\omega)}{90°} \approx \frac{d\log|E^*|}{d\log\omega}
```

ViscoAnalysis computes both sides numerically and displays them on a scatter plot.
Points lying close to the identity line ``y = x`` indicate consistent, reliable
viscoelastic measurements.

---

## 6. Cole-Cole and Black diagrams

These are standard representation planes for comparing different materials or
temperature conditions independently of the frequency axis:

| Diagram | x-axis | y-axis | Scale |
|---------|--------|--------|-------|
| **Cole-Cole** | ``E_1`` (storage modulus) | ``E_2`` (loss modulus) | log-log |
| **Black** | ``\varphi`` (phase angle) | ``|E^*|`` (modulus norm) | linear-log |

Both are parametrised by frequency; a perfect thermorheologically simple material
produces a unique curve independent of temperature.

---

## References

- Di Benedetto, H., Olard, F., Sauzeat, C., & Delaporte, B. (2004). *Linear viscoelastic
  behaviour of bituminous materials: from binders to mixes*. Road Materials and Pavement
  Design, 5(sup1), 163–202.
- Olard, F., & Di Benedetto, H. (2003). *General "2S2P1D" model and relation between the
  linear viscoelastic behaviours of bituminous binders and mixes*. Road Materials and
  Pavement Design, 4(2), 185–224.
- Huet, C. (1963). *Étude par une méthode d'impédance du comportement viscoélastique des
  matériaux hydrocarbonés*. PhD thesis, Université de Paris.
- Sayegh, G. (1965). *Contribution à l'étude des propriétés viscoélastiques des bitumes
  purs et des bétons bitumineux*. PhD thesis, Université de Paris.
- Williams, M. L., Landel, R. F., & Ferry, J. D. (1955). *The temperature dependence of
  relaxation mechanisms in amorphous polymers and other glass-forming liquids*. Journal of
  the American Chemical Society, 77(14), 3701–3707.
- Booij, H. C., & Thoone, G. P. J. M. (1982). *Generalization of Kramers-Kronig transforms
  and some approximations of relations between viscoelastic quantities*. Rheologica Acta,
  21(1), 15–24.
