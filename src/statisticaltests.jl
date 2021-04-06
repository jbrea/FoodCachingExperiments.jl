function tocategoricaldf(df::AbstractDataFrame; categoricalexcept)
    df = typeof(df) <: DataFrame ? copy(df) : DataFrame(df)
    categorical = setdiff(names(df), [categoricalexcept])
    categorical!(df, categorical)
end

copysubarray(x::SubArray) = copy(x)
copysubarray(x) = x
function splitplotanova(df, locals; data, kwargs...)
    aoverror(locals, copysubarray(getproperty(df, data)))
end
function splitplotanova(df, locals::Base.RefValue;
                        betweenfactors, withinfactors, id, data,
                        categoricalexcept = string.(data))
    formula = term(data) ~ predictor_product([betweenfactors; withinfactors])
    df = tocategoricaldf(df; categoricalexcept)
    res, locals[] = aoverror(formula, id, withinfactors, df; return_locals = true)
    res
end
anova(df, formula, locals) = aov(locals, copysubarray(getproperty(df, formula.lhs.sym)))
function anova(df, formula, locals::Base.RefValue)
    df = tocategoricaldf(df; categoricalexcept = string(formula.lhs.sym))
    res, locals[] = aov(formula, df; return_locals = true)
    res
end

abstract type AbstractSimpleTest end
struct UTest <: AbstractSimpleTest
    u::Float64
    p::Float64
    n::Int
end
function utest(x, y)
    res = MannWhitneyUTest(x, y)
    UTest(res.U, HypothesisTests.pvalue(res), length(x) + length(y))
end
function Base.show(io::IO, t::UTest)
    println(io, "Mann-Whitney U test")
    println(io, "u = $(t.u) p = $(t.p) n = $(t.n)")
end
struct TTest <: AbstractSimpleTest
    t::Float64
    p::Float64
    df::Int
end
struct NoTest <: AbstractSimpleTest
    comment::String
    p::Float64
end
# this is a hack for Correia07_exp2 where the content can be a string
NoTest(comment) = NoTest(comment, 1.)
function ttest(x::AbstractVector, y::AbstractVector, μ0::Real=0;
               paired = false, twosided = true)
    res = paired ? OneSampleTTest(x, y, μ0) : EqualVarianceTTest(x, y, μ0)
    TTest(res.t, HypothesisTests.pvalue(res, tail = twosided ? :both : :right), res.df)
end
function Base.show(io::IO, t::TTest)
    println(io, "Student's t-test")
    println(io, "t = $(t.t) p = $(t.p) DF = $(t.df)")
end
function is_significantly_bigger(df;
                                 conditionkey::Symbol,
                                 condbigger, condsmaller,
                                 valuekey::Symbol,
                                 paired = true)
    x = DataFramesMeta.where(df, d -> getproperty(d, conditionkey) .== condbigger)
    y = DataFramesMeta.where(df, d -> getproperty(d, conditionkey) .== condsmaller)
    ttest(getproperty(x, valuekey), getproperty(y, valuekey), paired = paired, twosided = false)
end
function isnot_significantly_different(df; conditionkey::Symbol,
                                       condition1, condition2,
                                       valuekey::Symbol,
                                       paired = true)
    x = DataFramesMeta.where(df, d -> getproperty(d, conditionkey) .== condition2)
    y = DataFramesMeta.where(df, d -> getproperty(d, conditionkey) .== condition1)
    ttest(getproperty(x, valuekey), getproperty(y, valuekey), paired = paired, twosided = true)
end
struct ChisqTest <: AbstractSimpleTest
    χ²::Float64
    p::Float64
    df::Int
end
function mergeanddropzerorows(x, y)
    tmp = Int[]
    for (xi, yi) in zip(x, y)
        xi == yi == 0 && continue
        push!(tmp, xi); push!(tmp, yi)
    end
    reshape(tmp, 2, :)
end
chisqtest(x::Vector{Int}, y::Vector{Int}) = chisqtest(mergeanddropzerorows(x, y))
function chisqtest(x::Array{Int, 2})
    χ² = HypothesisTests.ChisqTest(x)
    ChisqTest(χ².stat, HypothesisTests.pvalue(χ²), χ².df)
end
function Base.show(io::IO, c::ChisqTest)
    println(io, "χ²-test")
    println(io, "χ²($(c.df)) = $(c.χ²) p = $(c.p)")
end
struct FisherExactTest <: AbstractSimpleTest
    table::NTuple{4, Int}
    p::Float64
end
function Base.show(io::IO, f::FisherExactTest)
    println(io, "Fisher exact test")
    println(io, "$(f.table[1])|$(f.table[2]) vs $(f.table[3])|$(f.table[4])  p = $(f.p)")
end
function fisherexacttest(df; cond1, cond2, data)
    table = combine(groupby(df, [cond1, cond2]), d -> sum(getproperty(d, data)))
    tabletuple = tuple(table.x1...)
    if tabletuple[1] == tabletuple[3] == 0 || tabletuple[2] == tabletuple[4] == 0
        FisherExactTest(tabletuple, 1.) # this is a hack to avoid errors
    else
        p = HypothesisTests.pvalue(HypothesisTests.FisherExactTest(tabletuple...))
        FisherExactTest(tabletuple, p)
    end
end
struct BinomialTest <: AbstractSimpleTest
    x::Int
    n::Int
    p::Float64
end
function Base.show(io::IO, f::BinomialTest)
    println(io, "Binomial test")
    println(io, "x/n = $(f.x)/$(f.n), p = $(f.p)")
end
function binomialtest(v::Vector)
    x = sum(v)
    n = length(v)
    p = HypothesisTests.pvalue(HypothesisTests.BinomialTest(x, n))
    BinomialTest(x, n, p)
end

struct Test{T,Ta}
    id::String
    content::T
    target::Ta
    pvalues::Vector{Float64}
end
function Test(id, content, target)
    Test(id, content, target, pvalues(target.accessor, content, target))
end
function Test(id, content, target::Dict)
    Test(id, content, target[id])
end
function Base.show(io::IO, t::Test)
    printstyled(io, "Test ID:  $(t.id)\n", bold = true)
    pvalues = t.target.pvalues
    for (k, p) in zip(t.target.keys, pvalues)
        color = true ? :green : :red
        printstyled(io, "$(rpad(k, 25)) p = $(round(p, digits = 4))\n", color = color)
    end
    println(io, t.content)
end

pvalues(::Any, c::AbstractSimpleTest, ::Any) = [c.p]
df(::Any, c::AbstractSimpleTest, ::Any) = ""
pvalues(a, c::DataFrame, ::Any) = c.p[a]
df(a, c::DataFrame, ::Any) = map(x -> "$(c.DF[x]),$(c.DF[end])", a)
pvalues(a, c::Vector{DataFrame}, ::Any) = vcat([c[i].p[idx] for (i, idx) in a]...)
df(a, c::Vector{DataFrame}, x::Any) = vcat([df([idx], c[i], x) for (i, idx) in a]...)
function pvalues(a::Base.RefValue, c::DataFrame, t)
    a[] = map(name -> findfirst(x -> x == name, c.names), t.keys)
    pvalues(a[], c, t)
end
function accessor_tuple(k, c)
    for (i, d) in enumerate(c)
       idx = findfirst(x -> x == k, d.names)
       idx === nothing || return (i, idx)
    end
end
function pvalues(a::Base.RefValue, c::Vector{DataFrame}, t)
    a[] = [accessor_tuple(k, c) for k in t.keys]
    pvalues(a[], c, t)
end

struct TestCollection{Tt}
    tests::Tt
    pvalues::Vector{Float64}
end
function Base.show(io::IO, ts::TestCollection)
    for test in ts.tests
        Base.show(io, test)
        println()
    end
end
TestCollection(test::Test) = TestCollection([test])
function TestCollection(tests::Vector{<:Test})
    TestCollection(tests, vcat([t.pvalues for t in tests]...))
end

function significancecode(p; levels = SIGLEVELS)
    i = one(Float64)
    for v in levels
        p < v && return i
        i += 1.
    end
    i
end
const SIGLEVELS = [.001, .01, .05, .1]
function setrsiglevels!()
    empty!(SIGLEVELS)
    append!(SIGLEVELS, [.001, .01, .05, .1])
end
function setbinarysiglevels!()
    empty!(SIGLEVELS)
    push!(SIGLEVELS, .05)
end
