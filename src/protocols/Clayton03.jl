# Clayton, N. S., Yu, K. S. and Dickinson, A. (2003), Interacting Cache
# Memories: Evidence for Flexible Memory Use by Western Scrub-Jays (Aphelocoma
# californica) Journal of Experimental Psychology: Animal Behavior Processes,
# 1:14-22

function _summarize(exp::Experiment{:Clayton03_exp1}, results)
    res = similar(exp.data, 0)
    for g in groupby(@where(results, :action .== "cache", :set .== 7),
                     [:foodtype, :set])
        push!(res, [missing, g.foodtype[1], "cache", missing, missing, g.set[1],
                    mean(g.counts), sem(g.counts), missing, length(g.counts)])
    end
    res = [res; combine(groupby(@where(results, :action .== "inspect", :foodtype .== "other", :set .== 7),
                                [:group, :foodtype, :action, :RI, :trial, :set]),
             df -> DataFrame(μ = missing, sem = missing,
                             firstinspection = mean(df.firstinspection),
                             n = length(df.counts)))]
    res = [res; combine(groupby(cricketproportions(results), [:group, :RI]),
                    d -> DataFrame(foodtype = "cricketproportion", action = "inspect",
                                   set = 7, μ = mean(d.counts), sem = sem(d.counts),
                                   n = length(d.counts), trial = "pc",
                                   firstinspection = missing))]
    res
end
function statistical_tests(exp::Experiment{:Clayton03_exp1}, data)
    tests = Test[]
    datasetinspectClayton03_exp1 = @where(data, (|).(:set .== 4, :set .== 7),
                                         :action .== "inspect", :trial .== "pc",
                                         :RI .> 4)
    for g in groupby(datasetinspectClayton03_exp1, :RI)
        push!(tests, Test("first inspectes RI $(g.RI[1]) Clayton03 exp1",
                          fisherexacttest(g, cond1 = :group, cond2 = :foodtype,
                                          data = :firstinspection),
                          exp.tests))
    end
    cricketprop = cricketproportions(data)
    for g in groupby(cricketprop, :RI)
        id = "inspect RI $(g.RI[1]) Clayton03 exp1"
        push!(tests, Test(id,
                          anova(g, @formula(counts ~ group), exp.tests[id].locals),
                          exp.tests))
    end
#   How did they analyse this in the paper: RI 76 was measured twice which
#   yields unbalanced within factors.
    id = "cache Clayton03 exp1"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :action .== "cache", :set .== 7),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = [:foodtype, :RI],
                                     id = :id, data = :counts),
                      exp.tests))
    id = "inspect Clayton03 exp1"
    push!(tests, Test(id,
                      splitplotanova(cricketprop,
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = :RI, id = :id,
                                     data = :counts),
                      exp.tests))
#   TODO: "inspect degrade Clayton03 exp1" "inspect replenish Clayton03 exp1"
    TestCollection(tests)
end
function run!(::Experiment{:Clayton03_exp1}, models)
    results = DataFrame(group = Union{String,Missing}[],
                        foodtype = Union{String,Missing}[],
                        id = Int[], set = Int[], trial = Union{String,Missing}[],
                        RI = Union{Int,Missing}[],
                        action = String[], counts = Int[],
                        firstinspection = Union{Missing,Int}[])
    id = 0
    for group in ["degrade", "replenish"]
        for i in 1:8
            id += 1
            m = models[id]
            # training before Clayton 2003, experiment 1, January 2000
            wait!(m, 30u"d")
            for RI in (52u"hr", 76u"hr")
                Clayton01_trial!(m, results, group, id, 7, Peanut, Cricket, RI,
                                 degrade = false, pilfer = true, bothtrayspresent = true)
                #interleaved retraining
                Clayton01_trial!(m, results, group, id, 0, Peanut, Cricket, 4u"hr",
                                 degrade = false, pilfer = false)
            end
            wait!(m, 30u"d")
            #interleaved retraining
            Clayton01_trial!(m, results, group, id, 0, Peanut, Cricket, 100u"hr",
                             degrade = isdegrade(group, Cricket, 100u"hr"), pilfer = false)
            for RI in (76u"hr", 124u"hr")
                Clayton01_trial!(m, results, group, id, 7, Peanut, Cricket, RI,
                                 degrade = false, pilfer = true, bothtrayspresent = true)
                #interleaved retraining
                Clayton01_trial!(m, results, group, id, 0, Peanut, Cricket, 4u"hr",
                                 degrade = false, pilfer = false)
            end
        end
    end
    results
end

function _summarize(::Experiment{:Clayton03_exp2}, results)
    res = combine(groupby(@where(results, :action .== "inspect"),
                          [:group, :foodtype, :action, :condition, :RI]),
             d -> DataFrame(action = "inspect", μ = mean(d.counts),
                            sem = sem(d.counts),
                            firstinspection = mean(d.firstinspection),
                            n = length(d.counts)))
    res = [res; combine(groupby(@where(results, :action .== "cache"),
                                [:group, :foodtype, :action]),
                   d -> DataFrame(action = "cache", μ = mean(d.counts),
                                  sem = sem(d.counts),
                                  firstinspection = missing,
                                  condition = missing, RI = missing,
                                  n = length(d.counts)))]
end
function statistical_tests(exp::Experiment{:Clayton03_exp2}, data)
    tests = Test[]
    for g in groupby(@where(data, :action .== "inspect"), :group)
        group = g.group[1]
        id = "inspect $group"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :condition,
                                         withinfactors = [:foodtype, :RI],
                                         id = :id, data = :counts),
                         exp.tests))
        for subg in groupby(g, :RI)
            RI = subg.RI[1]
            id = "inspect $group RI $RI"
            push!(tests, Test(id,
                              splitplotanova(subg,
                                             exp.tests[id].locals,
                                             betweenfactors = :condition,
                                             withinfactors = :foodtype,
                                             id = :id, data = :counts),
                              exp.tests))
            if group == "degrade" && RI == 76
                for subsubg in groupby(subg, :condition)
                    id = "inspect $group RI $RI $(subsubg.condition[1])"
                    push!(tests, Test(id,
                                      anova(subsubg, @formula(counts ~ foodtype + id), exp.tests[id].locals),
                                      exp.tests))
                end
                for subsubg in groupby(subg, :foodtype)
                    id = "inspect $group RI $RI $(subsubg.foodtype[1])"
                    push!(tests, Test(id,
                                      anova(subsubg, @formula(counts ~ condition), exp.tests[id].locals),
                                      exp.tests))
                end
            end
        end
        if group == "replenish"
            for subg in groupby(g, :condition)
                id = "inspect $group $(subg.condition[1])"
                push!(tests, Test(id,
                                  splitplotanova(subg,
                                                 exp.tests[id].locals,
                                                 betweenfactors = [],
                                                 withinfactors = [:foodtype, :RI],
                                                 id = :id, data = :counts),
                                  exp.tests))
            end
            for subg in groupby(g, :foodtype)
                id = "inspect $group $(subg.foodtype[1])"
                push!(tests, Test(id,
                                  splitplotanova(subg,
                                                 exp.tests[id].locals,
                                                 betweenfactors = :condition,
                                                 withinfactors = [:RI],
                                                 id = :id, data = :counts),
                                  exp.tests))
            end
        end
        gsorted = sort(g, [:id, :RI, :foodtype])
        gsortedconsistent = @where(gsorted, :condition .== "consistent")
        gsortedreversed = @where(gsorted, :condition .== "reversed")
        push!(tests, Test("first inspectes $group",
                          chisqtest(firstinspect_dist(gsortedconsistent,
                                                      n = group == "degrade" ? 4 : 6),
                                    firstinspect_dist(gsortedreversed,
                                                      n = group == "degrade" ? 4 : 6)),
                          exp.tests))
    end
    for g in groupby(@where(data, :action .== "cache"), :group)
        id = "cache $(g.group[1])"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :condition,
                                         withinfactors = [:foodtype, :RI],
                                         id = :id, data = :counts),
                          exp.tests))
    end
    TestCollection(tests)
end
hack(i) = i
@inline function Clayton03_trial!(results, m, group, id, condition, RI)
    traypairs = [(Tray(hack(1)), Tray(hack(2))) for d in 1:3]
    # caching
    for (i, (tray1, tray2)) in enumerate(traypairs)
        remove!(m, Any)
        wait!(m, 4u"hr")
        cover!(tray2)
        add!(m, tray1); add!(m, tray2)
        add!(m, Peanut, 50)
        wait!(m, 15u"minute")
        remove!(m, Any)
        cover!(tray1); uncover!(tray2)
        add!(m, tray1); add!(m, tray2)
        add!(m, Cricket, 50)
        wait!(m, 15u"minute")
        remove!(m, Any)
        uncover!(tray1)
        if i == 3
            push!(results, [group, "peanut", id, condition, value(RI), "cache",
                            countcache(tray1), missing])
            push!(results, [group, "cricket", id, condition, value(RI), "cache",
                            countcache(tray2), missing])
        end
        add!(m, MaintenanceDiet)
        wait!(m, 25u"minute" + 15u"hr")
    end
    # recovery
    wait!(m, RI - 3u"d" - 4u"hr")
    for (i, (tray1, tray2)) in enumerate(traypairs)
        if i == 3
            pilfer!(tray1); pilfer!(tray2)
        elseif condition == "reversed"
            degrade!(tray2)
        end
        remove!(m, Any)
        wait!(m, 4u"hr")
        add!(m, tray1)
        add!(m, tray2)
        inspectionobserver = InspectionObserver()
        add!(m, inspectionobserver)
        wait!(m, 5u"minute")
        remove!(m, Any)
        if i == 3
            push!(results, [group, "peanut", id, condition, value(RI), "inspect",
                            countinspections(inspectionobserver, tray1),
                            firstinspection(inspectionobserver, tray1)])
            push!(results, [group, "cricket", id, condition, value(RI), "inspect",
                            countinspections(inspectionobserver, tray2),
                            firstinspection(inspectionobserver, tray2)])
        end
        add!(m, MaintenanceDiet)
        wait!(m, 55u"minute" + 15u"hr")
    end
end
function run!(::Experiment{:Clayton03_exp2}, models)
    results = DataFrame(group = Union{String,Missing}[],
                        foodtype = Union{String,Missing}[],
                        id = Int[], condition = Union{String,Missing}[],
                        RI = Union{Int,Missing}[],
                        action = String[], counts = Int[],
                        firstinspection = Union{Missing,Int}[])
    id = 0
    for group in ["degrade", "replenish"]
        for i in 1:8
            id += 1
            m = models[id]
            # retraining Feb 2000
            for wait in (4u"hr", 100u"hr")
                Clayton01_trial!(m, [], group, id, 0, Peanut, Cricket, wait,
                       degrade = isdegrade(group, Cricket, wait), pilfer = false)
            end
            condition = i > 4 ? "reversed" : "consistent"
            Clayton03_trial!(results, m, group, id, condition, 76u"hr")
            group == "replenish" && Clayton03_trial!(results, m, group, id, condition, 124u"hr")
            tmpres = [] # since Clayton01_trial! expects another form of results table
            Clayton01_trial!(m, tmpres, group, id, 1, Peanut, Cricket, 28u"hr",
                             degrade = false, pilfer = true, specificothername = true)
            for row in tmpres
                push!(results, [row[1:3]; condition; row[end-3:end]])
            end
        end
    end
    results
end
