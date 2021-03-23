# This script loads the raw data from all experiments, runs the protocols and
# stores some values that will be useful to run the tests and the extraction of
# the results from a simulated run in fields of type Base.RefValue.
# The results are saved and are loaded by FoodCachingExperiments at init.
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using TOML, CSV, FoodCachingExperiments, DataFramesMeta, Distributions, BSON, CodecZstd
import FoodCachingExperiments: EXPERIMENTS, Experiment, TestSummary, Food,
       default_keycols, bsave
for foodtype in instances(Food)
    eval(:(import FoodCachingExperiments: $(Symbol(foodtype))))
end

include(joinpath(@__DIR__, "..", "examples", "dummy_model.jl"))

const DATADIR = joinpath(@__DIR__, "..", "data", "raw")

function load_experiment(name; datadir = DATADIR, run = true)
    meta = TOML.parsefile(joinpath(datadir, "$name.toml"))
    data = CSV.File(joinpath(datadir, "$name.csv"), pool = false) |> DataFrame
    tests = CSV.File(joinpath(datadir, "$(name)_tests.csv")) |> DataFrame |>
            processtests
    ex = Experiment{name}(Base.RefValue{Any}(),
                          Base.RefValue{Any}(),
                          haskey(meta, "major_finding") ?
                          meta["major_finding"] : (@warn("$name misses major_finding"); ""),
                          haskey(meta, "comments") ?
                          meta["comments"] : (@warn("$name misses comments"); ""),
                          sort!(data, default_keycols(data)),
                          tests, meta["nbirds"],
                          eval.(Meta.parse.(meta["foodtypes"])))
    if run
        data = run!(ex, fill(DummyModel(), ex.nbirds))
        res = results(ex, data)
        ex = dropref(ex)
        length(res) == length(target(ex)) || @warn "$name: result and target have different lengths"
        ex
    else
        ex
    end
end

function processtests(tests)
    result = Dict{String,TestSummary}()
    for g in groupby(tests, :id)
        result[g.id[1]] = TestSummary(
                                @with(g, pvalue.(:statistic, :df, :value)),
                                string.(g.key),
                                string.(g.df),
                                string.(g.label),
                                string.(g.statistic),
                                string.(g.value),
                                Base.RefValue{Any}(),
                                Base.RefValue{Any}()
                               )
    end
    result
end
pvalue(statistic, df::String, value) = pvalue(statistic, eval(Meta.parse(df)), value)
function pvalue(statistic, df, value)
    if typeof(value) == String
        if value[1] == '<'
            value = eval(Meta.parse(value[2:end])) - .01
        elseif value[1] == '>'
            value = eval(Meta.parse(value[2:end])) + .01
        else
            value = eval(Meta.parse(value))
        end
    end
    if statistic == "F"
        ccdf(FDist(df[1], df[2]), value)
    elseif statistic == "t"
        ccdf(FDist(1, df[1]), value^2)
    elseif statistic == "U" || statistic == "FisherExactTest" || statistic == "Binomial"
        value
    elseif statistic == "Chisq"
        ccdf(Chisq(df), value)
    else
        error("Don't know how to treat statistic $statistic.")
    end
end

function dropref(x::TestSummary)
    TestSummary(x.pvalues, x.keys, x.df, x.labels, x.statistic, x.value,
                isassigned(x.locals) ? x.locals[] : nothing,
                isassigned(x.accessor) ? x.accessor[] : nothing)
end
function dropref(x::Dict{String, TestSummary})
    Dict(id => dropref(test) for (id, test) in x)
end
function dropref(e::Experiment{name}) where name
    Experiment{name}(e.data_accessor[],
                     e.target[],
                     e.major_finding,
                     e.comments,
                     e.data,
                     dropref(e.tests),
                     e.nbirds,
                     e.foodtypes)
end

println("Processing experiments. This will take some time!")
for filename in readdir(DATADIR)
    name, ending = splitext(filename)
    name = Symbol(name)
    run = name ∉ FoodCachingExperiments.CLAYTON0103_EXPERIMENTS
    if ending == ".toml"
        println("$name ...")
        EXPERIMENTS[name] = load_experiment(name; run)
    end
end

# This is a dummy experiment to aggregate all the sequentially performed experiments
println("Clayton0103 ...")
EXPERIMENTS[:Clayton0103] = Experiment{:Clayton0103}(Base.RefValue{Any}(),
                                                     Base.RefValue{Any}(),
                                                     "",
                                                     "Running 01/03 experiments in one go.",
                                                     DataFrame(),
                                                     Dict{String, TestSummary}(),
                                                     16,
                                                     [Peanut, Mealworm, Cricket])
data = run!(EXPERIMENTS[:Clayton0103], fill(DummyModel(), 16))
res = results(EXPERIMENTS[:Clayton0103], data)
EXPERIMENTS[:Clayton0103] = dropref(EXPERIMENTS[:Clayton0103])
length(res) == length(target(EXPERIMENTS[:Clayton0103])) || @warn "Clayton0103: result and target have different lengths"
for e in FoodCachingExperiments.CLAYTON0103_EXPERIMENTS
    EXPERIMENTS[e] = dropref(EXPERIMENTS[e])
end

bsave(joinpath(DATADIR, "..", "processed", "experiments"), EXPERIMENTS)
