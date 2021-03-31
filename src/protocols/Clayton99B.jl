# Clayton, N. S. and Dickinson A. (1999), Scrub jays (Aphelocoma coerulescens)
# remember the relative time of caching as well as the location and content of
# their caches. Journal of Comparative Psychology, 4:403-416
#
# Some of the results of this experiment are also reported in
# Clayton, N. S., Dickinson, A. (1998). Episodic-like memory during cache
# recovery by scrub jays. Nature, 395(6699), 272–274.

function _summarize(::Experiment{:Clayton99B_exp1}, results)
    inspect = combine(groupby(@where(results, :action .== "inspect"),
                              [:group, :trial, :RI, :action, :foodtype]),
                df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                                firstinspection = mean(df.firstinspection),
                                n = length(df.counts)))
    cachetraining = combine(groupby(@where(results, :action .== "cache", :trial .<= 4),
                                    [:group, :trial, :action, :foodtype]),
                       df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                                       RI = missing, firstinspection = missing,
                                       n = length(df.counts)))
    cachetest = combine(groupby(@where(results, :action .== "cache", :trial .== 5),
                                [:trial, :action, :foodtype]),
                       df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                                       RI = missing, firstinspection = missing,
                                       group = missing,
                                       n = length(df.counts)))
    [inspect; cachetraining; cachetest]
end
function statistical_tests(exp::Experiment{:Clayton99B_exp1}, data)
    tests = Test[]
    datacache = @where(data, :action .== "cache", :trial .<= 4)
    datainspect = @where(data, :action .== "inspect", :trial .<= 4)
    for action in ("cache", "inspect")
        push!(tests, Test(action,
                          splitplotanova(action == "cache" ? datacache : datainspect,
                                         exp.tests[action].locals,
                                         betweenfactors = :group,
                                         withinfactors = [:RI, :foodtype, :trial],
                                         id = :id, data = :counts),
                          exp.tests))
    end
    for g in groupby(datacache, :group)
        id = "cache foodtype × trial $(g.group[1])"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = [],
                                         withinfactors = [:RI, :foodtype, :trial],
                                         id = :id, data = :counts),
                          exp.tests))
    end
    for g in groupby(datainspect, :RI)
        RI = g.RI[1]
        id = "inspect $RI"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = [:foodtype, :trial],
                                         id = :id, data = :counts),
                          exp.tests))
        if RI == 124
            for subg in groupby(g, :group)
                id = "inspect $RI $(subg.group[1])"
                push!(tests, Test(id,
                                  splitplotanova(subg,
                                                 exp.tests[id].locals,
                                                 betweenfactors = [],
                                                 withinfactors = [:foodtype, :trial],
                                                 id = :id, data = :counts),
                                  exp.tests))
            end
            for subg in groupby(g, :foodtype)
                id = "inspect $RI $(subg.foodtype[1])"
                push!(tests, Test(id,
                                  splitplotanova(subg,
                                                 exp.tests[id].locals,
                                                 betweenfactors = :group,
                                                 withinfactors = [:trial],
                                                 id = :id, data = :counts),
                                  exp.tests))
            end
        end
    end
    datatest = @where(data, :trial .== 5)
    id = "test"
    push!(tests, Test(id,
                      splitplotanova(datatest,
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = [:RI, :foodtype],
                                     id = :id, data = :counts),
                      exp.tests))
    for g in groupby(datatest, :RI)
        RI = g.RI[1]
        id = "test $RI"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = :foodtype,
                                         id = :id, data = :counts),
                          exp.tests))
        if RI == 124
            for subg in groupby(g, :foodtype)
                id = "test $RI $(subg.foodtype[1])"
                push!(tests, Test(id,
                                  splitplotanova(subg,
                                                 exp.tests[id].locals,
                                                 betweenfactors = :group,
                                                 withinfactors = [],
                                                 id = :id, data = :counts),
                                  exp.tests))
            end
        end
    end
    TestCollection(tests)
end
# In the experiment 2 bird from the degrade group and one from the replenish
# group were excluded at testing because they failed to cache. We don't do this
# here.
function run!(::Experiment{:Clayton99B_exp1}, models)
    results = DataFrame(group = String[], trial = Int[],
                        RI = Union{Int, Missing}[], action = String[],
                        foodtype = String[], id = Int[], counts = Int[],
                        firstinspection = Union{Missing,Int}[])
    id = 0
    for group in ["replenish", "degrade", "pilfer"]
        for i in 1:(group == "pilfer" ? 7 : 8)
            id += 1
            m = models[id]
            for trial in 1:10               # 1-8 training, 9-10 testing
                remove!(m, Any)
                wait!(m, 4u"hr")
                trays = [Tray(hack(i)) for i in 1:2] # trays at different locations
                add!(m, trays[1])
                foodtypes = [Peanut, Waxworm]
                if i > 4
                    reverse!(foodtypes)
                    waxwormtray = 1
                else
                    waxwormtray = 2
                end
                add!(m, foodtypes[1], 50)
                wait!(m, 15u"minute")       # caching phase 1
                remove!(m, Any)
                add!(m, trays[2])
                add!(m, foodtypes[2], 50)
                wait!(m, 15u"minute")       # caching phase 2
                if trial%2 == 0 && trial <= 8 || trial%2 == 1 && trial > 8 # reverse order of test trials.
                    RI = 4
                else
                    RI = 124
                end
                for k in 1:2
                    push!(results, [group, div(trial + 1, 2), RI, "cache",
                                    lowercase(string(foodtypes[k])), id,
                                    countcache(trays[k]), missing])
                end
                remove!(m, Any)
                if RI == 4
                    wait!(m, 4u"hr")
                else
                    add!(m, MaintenanceDiet)
                    wait!(m, 120u"hr")
                    remove!(m, Any)
                    wait!(m, 4u"hr")
                    if group == "pilfer"
                        pilfer!(trays[waxwormtray])
                    elseif group == "degrade"
                        degrade!(trays[waxwormtray])
                    end
                end
                if trial > 8 # testing
                    map(tray -> pilfer!(tray), trays)
                end
                add!(m, trays)
                inspectionobserver = InspectionObserver()
                add!(m, inspectionobserver)
                wait!(m, 15u"minute")
                for k in 1:2
                    push!(results, [group, div(trial + 1, 2), RI, "inspect",
                                    lowercase(string(foodtypes[k])), id,
                                    countinspections(inspectionobserver, trays[k]),
                                    firstinspection(inspectionobserver, trays[k])])
                end
                remove!(m, Any)
                add!(m, MaintenanceDiet)
                wait!(m, 1u"d" + 15u"minute" + 15u"hr")
            end
        end
    end
    results
end

function _summarize(::Experiment{:Clayton99B_exp2}, results)
    inspect = combine(groupby(@where(results, :action .== "inspect"),
                              [:group, :trial, :order, :action, :foodtype]),
                df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                                firstinspection = mean(df.firstinspection),
                                n = length(df.counts)))
    cachetrainw = combine(groupby(@where(results, :action .== "cache",
                            :trial .== "train", :foodtype .== "waxworm"),
                                  [:trial, :action, :foodtype]),
                     df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                                     firstinspection = missing, group = missing,
                                     order = missing, n = length(df.counts)))
    cachetrainp = combine(groupby(@where(results, :action .== "cache",
                            :trial .== "train", :foodtype .== "peanut"),
                                  [:group, :trial, :action, :foodtype]),
                     df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                                     firstinspection = missing,
                                     order = missing, n = length(df.counts)))
    cachetest = combine(groupby(@where(results, :action .== "cache", :trial .== "test"),
                                [:group, :trial, :action, :foodtype]),
                     df -> DataFrame(μ = mean(df.counts), sem = sem(df.counts),
                                     firstinspection = missing,
                                     order = missing, n = length(df.counts)))
    [inspect; cachetrainw; cachetrainp; cachetest]
end
function statistical_tests(exp::Experiment{:Clayton99B_exp2}, data)
    tests = Test[]
    datatraincache = @where(data, :trial .== "train", :action .== "cache")
    id = "train cache"
    push!(tests, Test(id,
                      splitplotanova(datatraincache,
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = [:order, :foodtype],
                                     id = :id, data = :counts),
                      exp.tests))
    for g in groupby(datatraincache, :foodtype)
        id = "train cache $(g.foodtype[1])"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = [:order],
                                         id = :id, data = :counts),
                          exp.tests))
    end
    datainspect = @where(data, :action .== "inspect")
    for superg in groupby(datainspect, :trial)
        trial = superg.trial[1]
        id = "$trial inspect"
        push!(tests, Test(id,
                          splitplotanova(superg,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = [:order, :foodtype],
                                         id = :id, data = :counts),
                          exp.tests))
        for g in groupby(superg, :order)
            order = g.order[1]
            id = "$trial inspect $order"
            push!(tests, Test(id,
                              splitplotanova(g,
                                             exp.tests[id].locals,
                                             betweenfactors = :group,
                                             withinfactors = :foodtype,
                                             id = :id, data = :counts),
                              exp.tests))
            if order == "wp"
                for subg in groupby(g, :group)
                    id = "$trial inspect $order $(subg.group[1])"
                    push!(tests, Test(id,
                                      anova(subg, @formula(counts ~ foodtype), exp.tests[id].locals),
                                      exp.tests))
                end
            end
        end
    end
    TestCollection(tests)
end
function run!(::Experiment{:Clayton99B_exp2}, models)
    results = DataFrame(group = String[], trial = String[],
                        order = Union{Missing,String}[], action = String[],
                        foodtype = String[], id = Int[], counts = Int[],
                        firstinspection = Union{Missing, Int}[])
    id = 0
    for group in ["replenish", "degrade", "pilfer"] # the groups are the same as in exp1
        for i in 1:(group == "degrade" ? 5 : 6)
            id += 1
            for trial in 1:4               # 1-2 training, 3-4 testing
                m = models[id]
                remove!(m, Any)
                wait!(m, 4u"hr")
                trays = [Tray(hack(i)) for i in 1:2] # the used left/right hand side of the same tray
                add!(m, trays)
                foodtypes = [Peanut, Waxworm]
                cover!(trays[2])
                if (i <= 4 && isodd(trial)) || (i > 4 && iseven(trial))
                    reverse!(foodtypes)
                    waxwormtray = 1
                else
                    waxwormtray = 2
                end
                add!(m, foodtypes[1], 50)
                wait!(m, 15u"minute")       # caching phase 1
                uncover!(trays[2])
                remove!(m, Any)
                add!(m, MaintenanceDiet)
                wait!(m, 116u"hr")
                remove!(m, Any)
                wait!(m, 4u"hr")
                add!(m, trays)
                cover!(trays[1])
                add!(m, foodtypes[2], 50)
                wait!(m, 15u"minute")       # caching phase 2
                uncover!(trays[1])
                for k in 1:2
                    push!(results, [group, trial <= 2 ? "train" : "test",
                                    waxwormtray == 1 ? "wp" : "pw", "cache",
                                    lowercase(string(foodtypes[k])), id,
                                    countcache(trays[k]), missing])
                end
                remove!(m, Any)
                wait!(m, 4u"hr")
                if group == "pilfer" && waxwormtray == 1
                    pilfer!(trays[1])
                elseif group == "degrade" && waxwormtray == 1
                    degrade!(trays[1])
                end
                if trial > 2 # testing
                    pilfer!.(trays)
                end
                add!(m, trays)
                inspectionobserver = InspectionObserver()
                add!(m, inspectionobserver)
                wait!(m, 15u"minute")
                for k in 1:2
                    push!(results, [group, trial <= 2 ? "train" : "test",
                                    waxwormtray == 1 ? "wp" : "pw", "inspect",
                                    lowercase(string(foodtypes[k])), id,
                                    countinspections(inspectionobserver, trays[k]),
                                    firstinspection(inspectionobserver, trays[k])])
                end
                remove!(m, Any)
                add!(m, MaintenanceDiet)
                wait!(m, 1u"d" + 15u"minute" + 15u"hr")
            end
        end
    end
    results
end
