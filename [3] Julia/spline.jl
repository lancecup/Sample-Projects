struct spline
    n::Int64
    x::Vector{Float64}
    y::Vector{Float64}
    ydp::Vector{Float64}
end   
 
# Create an equally‐spaced grid of points between xlow and xhigh.
function creategrid(xlow, xhigh, npts)
    xinc = (xhigh - xlow) / (npts - 1)
    return collect(xlow:xinc:xhigh)
end   

function tridag(a, b, c, r)
    toler = 1.0e-12
    n     = length(a)
    u     = zeros(n)
    gam   = zeros(n)

    bet    = b[1]
    u[1]   = r[1] / bet
    for j in 2:n
        gam[j] = c[j - 1] / bet
        bet     = b[j] - a[j] * gam[j]
        if abs(bet) <= toler
            error("Failure in subroutine tridag.")
        end
        u[j] = (r[j] - a[j] * u[j - 1]) / bet
    end
    for j in (n - 1):-1:1
        u[j] -= gam[j + 1] * u[j + 1]
    end

    return u
end 

function makespline(fpts, flevel)
    zero = 0.0
    one  = 1.0

    npts = length(fpts)
    a    = zeros(npts)
    b    = zeros(npts)
    c    = zeros(npts)
    r    = zeros(npts)

    an = -one
    c1 = -one

    # Natural spline boundary conditions
    a[1]     = zero
    b[1]     = one
    c[1]     = c1
    r[1]     = zero

    a[npts]  = an
    b[npts]  = one
    c[npts]  = zero
    r[npts]  = zero

    for i in 2:(npts - 1)
        a[i] = (fpts[i]     - fpts[i - 1]) / 6
        b[i] = (fpts[i + 1] - fpts[i - 1]) / 3
        c[i] = (fpts[i + 1] - fpts[i    ]) / 6
        r[i] = (flevel[i + 1] - flevel[i]) / (fpts[i + 1] - fpts[i]) -
               (flevel[i]     - flevel[i - 1]) / (fpts[i]     - fpts[i - 1])
    end

    vdp = tridag(a, b, c, r)
    return spline(npts, fpts, flevel, vdp)
end

function interp(x, yspline; calcy = true, calcyp = false, calcydp = false)
    one  = 1.0
    npts = yspline.n

    klo = 1
    khi = npts
    while (khi - klo) > 1
        k = fld(khi + klo, 2)
        if yspline.x[k] > x
            khi = k
        else
            klo = k
        end
    end

    h    = yspline.x[khi] - yspline.x[klo]
    a    = (yspline.x[khi] - x) / h
    b    = (x - yspline.x[klo])     / h
    asq  = a * a
    bsq  = b * b

    if calcy
        y = a * yspline.y[klo] + b * yspline.y[khi] +
            ((asq * a - a) * yspline.ydp[klo] +
             (bsq * b - b) * yspline.ydp[khi]) * (h * h) / 6
    else
        y = 0.0
    end

    if calcyp
        yp = (yspline.y[khi] - yspline.y[klo]) / h -
             (3 * asq - one) / 6 * h * yspline.ydp[klo] +
             (3 * bsq - one) / 6 * h * yspline.ydp[khi]
    else
        yp = 0.0
    end

    if calcydp
        ydp = a * yspline.ydp[klo] + b * yspline.ydp[khi]
    else
        ydp = 0.0
    end

    return (y, yp, ydp)
end
