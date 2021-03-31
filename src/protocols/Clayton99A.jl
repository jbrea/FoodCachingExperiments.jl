# Clayton, N. S. and Dickinson, A. (1999), Memory for the Content of Caches by
# Scrub Jays (Aphelocoma coerulescens), Journal of Experimental Psychology:
# Animal Behavior Processes, 1: 82 - 91

function _summarize(::Experiment{:Clayton99A_exp1}, data)
    combine(groupby(data, [:trial, :tray, :action]),
       df -> DataFrame(μ = mean(df.counts),
                       sem = sem(df.counts),
                       n = length(df.counts)))
end
function statistical_tests(exp::Experiment{:Clayton99A_exp1}, data)
    tests = Test[]
    id = "4h overall cache"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :trial .== 4, :action .== "cache"),
                                     exp.tests[id].locals,
                                     betweenfactors = [:order, :foodtype, :pilfering],
                                     withinfactors = [:tray],
                                     id = :id, data = :counts),
                      exp.tests))
    id = "4h overall inspect"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :trial .== 4, :action .== "inspect"),
                                     exp.tests[id].locals,
                                     betweenfactors = [:order, :foodtype, :pilfering],
                                     withinfactors = [:tray],
                                     id = :id, data = :counts),
                      exp.tests))
    id = "172h overall cache"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :trial .== 172, :action .== "cache"),
                                     exp.tests[id].locals,
                                     betweenfactors = [:order, :foodtype],
                                     withinfactors = [:tray],
                                     id = :id, data = :counts),
                      exp.tests))
    id = "172h overall inspect"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :trial .== 172, :action .== "inspect"),
                                     exp.tests[id].locals,
                                     betweenfactors = [:order, :foodtype],
                                     withinfactors = [:tray],
                                     id = :id, data = :counts),
                      exp.tests))
    TestCollection(tests)
end
function run!(::Experiment{:Clayton99A_exp1}, models)
    results = DataFrame(trial = Int[], tray = String[],
                        action = String[], foodtype = String[],
                        order = String[], pilfering = Bool[],
                        id = Int[], counts = Int[])
    traylabel = (foodtype, id) -> foodtype == Peanut && id > 8 ||
                                  foodtype == Kibble && id <= 8 ? "same" : "different"
    for trial in 1:2
        for id in 1:14 # 2 excluded in trial 1
        m = models[id]
            remove!(m, Any)     # 10:00
            wait!(m, 4u"hr")
            trays = [Tray(i) for i in 1:2]
            foodtypes = [Peanut, Kibble]
            id % 4 < 2 && reverse!(foodtypes)
            ispilfer = (trial == 2 || id % 2 == 0)
            prefed = id > 8 ? PowderedPeanut : PowderedKibble
            for (i, foodtype) in enumerate(foodtypes)
                add!(m, trays[i])
                add!(m, foodtype, 50)
                wait!(m, 15u"minute")
                remove!(m, Any)
                push!(results, [trial == 1 ? 4 : 172,
                                traylabel(foodtype, id), "cache",
                                string(prefed), string(foodtypes[1]),
                                ispilfer,
                                id, countcache(trays[i], foodtype)])
            end
            if trial == 1
                wait!(m, 3.5u"hr")
            else
                add!(m, MaintenanceDiet)
                wait!(m, 167.5u"hr")
                remove!(m, Any)
                wait!(m, 4u"hr")
            end
            add!(m, prefed, 50)
            wait!(m, 30u"minute")
            (trial == 2 || id % 2 == 0) && pilfer!.(trays)
            remove!(m, Any)
            for i in 1:2 add!(m, trays[i]) end
            inspectionobserver = InspectionObserver()
            add!(m, inspectionobserver)
            wait!(m, 15u"minute")
            for (i, foodtype) in enumerate(foodtypes)
                push!(results, [trial == 1 ? 4 : 172,
                                traylabel(foodtype, id), "inspect",
                                string(prefed), string(foodtypes[1]),
                                ispilfer,
                                id, countinspections(inspectionobserver, trays[i])])
            end
            remove!(m, Any)
            add!(m, MaintenanceDiet)
            wait!(m, 15u"minute" + 15u"hr" + 6u"d")
        end
    end
    results
end

function _summarize(::Experiment{:Clayton99A_exp2}, data)
    combine(groupby(data, [:side, :action, :tray]),
       df -> DataFrame(μ = mean(df.counts),
                       sem = sem(df.counts),
                       n = length(df.counts)))
end
function statistical_tests(exp::Experiment{:Clayton99A_exp2}, data)
    tests = Test[]
    id = "inspect"
    push!(tests, Test(id,
                      splitplotanova(data,
                                     exp.tests[id].locals,
                                     betweenfactors = [:foodtype],
                                     withinfactors = [:tray, :side],
                                     id = :id, data = :counts),
                      exp.tests))
    for g in groupby(data, :side)
        id = "inspect $(g.side[1])"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :foodtype,
                                         withinfactors = :tray,
                                         id = :id, data = :counts),
                         exp.tests))
    end
    for g in groupby(data, :tray)
        id = "inspect $(g.tray[1])"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :foodtype,
                                         withinfactors = :side,
                                         id = :id, data = :counts),
                         exp.tests))
    end
    TestCollection(tests)
end
function run!(::Experiment{:Clayton99A_exp2}, models)
    results = DataFrame(tray = String[], action = String[],
                        foodtype = String[],
                        side = String[],
                        id = Int[], counts = Int[])
    for id in 1:18
        m = models[id]
        remove!(m, Any)
        wait!(m, 4u"hr")
        trays = [Tray(i) for i in 1:4] # left and right hand side of a tray are treated as different trays.
        for i in 1:4
            add!(m, trays[i])
            if i <= 2
                add!(m, Peanut, 50)
            else
                add!(m, Kibble, 50)
            end
            wait!(m, 15u"minute", m -> (countcache(trays[i]) >= 3))
            remove!(m, Any)
        end
        # if sum(countcache.(trays)) < 12 continue end # drop bird
        wait!(m, 3u"hr")
        if id <= 9
            first = 2; second = 3
        else
            first = 3; second = 2
        end
        add!(m, trays[first]) # tray B Peanuts
        wait!(m, 15u"minute")
        add!(m, trays[second]) # tray A Kibble
        wait!(m, 15u"minute")
        remove!(m, Any)
        if id % 2 == 0
            add!(m, PowderedPeanut, 50)
        else
            add!(m, PowderedKibble, 50)
        end
        wait!(m, 30u"minute")
        remove!(m, Any)
        add!(m, trays)
        inspectionobserver = InspectionObserver()
        add!(m, inspectionobserver)
        wait!(m, 15u"minute")
        for i in 1:4
            push!(results, [(id % 2 == 0 && i <= 2 || id % 2 == 1 && i > 2 ? "same" : "different"),
                            "inspect",
                            id % 2 == 0 ? "Peanut" : "Kibble", # prefed
                            (i == 1 || i == 4 ? "intact" : "recovered"),
                            id,
                            countinspections(inspectionobserver, trays[i])])
        end
    end
    results
end
