toterm(s1::Term, s2::Term) = InteractionTerm((s1, s2))
toterm(s1::InteractionTerm, s2::Term) = InteractionTerm((s1.terms..., s2))
toterm(s1::Term, s2::InteractionTerm) = InteractionTerm((s1, s2.terms...))
toterm(x::Tuple, s2::Term) = map(t -> toterm(t, s2), x)
toterm(s1::Term, x::Tuple) = map(t -> toterm(s1, t), x)
function predictor_product(predictors)
    init, rest = Iterators.peel(predictors)
    reduce((x, y) -> x + y + toterm(x, y), term.(rest), init = term(init))
end
function errorterm(ef, nested)
    terms = term(1) + term(ef)
    if length(nested) > 0
        nestedterms = predictor_product(nested)
        terms += toterm(term(ef), nestedterms)
    end
    terms
end

name(t::AbstractTerm) = "$(t.sym)"
name(t::InteractionTerm) = join(name.(t.terms), " & ")
name(t::InterceptTerm) = "Intercept"
pivoted_asgn(assign, qrp) = assign[qrp.p[1:rank(qrp.R)]]
function mqr(f::FormulaTerm, data; contrasts = Dict{Symbol, Any}())
    mf = ModelFrame(f, data; contrasts)
    mm = ModelMatrix(mf)
    qrp = qr(mm.m, Val(true))
    (qrp = qrp, mf = mf, mm = mm)
end
function aov(f::FormulaTerm, data; return_locals = false)
    qrp, mf, mm = mqr(f, data)
    aov(qrp, pivoted_asgn(mm.assign, qrp), mf.f.rhs.terms,
        getproperty(data, f.lhs.sym); return_locals)
end
aov(l, y) = aov(l..., y)
function aov(qrp, asgn, terms, y; return_locals = false)
    effects = qrp.Q' * y
    r = rank(qrp.R)
    SS = Float64[]
    names = String[]
    DF = Int[]
    for i in union(asgn)
        n = name(terms[i])
        n == "Intercept" && continue
        idxs = findall(asgn .== i)
        push!(SS, sum(abs2, @view(effects[idxs])))
        push!(names, n)
        push!(DF, length(idxs))
    end
    push!(SS, sum(abs2, @view(effects[r+1:end])))
    push!(names, "Residuals")
    push!(DF, length(effects) - r)
    MSS = SS ./ DF
    F = MSS ./ MSS[end]
    F[end] = NaN
    DFres = DF[end]
    result = DataFrame(names = names, DF = DF, SS = SS, MSS = MSS, F = F,
                       p = @.(ccdf(FDist(DF, DFres), F)))
    if return_locals
        result, (qrp = qrp, asgn = asgn, terms = terms)
    else
        result
    end
end
function aoverror(f::FormulaTerm, e, nested::T, data; return_locals = false) where T
    nested = T <: Symbol ? [nested] : nested
    ef = errorterm(e, nested)
    efit = mqr(f.lhs ~ ef, data,
        contrasts = Dict(e => HelmertCoding(),
                         [t => HelmertCoding() for t in nested]...))
    efit.mm.assign = efit.mm.assign[efit.qrp.p[1:rank(efit.qrp.R)]]
    mf = ModelFrame(f, data)
    mm = ModelMatrix(mf)
    ys = efit.qrp.Q' * getproperty(data, f.lhs.sym)
    append!(efit.mm.assign,
            fill(maximum(efit.mm.assign) + 1, length(ys) - length(efit.mm.assign)))
    Xs = efit.qrp.Q' * mm.m
    rows = [findall(efit.mm.assign .== i)
            for i in Iterators.drop(sort!(union(efit.mm.assign)), 1)]
    result = [inner(Xs, ys, row, mm.assign, mf.f.rhs.terms; return_locals)
              for row in rows]
    if return_locals
        first.(result), (Q = efit.qrp.Q,
                         locals_t = [(rest..., row)
                                     for (row, rest) in zip(rows, last.(result))])
    else
        result
    end
end
function aoverror(l, y)
    ys = l.Q' * y
    [aov(qrp, asgn, terms, ys[rows]) for (qrp, asgn, terms, rows) in l.locals_t]
end
function inner(X, y, rows, asgn, terms; return_locals = false)
    T = X[rows, :]
    cols = findall(reshape(sum(abs2, T, dims = 1), :) .> 1e-5)
    qrp = qr(T[:, cols], Val(true))
    aov(qrp, pivoted_asgn(asgn[cols], qrp), terms, y[rows]; return_locals)
end
