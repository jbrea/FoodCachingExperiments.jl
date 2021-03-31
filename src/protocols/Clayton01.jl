# Clayton, N. S., Yu, K. S. and Dickinson, A. (2001), Scrub jays (Aphelocoma
# coerulescens) form integrated memories of the multiple features of caching
# episodes. Journal of Experimental Psychology: Animal Behavior Processes, 1:17-29
#
# Experiments 1 & 2 are merged because they are very similar and involve the
# same birds. Interleaved training trials have set index 0, test phase of
# experiment 1 set index 5 and test phase of experiment 2 has set index 6.

const CLAYTON0103_EXPERIMENTS = (:Clayton01_exp1, :Clayton01_exp2, :Clayton01_exp3,
                                 :Clayton01_exp4, :Clayton03_exp1, :Clayton03_exp2)
function summarize(::Experiment{:Clayton0103}, results)
    [summarize(EXPERIMENTS[key], res)
     for (key, res) in zip(CLAYTON0103_EXPERIMENTS, results)]
end
function _score(exp::Experiment{:Clayton0103}, result, metric)
    vcat([_score(EXPERIMENTS[key], res, metric)
          for (key, res) in zip(CLAYTON0103_EXPERIMENTS, result)]...)
end
function statistical_tests(exp::Experiment{:Clayton0103}, data)
    [statistical_tests(EXPERIMENTS[key], d)
     for (key, d) in zip(CLAYTON0103_EXPERIMENTS, data)]
end
function run!(::Experiment{:Clayton0103}, models)
    results = [run!(EXPERIMENTS[key], models) for key in CLAYTON0103_EXPERIMENTS]
    results[5] = vcat(results[1], results[5]) # data from Clayton01_exp1 was reused in Clayton03_exp2
    results
end

function cricketproportions(results)
    pcinspect = @where(results, :action .== "inspect", (|).(:set .== 4, :set .== 7),
                      :trial .== "pc", :RI .> 4)
    sort!(pcinspect, [:id, :foodtype, :RI, :set])
    pcinspectcricket = @where(pcinspect, :foodtype .== "other")
    pcinspectcricket.counts = float.(pcinspectcricket.counts)
    pcinspectcricket.counts ./= (pcinspectcricket.counts .+
                                @where(pcinspect, :foodtype .== "peanut").counts .+
                                1e-16) # I prefer 0 if no site is ever inspected over NaN because NaN propagates and may lead to NaN scores.
    pcinspectcricket
end
function _summarize(::Experiment{:Clayton01_exp1}, results)
    res = combine(groupby(@where(results, :action .== "inspect", :set .!= 0,
                                 (|).(:foodtype .!= "other", :set .== 5)),
                          [:group, :foodtype, :action, :RI, :trial, :set]),
             df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                             firstinspection = mean(df.firstinspection),
                             n = length(df.counts)))
    for g in groupby(@where(results, :action .== "cache", :set .== 5), :group)
        push!(res, [g.group[1], missing, "cache", missing, missing, 5,
                    mean(g.counts), sem(g.counts), 0, length(g.counts)])
    end
    res
end
firstinspect_dist(df::DataFrame; n = 4) = firstinspect_dist(df.firstinspection; n = n)
function firstinspect_dist(firstinspections; n = 4)
    patterncounts = zeros(Int, 2^n)
    for i in 1:n:length(firstinspections)
        p = 1
        for j in 0:n - 1
            firstinspections[i + j] == 0 || (p += 2^j)
        end
        patterncounts[p] += 1
    end
    patterncounts
end
function statistical_tests(exp::Experiment{:Clayton01_exp1}, data)
    tests = Test[]
    for g in groupby(@where(data, :action .== "inspect", :set .== 4), :RI)
        push!(tests, Test("first inspect set 4 RI $(g.RI[1])",
                          chisqtest(firstinspect_dist(@where(g, :group .== "degrade")),
                                    firstinspect_dist(@where(g, :group .== "replenish"))),
                          exp.tests))
    end
    datatest = @where(data, :action .== "inspect", :set .== 5)
    for g in groupby(datatest, :RI)
        RI = g.RI[1]
        id = "inspect test RI $RI"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = :foodtype,
                                         id = :id, data = :counts),
                          exp.tests))
        push!(tests, Test("first inspect test RI $RI",
                          chisqtest(firstinspect_dist(@where(g, :group .== "degrade")),
                                    firstinspect_dist(@where(g, :group .== "replenish"))),
                          exp.tests))
        if RI == 100
            for subg in groupby(g, :group)
                id = "inspect test RI 100 $(subg.group[1])"
                push!(tests, Test(id,
                                  anova(subg, @formula(counts ~ foodtype),
                                        exp.tests[id].locals),
                                  exp.tests))
            end
        end
    end
    datatestcache = @where(data, :action .== "cache", :set .== 5)
    for g in groupby(datatest, :RI)
        RI = g.RI[1]
        id = "cache test RI $RI"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = :foodtype,
                                         id = :id, data = :counts),
                          exp.tests))
    end
    TestCollection(tests)
end
value(x::Quantity) = x.val
value(x) = div(x, 60)
@inline function Clayton01_trial!(m, results, group, id, set,
                        foodtype1, foodtype2, wait;
                        degrade, pilfer, bothtrayspresent = false,
                        waitbetween = 0u"hr", specificothername = false)
    foodtype1string = lowercase(string(foodtype1))
    foodtype2string = foodtype1 == Peanut && !specificothername ? "other" : lowercase(string(foodtype2))
    trial = "$(foodtype1string[1])$(lowercase(string(foodtype2)[1]))"
    remove!(m, Any)
    wait!(m, 4u"hr")
    tray1 = Tray(hack(1)) # one half of tray
    tray2 = Tray(hack(2)) # second half of tray
    if bothtrayspresent
        cover!(tray2)
        add!(m, tray2)
    end
    add!(m, tray1)
    add!(m, foodtype1, 50)
    wait!(m, 15u"minute")
    remove!(m, Any)
    push!(results, [group, foodtype1string, id, set, trial, value(wait), "cache", countcache(tray1), missing])
    if waitbetween > 0u"hr"
        add!(m, MaintenanceDiet)
        wait!(m, waitbetween - 4u"hr")
        remove!(m, Any)
        wait!(m, 4u"hr")
    end
    if bothtrayspresent
        uncover!(tray2)
        cover!(tray1)
        add!(m, tray1)
    end
    add!(m, tray2)
    add!(m, foodtype2, 50)
    wait!(m, 15u"minute")
    remove!(m, Any)
    uncover!(tray1)
    push!(results, [group, foodtype2string, id, set, trial, value(wait), "cache",
                    countcache(tray2), missing])
    if wait > 4u"hr"
        add!(m, MaintenanceDiet)
        wait!(m, wait - 4u"hr")
        remove!(m, MaintenanceDiet)
    end
    if degrade
        degrade!(tray2)
    end
    if pilfer
        pilfer!(tray2)
        pilfer!(tray1)
    end
    wait!(m, 4u"hr")
    add!(m, tray1)
    add!(m, tray2)
    inspectionobserver = InspectionObserver()
    add!(m, inspectionobserver)
    wait!(m, 5u"minute")
    remove!(m, Any)
    push!(results, [group, foodtype1string, id, set, trial, value(wait), "inspect",
                    countinspections(inspectionobserver, tray1),
                    firstinspection(inspectionobserver, tray1)])
    push!(results, [group, foodtype2string, id, set, trial, value(wait), "inspect",
                    countinspections(inspectionobserver, tray2),
                    firstinspection(inspectionobserver, tray2)])
    add!(m, MaintenanceDiet)
    wait!(m, 25u"minute" + 15u"hr")
end
function isdegrade(group, foodtype, wait)
    if group === "degrade"
        foodtype == Mealworm && wait > 4u"hr" ||
        foodtype == Cricket && wait > 28u"hr" ||
        foodtype == Waxworm && wait > 4u"hr"
    elseif group == "ripen"
        foodtype == Waxworm && wait <= 4u"hr"
    else
        false
    end
end
function run!(::Experiment{:Clayton01_exp1}, models)
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
            # training (May 1999)
            for set in 1:4
                ris = [4u"hr", 28u"hr", 100u"hr"]
                isodd(set) && reverse!(ris)
                for wait in ris
                    for foodtype in [Mealworm, Cricket]
                        Clayton01_trial!(m, results, group, id, set, Peanut, foodtype, wait,
                               degrade = isdegrade(group, foodtype, wait), pilfer = false)
                    end
                end
            end
            # test
            ris = [28u"hr", 100u"hr", 4u"hr"]
            for wait in ris
                for foodtype in [Mealworm, Cricket]
                    Clayton01_trial!(m, results, group, id, 5, Peanut, foodtype, wait,
                           degrade = false, pilfer = true)
                    Clayton01_trial!(m, results, group, id, 0, Peanut, foodtype, 4u"hr",
                           degrade = false, pilfer = false)
                end
            end
        end
    end
    results
end


function _summarize(::Experiment{:Clayton01_exp2}, results)
    res = combine(groupby(@where(results, :action .== "inspect", :set .!= 0),
                          [:group, :foodtype, :action, :RI, :trial, :set]),
             df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                             firstinspection = mean(df.firstinspection),
                             n = length(df.counts)))
    for g in groupby(@where(results, :action .== "cache", :set .>= 6),
                     [:foodtype, :set])
        push!(res, [missing, g.foodtype[1], "cache", missing, missing, g.set[1],
                    mean(g.counts), sem(g.counts), 0, length(g.counts)])
    end
    res
end
function statistical_tests(exp::Experiment{:Clayton01_exp2}, data)
    tests = Test[]
    for g in groupby(@where(data, :set .== 6), :action)
        action  = g.action[1]
        id = "$action test exp 2"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = [:foodtype, :RI],
                                         id = :id, data = :counts),
                          exp.tests))
        if action == "inspect"
            for subg in groupby(g, :RI)
                id = "$action test exp 2 RI $(subg.RI[1])"
                push!(tests, Test(id,
                                  splitplotanova(subg,
                                                 exp.tests[id].locals,
                                                 betweenfactors = :group,
                                                 withinfactors = :foodtype,
                                                 id = :id, data = :counts),
                                  exp.tests))
            end
            for subg in groupby(g, :group)
                group = subg.group[1]
                id = "$action test exp 2 group $group"
                push!(tests, Test(id,
                                  anova(subg, @formula(counts ~ foodtype * RI), exp.tests[id].locals),
                                  exp.tests))
                if group == "degrade"
                    for subsubg in groupby(subg, :RI)
                        id = "$action test exp 2 group $group RI $(subsubg.RI[1])"
                        push!(tests, Test(id,
                                          anova(subsubg, @formula(counts ~ foodtype), exp.tests[id].locals),
                                          exp.tests))
                    end
                end
            end
        end
    end
    datatest2inspect = sort(@where(data, :set .== 6, :action .== "inspect"), [:id, :RI, :foodtype])
    push!(tests, Test("first inspect test exp 2",
                      chisqtest(firstinspect_dist(@where(datatest2inspect, :group .== "degrade")),
                                firstinspect_dist(@where(datatest2inspect, :group .== "replenish"))),
                      exp.tests))
    TestCollection(tests)
end
function run!(::Experiment{:Clayton01_exp2}, models)
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
            # training before experiment 2 (July 1999)
            for foodtype in [Mealworm, Cricket]
                Clayton01_trial!(m, results, group, id, 0, Peanut, foodtype, 28u"hr",
                       degrade = isdegrade(group, foodtype, 28u"hr"), pilfer = false)
            end
            # test experiment 2
            ris = [4u"hr", 28u"hr"]
            isodd(id) && reverse!(ris)
            for wait in ris
                Clayton01_trial!(m, results, group, id, 6, Mealworm, Cricket, wait,
                       degrade = false, pilfer = true)
                # interleaved training trials
                for foodtype in [Mealworm, Cricket]
                    Clayton01_trial!(m, results, group, id, 0, Peanut, foodtype, 28u"hr",
                           degrade = isdegrade(group, foodtype, 28u"hr"), pilfer = false)
                end
            end
        end
    end
    results
end

function _summarize(::Experiment{:Clayton01_exp3}, results)
    res = [combine(groupby(@where(results, :action .== "inspect", :set .== 1),
                           [:group, :foodtype, :action, :trial]),
             df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                             firstinspection = mean(df.firstinspection),
                             n = length(df.counts)));
           combine(groupby(@where(results, :action .== "cache", :set .== 1), :foodtype),
              df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                              group = missing, action = "cache", trial = missing,
                              firstinspection = missing, n = length(df.counts)))]
end
function statistical_tests(exp::Experiment{:Clayton01_exp3}, data)
    tests = Test[]
    testdata = @where(data, :set .== 1)
    sort!(testdata, [:id, :foodtype, :trial])
    for g in groupby(testdata, :action)
        action = g.action[1]
        push!(tests, Test(action,
                          splitplotanova(g,
                                         exp.tests[action].locals,
                                         betweenfactors = :group,
                                         withinfactors = [:foodtype, :trial],
                                         id = :id, data = :counts),
                          exp.tests))
        if action == "inspect"
            for subg in groupby(g, :trial)
                id = "$action $(subg.trial[1])"
                push!(tests, Test(id,
                                  splitplotanova(subg,
                                                 exp.tests[id].locals,
                                                 betweenfactors = :group,
                                                 withinfactors = :foodtype,
                                                 id = :id, data = :counts),
                                  exp.tests))
            end
            for subg in groupby(g, :group)
                group = subg.group[1]
                id = "$action $group"
                push!(tests, Test(id,
                                  splitplotanova(subg,
                                                 exp.tests[id].locals,
                                                 betweenfactors = [],
                                                 withinfactors = [:foodtype, :trial],
                                                 id = :id, data = :counts),
                                  exp.tests))
                if group == "degrade"
                    for subsubg in groupby(subg, :trial)
                        trial = subsubg.trial[1]
                        condbigger = trial == "mc" ? "cricket" : "mealworm"
                        condsmaller = trial == "mc" ? "mealworm" : "cricket"
                        push!(tests, Test("$action $group $trial",
                                          is_significantly_bigger(subsubg,
                                                                  conditionkey = :foodtype,
                                                                  condbigger = condbigger,
                                                                  condsmaller = condsmaller,
                                                                  valuekey = :counts),
                                          exp.tests))
                    end
                end
            end
            push!(tests, Test("first inspectes",
                              chisqtest(firstinspect_dist(@where(g, :group .== "degrade")),
                                        firstinspect_dist(@where(g, :group .== "replenish"))),
                              exp.tests))
        end
    end
    TestCollection(tests)
end
function run!(::Experiment{:Clayton01_exp3}, models)
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
            # training (November 1999)
            for wait in [28u"hr", 4u"hr"]
                for foodtype in [Mealworm, Cricket]
                    Clayton01_trial!(m, results, group, id, 0, Peanut, foodtype, wait,
                           degrade = isdegrade(group, foodtype, wait), pilfer = false)
                end
            end
            # testing
            trials = [(Cricket, Mealworm), (Mealworm, Cricket)]
            i >= 4 && reverse!(trials)
            for (food1, food2) in trials
                Clayton01_trial!(m, results, group, id, 1, food1, food2, 4u"hr",
                       degrade = false, pilfer = true, bothtrayspresent = true,
                       waitbetween = 24u"hr")
                # interleaved training
                for foodtype in [Mealworm, Cricket]
                    Clayton01_trial!(m, results, group, id, 0, Peanut, foodtype, 4u"hr",
                           degrade = false, pilfer = false)
                end
            end
        end
    end
    results
end

function _summarize(::Experiment{:Clayton01_exp4}, results)
    res = [combine(groupby(@where(results, :action .== "inspect", :set .== 1),
                           [:group, :foodtype, :action, :RI]),
             df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                             firstinspection = mean(df.firstinspection),
                             n = length(df.counts)));
           combine(groupby(@where(results, :action .== "cache", :set .== 1),
                           [:group, :foodtype]),
              df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                              action = "cache", RI = missing,
                              firstinspection = missing, n = length(df.counts)))]
end
function statistical_tests(exp::Experiment{:Clayton01_exp4}, data)
    tests = Test[]
    datacache = @where(data, :action .== "cache", :set .== 1)
    id = "cache"
    push!(tests, Test(id,
                      splitplotanova(datacache,
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = [:foodtype, :RI],
                                     id = :id, data = :counts),
                      exp.tests))
    for g in groupby(datacache, :foodtype)
        id = "cache $(g.foodtype[1])"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = :RI,
                                         id = :id, data = :counts),
                          exp.tests))
    end
    datacache = @where(data, :action .== "inspect", :set .== 1)
    sort!(datacache, [:id, :foodtype, :RI])
    id = "inspect"
    push!(tests, Test(id,
                      splitplotanova(datacache,
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = [:foodtype, :RI],
                                     id = :id, data = :counts),
                      exp.tests))
    for g in groupby(datacache, :RI)
        id = "inspect $(g.RI[1])"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = :foodtype,
                                         id = :id, data = :counts),
                          exp.tests))
    end
    datacacheegrade = @where(datacache, :group .== "degrade")
    id = "inspect degrade"
    push!(tests, Test(id,
                      splitplotanova(datacacheegrade,
                                     exp.tests[id].locals,
                                     betweenfactors = [],
                                     withinfactors = [:foodtype, :RI],
                                     id = :id, data = :counts),
                      exp.tests))
    for g in groupby(datacacheegrade, :RI)
        id = "inspect degrade $(g.RI[1])"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = [],
                                         withinfactors = :foodtype,
                                         id = :id, data = :counts),
                          exp.tests))
    end
    push!(tests, Test("first inspectes",
                      chisqtest(firstinspect_dist(@where(datacache, :group .== "degrade")),
                                firstinspect_dist(@where(datacache, :group .== "replenish"))),
                      exp.tests))
    TestCollection(tests)
end
function run!(::Experiment{:Clayton01_exp4}, models)
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
            # training (December 1999)
            Clayton01_trial!(m, results, group, id, 0, Peanut, Mealworm, 4u"hr",
                   degrade = false, pilfer = false)
            remove!(m, Any)
            wait!(m, 4u"hr")
            tray1 = Tray(hack(1)) # one half of tray
            tray2 = Tray(hack(2)) # second half of tray
            add!(m, tray1)
            add!(m, Peanut, 50)
            wait!(m, 15u"minute")
            remove!(m, Any)
            push!(results, [group, "peanut", id, 1, "pm", 28, "cache", countcache(tray1), missing])
            add!(m, tray2)
            add!(m, Mealworm, 50)
            wait!(m, 15u"minute")
            remove!(m, Any)
            push!(results, [group, "mealworm", id, 1, "pm", 28, "cache", countcache(tray2), missing])
            add!(m, MaintenanceDiet)
            wait!(m, 30u"minute" + 23u"hr")
            tray3 = Tray(hack(1)) # one half of tray
            tray4 = Tray(hack(2)) # second half of tray
            add!(m, tray3)
            add!(m, Peanut, 50)
            wait!(m, 15u"minute")
            remove!(m, Any)
            push!(results, [group, "peanut", id, 1, "pm", 4, "cache", countcache(tray3), missing])
            add!(m, tray4)
            add!(m, Mealworm, 50)
            wait!(m, 15u"minute")
            remove!(m, Any)
            push!(results, [group, "mealworm", id, 1, "pm", 4, "cache", countcache(tray4), missing])
            wait!(m, 4u"hr")
            pilfer!(tray1); pilfer!(tray2); pilfer!(tray3); pilfer!(tray4)
            add!(m, tray1); add!(m, tray2)
            inspectionobserver = InspectionObserver()
            add!(m, inspectionobserver)
            wait!(m, 5u"minute")
            remove!(m, Any)
            push!(results, [group, "peanut", id, 1, "pm", 28, "inspect",
                            countinspections(inspectionobserver, tray1),
                            firstinspection(inspectionobserver, tray1)])
            push!(results, [group, "mealworm", id, 1, "pm", 28, "inspect",
                            countinspections(inspectionobserver, tray2),
                            firstinspection(inspectionobserver, tray2)])
            add!(m, tray3); add!(m, tray4)
            inspectionobserver = InspectionObserver()
            add!(m, inspectionobserver)
            wait!(m, 5u"minute")
            remove!(m, Any)
            push!(results, [group, "peanut", id, 1, "pm", 4, "inspect",
                            countinspections(inspectionobserver, tray3),
                            firstinspection(inspectionobserver, tray3)])
            push!(results, [group, "mealworm", id, 1, "pm", 4, "inspect",
                            countinspections(inspectionobserver, tray4),
                            firstinspection(inspectionobserver, tray4)])
        end
    end
    results
end
