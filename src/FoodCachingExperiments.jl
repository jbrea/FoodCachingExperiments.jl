module FoodCachingExperiments

using BSON, StatsModels, DataFrames, Random, LinearAlgebra, Distributions,
      HypothesisTests, DataFramesMeta, Unitful, StatsBase, CodecZstd, PythonCall

export run!, summarize, statistical_tests, results, nbirds, target

include("language.jl")
include("experiments.jl")
include("anova.jl")
include("statisticaltests.jl")
include("fileio.jl")
include("pythoncall.jl")

const EXPERIMENTS = Dict{Symbol, Experiment}()

for filename in readdir(joinpath(@__DIR__, "protocols"))
    if splitext(filename)[end] == ".jl"
        include(joinpath(@__DIR__, "protocols", filename))
    end
end

run!(name::Symbol, models) = run!(EXPERIMENTS[name], models)
summarize(name::AbstractString, data) = summarize(Symbol(name), data)
summarize(name::Symbol, data) = summarize(EXPERIMENTS[name], data)
function summarize(e::Experiment, data)
    ag = _summarize(e, data)
    sort!(ag, default_keycols(ag))
end
statistical_tests(name::AbstractString, data) = statistical_tests(Symbol(name), data)
statistical_tests(name::Symbol, data) = statistical_tests(EXPERIMENTS[name], data)
results(name::AbstractString, data) = results(Symbol(name), data)
results(name::Symbol, data) = results(EXPERIMENTS[name], data)
nbirds(name::AbstractString) = nbirds(Symbol(name))
nbirds(name::Symbol) = nbirds(EXPERIMENTS[name])
target(name::AbstractString) = target(Symbol(name))
target(name::Symbol) = target(EXPERIMENTS[name])
foodtypes(name::AbstractString) = foodtypes(Symbol(name))
foodtypes(name::Symbol) = foodtypes(EXPERIMENTS[name])
asdataframe(name::Symbol, x, k = Ref(0)) = asdataframe(EXPERIMENTS[name], x, k)

function __init__()
    filename = joinpath(@__DIR__, "..", "data", "processed", "experiments.bson.zstd")
    if !isfile(filename)
        @warn "$filename not found. Please run `julia script/process_experiments.jl`."
    else
        for (name, experiment) in bload(filename)
            EXPERIMENTS[name] = experiment
        end
    end
end

end
