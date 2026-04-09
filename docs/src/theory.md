# Theory

This page presents the mathematical framework underlying ViscoAnalysis.jl.
The models and equations follow the methodology established at [IFSTTAR/Gustave Eiffel University](https://viscoanalyse-database.ifsttar.fr/) for the characterisation of bituminous materials.

---

## 1. Complex Modulus

The mechanical behaviour of a linear viscoelastic material under sinusoidal loading
at angular frequency ``\omega`` is fully characterised by the **complex modulus**:

```math
E^*(\omega) = |E^*(\omega)|\, e^{i\varphi(\omega)}
            = E_1(\omega) + i\, E_2(\omega)
```

| Quantity | Symbol | Definition |
|----------|--------|-----------|
| Magnitude | ``|E^*|`` | ``\sqrt{E_1^2 + E_2^2}`` |
| Phase angle | ``\varphi`` | ``\arctan(E_2 / E_1)`` |
| Storage modulus | ``E_1`` | ``|E^*|\cos\varphi`` |
| Loss modulus | ``E_2`` | ``|E^*|\sin\varphi`` |

The symbol ``M^*`` is used in the general case where the modulus may be either a
tensile-compression modulus ``E^*`` or a shear modulus ``G^*``.

---

## 2. Time-Temperature Superposition (TTS)

Bituminous materials are **thermo-rheologically simple**: the frequency response at
temperature ``T`` can be mapped onto the response at a reference temperature ``T_\text{ref}``
by a multiplicative shift of the frequency axis.

The **reduced angular frequency** is:

```math
\omega_\text{r} = a_T(T) \cdot \omega
```

where ``a_T`` is the **shift factor** (dimensionless).

### 2.1 Shift factor estimation (LCPC method)

The shift factor between two successive temperatures is estimated from the
Booij–Thoone approximation:

```math
\varphi(\omega) \approx \frac{\pi}{2}\,
    \frac{\mathrm{d}\log|M^*(\omega)|}{\mathrm{d}\log\omega}
```

This gives:

```math
\log_{10} a_{T_i,T_\text{ref}}
= \sum_{T_j = T_\text{ref}}^{T_i}
  \frac{\log|M^*(T_j,\omega)| - \log|M^*(T_{j+1},\omega)|}
       {\bar{\varphi}^{T_j, T_{j+1}}(\omega) \cdot \pi/2 / 90}
```

where ``\bar{\varphi}`` is the average phase angle between temperatures ``T_j``
and ``T_{j+1}``.

### 2.2 WLF equation

The shift factors are fitted by the **Williams–Landel–Ferry (WLF)** equation:

```math
\log_{10} a_T(T) = \frac{-C_1 (T - T_\text{ref})}{C_2 + T - T_\text{ref}}
```

``C_1`` and ``C_2`` are material constants that depend on the choice of reference
temperature. They are related to an alternative reference ``T_\text{ref}'`` by the
exact transformation:

```math
C_2^{\text{new}} = C_2^{\text{old}} + T_\text{ref}^\text{new} - T_\text{ref}^\text{old}
```

```math
C_1^{\text{new}} = \frac{C_1^{\text{old}}\, C_2^{\text{old}}}{C_2^{\text{new}}}
```

### 2.3 Equivalent temperature

The **inverse WLF** gives the temperature at which frequency ``\omega`` is
equivalent to ``\omega_c`` measured at ``T_\text{ref}``:

```math
T_\text{eq} =
\frac{T_\text{ref}\, C_1 - \bigl(\log_{10}\omega_c - \log_{10}\omega\bigr)
     (C_2 - T_\text{ref})}
     {C_1 + \bigl(\log_{10}\omega_c - \log_{10}\omega\bigr)}
```

---

## 3. Rheological Models

All models express the complex modulus as a function of the complex variable
``p = i\omega``. The relaxation time ``\tau`` is temperature-dependent through the
WLF shift: ``\tau(T) = \tau(T_\text{ref}) / a_T(T)``.

### 3.1 2S2P1D model

The **2S2P1D model** (2 Springs, 2 Parabolic elements, 1 Dashpot) was introduced by
Olard & Di Benedetto (2003). It is the reference model for bituminous materials.

```math
\boxed{
E^*(p) = E_\infty + \frac{E_0 - E_\infty}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h} + (p\beta\tau)^{-1}}
}
```

**Mechanical analogy:**

```
  ──[E∞]──────────────────────────────────────────────
             │
         ┌───┴───┐
         │       │
      [E₀-E∞]   ─[δ, k]─ [h] ─ [β] ─
         │       │
         └───┬───┘
             │
  ─────────────────────────────────────────────────────
```

**Parameters:**

| Symbol | Name | Unit | Constraint |
|--------|------|------|-----------|
| ``E_\infty`` | Glassy (high-freq.) modulus | MPa | ``E_\infty > E_0`` |
| ``E_0`` | Static (zero-freq.) modulus | MPa | ``E_0 > 0`` |
| ``\delta`` | Shape parameter | — | ``\delta > 0`` |
| ``\tau`` | Relaxation time at ``T_\text{ref}`` | s | ``\tau > 0`` |
| ``k`` | Low-freq. fractional exponent | — | ``0 < k < h`` |
| ``h`` | High-freq. fractional exponent | — | ``k < h \leq 1`` |
| ``\beta`` | Dashpot coefficient | — | ``\beta > 0`` |

**Asymptotic behaviour:**

```math
\lim_{\omega \to \infty} |E^*| = E_\infty, \qquad
\lim_{\omega \to 0} |E^*| = E_0, \qquad
\lim_{\omega \to 0} \varphi = 90° \cdot k
```

---

### 3.2 Huet-Sayegh model (HS)

The **Huet-Sayegh model** is obtained by removing the dashpot from 2S2P1D
(``\beta \to \infty``). It is appropriate when low-frequency viscous flow is
negligible.

```math
\boxed{
E^*(p) = E_\infty + \frac{E_0 - E_\infty}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h}}
}
```

This model has **6 parameters**: ``E_\infty, E_0, \delta, \tau, k, h``.

At low frequencies the phase angle tends to **zero** (purely elastic behaviour),
unlike 2S2P1D which tends to 90° × k.

---

### 3.3 1S2P1D model

The **1S2P1D model** (1 Spring, 2 Parabolic, 1 Dashpot) removes the glassy spring
``E_\infty``, effectively setting ``E_\infty \to \infty``. It is used for materials
that do not exhibit a clear glassy plateau.

```math
\boxed{
E^*(p) = \frac{E_0}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h} + (p\beta\tau)^{-1}}
}
```

This model has **6 parameters**: ``E_0, \delta, \tau, k, h, \beta``.

---

### 3.4 Huet model (1S2P)

The **Huet model** combines the 1S2P1D restriction (``E_\infty \to \infty``) with
the Huet-Sayegh restriction (``\beta \to \infty``):

```math
\boxed{
E^*(p) = \frac{E_0}
         {1 + \delta\,(p\tau)^{-k} + (p\tau)^{-h}}
}
```

This model has **5 parameters**: ``E_0, \delta, \tau, k, h``.

---

### 3.5 Model comparison

| Model | Parameters | ``E_\infty`` | Dashpot |
|-------|-----------|:---:|:---:|
| 2S2P1D | 7 | yes | yes |
| Huet-Sayegh | 6 | yes | no |
| 1S2P1D | 6 | no | yes |
| Huet | 5 | no | no |

---

### 3.6 Generalised Maxwell model

The **Generalised Maxwell (Prony series)** model sums ``N`` Maxwell branches:

```math
G^*(p) = E_1 + \sum_{i=2}^{N} \frac{E_i\, \tau_i\, p}{1 + \tau_i\, p}
```

where ``E_i`` are partial stiffnesses and ``\tau_i`` are relaxation times.
This model is often used as a reference representation after conversion from
2S2P1D parameters.

---

## 4. Kramers-Kronig Relations

For any causal linear viscoelastic material (i.e. the response cannot precede the
loading), the storage and loss parts of the complex modulus are linked by the
**Kramers-Kronig (KK) relations**. The BT2 approximation (Booij & Thoone 1982)
provides a practical check:

```math
\varphi(\omega) \approx \frac{\pi}{2}\,
\frac{\mathrm{d}\log|M^*(\omega)|}{\mathrm{d}\log\omega}
```

The relative KK error at each frequency is:

```math
\varepsilon_\text{KK}(\omega) =
\left|\frac{\varphi(\omega)/90}
           {\mathrm{d}\log|M^*|/\mathrm{d}\log\omega} - 1\right|
```

A good dataset should have ``\varepsilon_\text{KK} \lesssim 5\%`` across the entire
frequency range. Larger errors typically indicate measurement artefacts or
non-linear behaviour.

---

## 5. Identification Objective Function

Model parameters are identified by minimising a **log-frequency-weighted
least-squares** objective over the complex master curve:

```math
J = \sum_{i=1}^{N} \Delta\log\omega_i
    \left|1 - \frac{E^*_\text{model}(\omega_i)}{E^*_\text{data}(\omega_i)}\right|^2
```

where ``\Delta\log\omega_i`` is the local frequency spacing in log scale, giving
equal importance to each frequency decade regardless of sampling density.

The optimisation uses **derivative-free algorithms** from NLopt:

| Model | Algorithm | Max evaluations |
|-------|-----------|----------------|
| 2S2P1D | `:LN_SBPLX` | 100 000 |
| 1S2P1D | `:LN_NELDERMEAD` | 500 000 |
| Huet-Sayegh | `:LN_NELDERMEAD` | 500 000 |

---

## 6. Representation Diagrams

Three standard diagrams are used to visualise complex modulus data:

### Black diagram
``|E^*|`` (log scale) versus ``\varphi``. A material that follows TTS traces a
**unique curve** independent of temperature, making the Black diagram a powerful
way to validate superposition.

### Cole-Cole diagram
Loss modulus ``E_2`` versus storage modulus ``E_1`` on log-log axes. Like the Black
diagram, a TTS-valid material traces a single arch.

### Isothermal / isochronal sweeps
- **Isothermal**: ``|E^*|`` and ``\varphi`` as a function of frequency at fixed
  temperature.
- **Isochronal**: ``|E^*|`` and ``\varphi`` as a function of temperature at fixed
  frequency.

---

## References

- Olard, F. & Di Benedetto, H. (2003). *General "2S2P1D" model and relation between the linear viscoelastic behaviours of bituminous binders and mixes.* Road Materials and Pavement Design, 4(2), 185–224.
- Di Benedetto, H., Delaporte, B. & Sauzéat, C. (2007). *Three-dimensional linear behavior of bituminous materials: experiments and modeling.* International Journal of Geomechanics, ASCE, 7(2), 149–157.
- Booij, H.C. & Thoone, G.P.J.M. (1982). *Generalization of Kramers-Kronig transforms and some approximations of relations between viscoelastic quantities.* Rheologica Acta, 21, 15–24.
- Williams, M.L., Landel, R.F. & Ferry, J.D. (1955). *The temperature dependence of relaxation mechanisms in amorphous polymers and other glass-forming liquids.* Journal of the American Chemical Society, 77(14), 3701–3707.
