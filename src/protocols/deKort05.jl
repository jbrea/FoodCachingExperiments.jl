# de Kort, S. R., Dickinson, A., and Clayton, N. S. (2005), Retrospective
# cognition by food-caching western scrub-jays, Learning and Motivation
# 36:159-176

function _summarize(::Experiment{:deKort05}, results)
    datainspectpeanut = @where(results, :action .== "inspect", :foodtype .== "peanut")
    datainspectwaxworm = @where(results, :action .== "inspect", :foodtype .== "other")
    data = @transform datainspectwaxworm counts = datainspectwaxworm.counts ./
                                (1e-16 .+ datainspectpeanut.counts .+ datainspectwaxworm.counts)
    combine(groupby(data, [:group, :action, :set, :RI]),
       d -> DataFrame(μ = mean(d.counts), sem = sem(d.counts),
                      firstinspection = mean(d.firstinspection),
                      n = length(d.counts)))
end
function statistical_tests(exp::Experiment{:deKort05}, data)
    tests = Test[]
    id = "inspect"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :action .== "inspect"),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = [:RI, :set, :foodtype],
                                     id = :id, data = :counts),
                      exp.tests))
    d = @where(data, :action .== "inspect", :set .== 8)
    sort!(d, [:id, :foodtype, :RI])
    push!(tests, Test("first inspect trial 8",
                      chisqtest(firstinspect_dist(@where(d, :group .== "degrade")),
                                firstinspect_dist(@where(d, :group .== "ripen"))),
                      exp.tests))
    TestCollection(tests)
end
function run!(::Experiment{:deKort05}, models)
    results = DataFrame(group = Union{String,Missing}[],
                        foodtype = Union{String,Missing}[],
                        id = Int[], set = Int[], trial = Union{String,Missing}[],
                        RI = Union{Int,Missing}[],
                        action = String[], counts = Int[],
                        firstinspection = Union{Missing,Int}[])
    id = 0
    for group in ("degrade", "ripen")
        for i in 1:(group == "degrade" ? 5 : 7)
            id += 1
            m = models[id]
            for set in 1:8
                for RI in (4u"hr", 28u"hr")
                    Clayton01_trial!(m, results, group, id, set, Peanut,
                                     Waxworm, RI,
                                     degrade = isdegrade(group, Waxworm, RI),
                                     pilfer = false)
                end
            end
        end
    end
    results
end
