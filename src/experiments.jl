struct TestSummary{L, A}
    pvalues::Vector{Float64}
    keys::Vector{String}
    df::Vector{String}
    labels::Vector{String}
    statistic::Vector{String}
    value::Vector{String}
    locals::L
    accessor::A
end
struct Experiment{name, A, T}
    data_accessor::A
    target::T
    major_finding::String
    comments::String
    data::DataFrame
    tests::Dict{String,TestSummary}
    repetitions::Int
    foodtypes::Vector{Food}
end
function Experiment{name}(a::A, t::T, args...) where {name, A, T}
    Experiment{name, A, T}(a, t, args...)
end

name(::Experiment{N}) where N = N
repetitions(exp::Experiment) = exp.repetitions
foodtypes(exp::Experiment) = exp.foodtypes

default_keycols(x) = setdiff(names(x), ["μ", "sem", "firstinspection", "n"])
extract(data, da) = convert(Vector{Float64}, vcat([data[idx, c] for (c, idx) in da]...))
function results(da, data, tests, ::Any)
    res = extract(data, da)
    append!(res, significancecode.(tests.pvalues))
end
function results(da::Base.RefValue, data, tests, e::Experiment{K}) where K
    ks = default_keycols(data)
    targetdf = K ∈ (:Cheke11_specsat, :Cheke11_planning) ?
               sort!(aggregate(e, e.data), ks) : e.data
    if dropmissing(data[!,ks]) != dropmissing(targetdf[!,ks])
        @warn K data[!,ks] targetdf[!,ks]
    end
    da[] = [(c, findall(x -> x !== missing, targetdf[!, c]))
            for c in intersect(["μ", "sem", "firstinspection"], names(targetdf))]
    target = extract(targetdf, da[])
    for test in tests.tests
        targetdf = e.tests[test.id].df
        a = e.tests[test.id].accessor
        isassigned(a) || break
        computeddf = df(a[], test.content, nothing)
        targetdf == computeddf || @warn K test.id targetdf computeddf
        append!(target, significancecode.(e.tests[test.id].pvalues))
    end
    e.target[] = target
    results(da[], data, tests, e)
end
function results(e, data)
    tests = statistical_tests(e, data)
    ag = aggregate(e, data)
    sort!(ag, default_keycols(ag))
    results(e.data_accessor, ag, tests, e)
end
function results(e::Experiment{:Clayton0103}, data)
    res = vcat([results(EXPERIMENTS[key], res)
               for (key, res) in zip(CLAYTON0103_EXPERIMENTS, data)]...)
    if isa(e.target, Base.RefValue)
        e.target[] = vcat([EXPERIMENTS[key].target[] for key in CLAYTON0103_EXPERIMENTS]...)
        e.data_accessor[] = nothing
    end
    res
end
