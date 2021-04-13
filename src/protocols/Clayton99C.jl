# Clayton, N. S. and Dickinson, A. (1999), Motivational control of caching
# behaviour in the scrub jay (Aphelocoma coerulescens), Animal Behaviour,
# 2:435-444

function _summarize(::Experiment{:Clayton99C_exp1}, results)
    combine(groupby(results, [:group, :foodtype, :action, :stage]),
       df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                       n = length(df.counts)))
end
function statistical_tests(exp::Experiment{:Clayton99C_exp1}, data)
    tests = Test[]
    push!(tests, Test("prefeding effect on stones cache",
                      ttest(@where(data, :action .== "cache",
                                         :foodtype .== "stone",
                                         :group .== "S",
                                         :stage .== 1).counts,
                            @where(data, :action .== "cache",
                                         :foodtype .== "stone",
                                         (:group .== "pP") .| (:group .== "pP+S")).counts,
                            paired = false), # why is the degree 1,20 in the paper?
                      exp.tests))
    push!(tests, Test("prefeding effect on peanuts cache",
                      ttest(@where(data, :action .== "cache",
                                         :foodtype .== "peanut",
                                         :group .== "P",
                                         :stage .== 1).counts,
                            @where(data, :action .== "cache",
                                         :foodtype .== "peanut",
                                         (:group .== "pP") .| (:group .== "pP+S")).counts,
                            paired = false), # why is the degree 1,20 in the paper?
                      exp.tests))
    push!(tests, Test("precaching effect on stones cache",
                      ttest(@where(data, :action .== "cache",
                                         :foodtype .== "stone",
                                         :group .== "S", :trial .== "S",
                                         :stage .== 1).counts,
                            @where(data, :action .== "cache",
                                         :foodtype .== "stone",
                                         :group .== "S",
                                         :stage .== 2).counts,
                            paired = true),
                      exp.tests))
    push!(tests, Test("precaching effect on peanuts cache",
                      ttest(@where(data, :action .== "cache",
                                         :foodtype .== "peanut",
                                         (:group .== "S") .| (:group .== "pP+S"),
                                         :stage .== 2).counts,
                            @where(data, :action .== "cache",
                                         :foodtype .== "peanut",
                                         :group .== "P",
                                         :stage .== 1).counts,
                            paired = false),
                      exp.tests))
    id = "interactions"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :stage .== 2, :action .== "cache"),
                                     exp.tests[id].locals,
                                     betweenfactors = [:group, :order],
                                     withinfactors = :foodtype,
                                     id = :id, data = :counts),
                      exp.tests))
    id = "stones cache in stage 2"
    push!(tests, Test(id,
                      anova(@where(data, :stage .== 2, :action .== "cache",
                                         :foodtype .== "stone"),
                            @formula(counts ~ group), exp.tests[id].locals),
                      exp.tests))
    id = "peanuts cache in stage 2"
    push!(tests, Test(id,
                      anova(@where(data, :stage .== 2, :action .== "cache",
                                         :foodtype .== "peanut"),
                            @formula(counts ~ group), exp.tests[id].locals),
                      exp.tests))
    TestCollection(tests)
end
function run!(::Experiment{:Clayton99C_exp1}, models)
    results = DataFrame(group = String[], trial = String[], order = String[],
                        foodtype = String[], action = String[],
                        stage = Int[], id = Int[], counts = Int[])
    id = 0
    for group in ["pP", "S", "P", "pP+S"]
        for i in 1:6
            id += 1
            m = models[id]
            trials = ["S", "P"]
            if i > 3
                reverse!(trials)
                order = "PS"
            else
                order = "SP"
            end
            for trial in trials
                remove!(m, Any)
                wait!(m, 4u"hr")
                tray = Tray()
                add!(m, tray) # stage 1
                if group == "pP"
                    add!(m, PowderedPeanut, 50)
                elseif group == "S"
                    add!(m, Stone, 50)
                elseif group == "P"
                    add!(m, Peanut, 50)
                else
                    add!(m, PowderedPeanut, 50)
                    add!(m, Stone, 50)
                end
                wait!(m, 1u"hr")
                if group == "P"
                    cache = countcache(tray, Peanut)
                    push!(results, [group, trial, order, "peanut", "cache", 1, id, cache])
                    push!(results, [group, trial, order, "peanut", "eat", 1, id,
                                    50 - countfooditems(m, Peanut)])
                elseif group == "S"
                    push!(results, [group, trial, order, "stone", "cache", 1, id,
                                    countcache(tray, Stone)])
                end
                remove!(m, Any)
                pilfer!(tray)
                add!(m, tray) # stage 2
                foodtype = trial == "S" ? Stone : Peanut
                add!(m, foodtype, 50)
                wait!(m, 1u"hr")
                cache = countcache(tray, foodtype)
                push!(results, [group, trial, order, lowercase(string(foodtype)), "cache", 2,
                                id, cache])
                if foodtype == Peanut
                    push!(results, [group, trial, order, "peanut", "eat", 2, id,
                                    50 - countfooditems(m, Peanut)])
                end
                remove!(m, Any)
                add!(m, MaintenanceDiet)
                wait!(m, 18u"hr" + 1u"d")
            end
        end
    end
    results
end

function _summarize(::Experiment{:Clayton99C_exp2}, results)
    combine(groupby(results, [:group, :action, :stage]),
       df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                       n = length(df.counts)))
end
function statistical_tests(exp::Experiment{:Clayton99C_exp2}, data)
    tests = Test[]
    for action in ("cache", "eat")
        push!(tests, Test(action,
                          splitplotanova(@where(data, :action .== action),
                                         exp.tests[action].locals,
                                         betweenfactors = [:group, :foodtype2, :traychanged],
                                         withinfactors = :stage,
                                         id = :id, data = :counts),
                          exp.tests))
        for stage in 1:2
            id = "$action stage $stage"
            push!(tests, Test(id,
                              anova(@where(data, :action .== action,
                                           :stage .== stage),
                                    @formula(counts ~ group * foodtype2 * traychanged), exp.tests[id].locals),
                              exp.tests))
        end
    end
    for group in ("same", "different")
        for action in ("cache", "eat")
#   with stage as within factor I don't get the same Df as in the paper
            id = "$group group stage 1 vs stage 2 $action"
            push!(tests, Test(id,
                              splitplotanova(@where(data, :action .== action,
                                             :group .== group),
                                             exp.tests[id].locals,
                                             betweenfactors = [:foodtype2, :traychanged],
                                             withinfactors = :stage,
                                             id = :id, data = :counts),
#                               anova(@where(data, :action .== action,
#                                            :group .== group),
#                               @formula(counts ~ stage*foodtype2*traychanged)),
                              exp.tests))
        end
    end
    TestCollection(tests)
end
function run!(::Experiment{:Clayton99C_exp2}, models)
    results = DataFrame(group = String[], action = String[], stage = Int[],
                        foodtype2 = String[], traychanged = Bool[],
                        id = Int[], counts = Int[])
    id = 0
    for group in ["same", "different"]
        for i in 1:12
            id += 1
            m = models[id]
            foodtypes = [Peanut, Kibble]
            i > 6 && reverse!(foodtypes)
            remove!(m, Any)
            wait!(m, 4u"hr")
            tray = Tray(1)
            foodtype2 = "same" == group ? string(foodtypes[1]) : string(foodtypes[2])
            traychanged = i % 2 == 0
            for stage in 1:2
                foodtypeindex = 1
                if stage == 2
                    traychanged && (tray = Tray(2)) # Did they put it at the same place as the first tray or not?
                    foodtypeindex = "same" == group ? 1 : 2
                end
                add!(m, tray)
                add!(m, foodtypes[foodtypeindex], 50)
                wait!(m, 1u"hr")
                cache = countcache(tray)
                push!(results, [group, "cache", stage, foodtype2, traychanged, id, cache])
                push!(results, [group, "eat", stage, foodtype2, traychanged, id,
                                50 - countfooditems(m, foodtypes[foodtypeindex])])
                remove!(m, Any)
                pilfer!(tray)
            end
        end
    end
    results
end

function _summarize(::Experiment{:Clayton99C_exp3}, results)
    combine(groupby(results, [:group, :action]),
       df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                       n = length(df.counts)))
end
function statistical_tests(exp::Experiment{:Clayton99C_exp3}, data)
    tests = Test[]
    for action in ("cache", "eat")
        push!(tests, Test(action,
                          anova(@where(data, :exp .== "a", :action .== action),
                                @formula(counts ~ group * foodtype),
                                exp.tests[action].locals),
                          exp.tests))
    end
    push!(tests, Test("within-subject prefeeding",
                      is_significantly_bigger(@where(data, :exp .== "b"),
                                              conditionkey = :group,
                                              condbigger = "nothing",
                                              condsmaller = "prefed",
                                              valuekey = :counts,
                                              paired = true),
                      exp.tests))
    TestCollection(tests)
end
function run!(::Experiment{:Clayton99C_exp3}, models; samebirds = true)
    results = DataFrame(exp = String[],
                        group = String[], action = String[], foodtype = String[],
                        id = Int[], counts = Int[])
    id = 0
    for group in ["same", "different", "none"]
        for i in 1:8
            id += 1
            m = models[id]
            foodtypes = [Peanut, Kibble]
            i > 6 && reverse!(foodtypes)
            remove!(m, Any)
            wait!(m, 4u"hr")
            tray = Tray(1)
            add!(m, tray)
            group != "none" && add!(m, foodtypes[1] == Peanut ? PowderedPeanut :
                                    PowderedKibble, 50)
            wait!(m, 1u"hr")
            remove!(m, Any)
            add!(m, tray)
            foodtypeindex = group == "same" ? 1 : 2
            add!(m, foodtypes[foodtypeindex], 50)
            wait!(m, 1u"hr")
            cache = countcache(tray)
            push!(results, ["a", group, "cache",
                            string(foodtypes[foodtypeindex]), id, cache])
            push!(results, ["a", group, "eat", string(foodtypes[foodtypeindex]), id,
                            50 - countfooditems(m, foodtypes[foodtypeindex])])
            remove!(m, Any)
        end
    end
    samebirds && (id = 0)
    for i in 1:23
        id += 1
        m = models[id]
        add!(m, MaintenanceDiet)
        wait!(m, 100u"d")
        for day in 1:2
            remove!(m, Any)
            wait!(m, 4u"hr")
            prefed = (day == 1 && i <= 11) || (day == 2 && i > 11)
            prefed && add!(m, PowderedPeanut, 50)
            wait!(m, 1u"hr") # not mentioned in paper
            remove!(m, Any)
            tray = Tray()
            add!(m, tray)
            add!(m, Peanut, 50) # amount not mentioned in paper
            wait!(m, 1u"hr") # not mentioned in paper
            cache = countcache(tray)
            push!(results, ["b", prefed ? "prefed" : "nothing",
                            "cache", i <= 11 ? "first" : "second", id, cache])
            remove!(m, Any)
            add!(m, MaintenanceDiet)
            wait!(m, 18u"hr")
        end
    end
    results
end
