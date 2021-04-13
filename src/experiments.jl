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
    nbirds::Int
    foodtypes::Vector{Food}
end
function Experiment{name}(a::A, t::T, args...) where {name, A, T}
    Experiment{name, A, T}(a, t, args...)
end

name(::Experiment{N}) where N = N
nbirds(exp::Experiment) = exp.nbirds
foodtypes(exp::Experiment) = exp.foodtypes
target(exp::Experiment) = exp.target

default_keycols(x) = setdiff(names(x), ["μ", "sem", "firstinspection", "n"])
extract(data, da) = convert(Vector{Float64}, vcat([data[idx, c] for (c, idx) in da]...))
function results(da, data, tests, ::Any)
    res = extract(data, da)
    append!(res, significancecode.(tests.pvalues))
end
function results(da::Base.RefValue, data, tests, e::Experiment{K}) where K
    ks = default_keycols(data)
    targetdf = K ∈ (:Cheke11_specsat, :Cheke11_planning) ? summarize(e, e.data) : e.data
    if dropmissing(data[!,ks]) != dropmissing(targetdf[!,ks])
        @warn K data[!,ks] targetdf[!,ks]
    end
    da[] = [(c, findall(x -> x !== missing, targetdf[!, c]))
            for c in intersect(["μ", "sem", "firstinspection"], names(targetdf))]
    target = extract(targetdf, da[])
    for test in tests.tests
        targetdf = e.tests[test.id].df
        append!(target, significancecode.(e.tests[test.id].pvalues))
        a = e.tests[test.id].accessor
        isassigned(a) || continue
        computeddf = df(a[], test.content, nothing)
        targetdf == computeddf || @warn K test.id targetdf computeddf
    end
    e.target[] = target
    results(da[], data, tests, e)
end
function results(e, data)
    tests = statistical_tests(e, data)
    ag = summarize(e, data)
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
function asdataframe(e::Experiment{K}, x, k = Ref(0)) where K
    data = K ∈ (:Cheke11_specsat, :Cheke11_planning) ? summarize(e, e.data) : deepcopy(e.data)
    k0 = k[]
    for (col, idx) in e.data_accessor
        data[idx, col] .= x[k[]+1:k[]+length(idx)]
        k[] += length(idx)
    end
    tests = x[k[]+1:k0 + length(e.target)]
    k[] += length(tests)
    data, tests
end
function asdataframe(::Experiment{:Clayton0103}, x, k = Ref(0))
    [asdataframe(e, x, k) for e in CLAYTON0103_EXPERIMENTS]
end
