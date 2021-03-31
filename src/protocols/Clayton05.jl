# Clayton, N. S. and Dally, J. and Gilbert, J. and Dickinson, A. (2005),
# Food Caching by Western Scrub-Jays (Aphelocoma californica) Is Sensitive to
# the Conditions at Recovery. Journal of Experimental Psychology: Animal
# Behavior Processes, 2:115-124

function _summarize(::Union{Experiment{:Clayton05_exp1}, Experiment{:Clayton05_exp2}},
                       data)
    combine(groupby(data, [:group, :trial, :action, :foodtype]),
	   df -> DataFrame(μ = mean(df.items), sem = sem(df.items)))
end
function statistical_tests(exp::Experiment{:Clayton05_exp1}, data)
    tests = Test[]
    id = "group × foodtype first trial"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :trial .== 1),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = :foodtype,
                                     id = :id, data = :items),
                      exp.tests))
    id = "group × trial × foodtype"
    push!(tests, Test(id,
                      splitplotanova(data,
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = [:trial, :foodtype],
                                     id = :id, data = :items),
                      exp.tests))
    for g in groupby(data, :group)
        groupname = g.group[1]
        id = "Group $groupname"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = [],
                                         withinfactors = [:trial, :foodtype],
                                         id = :id, data = :items),
                          exp.tests))
        if groupname == "consistent degrade"
            id = "Group $groupname: more worms than nuts in trial 1"
            push!(tests, Test(id,
                              anova(@where(g, :trial .== 1),
                                    @formula(items ~ foodtype + id), exp.tests[id].locals),
                              exp.tests))
            id = "Group $groupname: more nuts than worms in trials 3-6"
            push!(tests, Test(id,
                              splitplotanova(@where(g, (|).([:trial .== i
                                                             for i in 3:6]...)),
                                             exp.tests[id].locals,
                                             betweenfactors = [],
                                             withinfactors = [:trial, :foodtype],
                                             id = :id, data = :items),
                              exp.tests))
            for subg in groupby(g, :foodtype)
                foodtype = subg.foodtype[1]
                id = "Group consistent degrade: $foodtype"
                push!(tests, Test(id,
                                  anova(subg, @formula(items ~ trial + id), exp.tests[id].locals),
                                  exp.tests))
            end
        end
    end
    for g in groupby(data, :foodtype)
        id = "Foodtype $(g.foodtype[1])"
        push!(tests, Test(id,
                          splitplotanova(g,
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = :trial,
                                         id = :id, data = :items),
                          exp.tests))
    end
    TestCollection(tests)
end
function foodtypelabel(f)
    if f === Peanut
        "nuts"
    elseif f === Waxworm || f === Mealworm
        "worms"
    elseif f === Pineapple
        "pineapple"
    elseif f === Salami
        "salami"
    end
end
@inline function Clayton05_trial!(m, results, group, id, trial;
                                  longRIduration = 100u"hr",
                                  longRI = id > 2 && trial in (1, 4, 5, 7, 9) ||
                                           id <= 2 && trial in (2, 3, 6, 8, 10),
                                  foodtype1 = Peanut, foodtype2 = Waxworm,
                                  treatment = group in ("consistent degrade", "partial degrade") ?  "degrade" : group == "replenish" ? "none" : "pilfer",
                                  pilfer = group == "consistent pilfer" ||
                                           group == "partial pilfer" && longRI,
                                  degrade = group == "consistent degrade" ||
                                            group == "partial degrade" && longRI)
    add!(m, MaintenanceDiet) # Sunday 20:00
    wait!(m, 24u"hr")
    remove!(m, Any)          # Monday 20:00
    wait!(m, 12u"hr")
    add!(m, foodtype1, 50)      # Tuesday 8:00
    add!(m, foodtype2, 50)
    tray = Tray(1)
    add!(m, tray)
    wait!(m, 15u"minute")
    remove!(m, Any)
    if longRI
        add!(m, MaintenanceDiet)
        wait!(m, longRIduration - 4u"hr")
        remove!(m, Any)
    end
    wait!(m, 4u"hr")
    for foodtype in [foodtype1, foodtype2]
        push!(results, [group, trial, "cache",
                        foodtypelabel(foodtype),
                        id,
                        group in ("consistent degrade", "consistent pilfer"),
                        treatment,
                        countcache(tray, foodtype)])
    end
    degrade && degrade!(tray, foodtype2)
    pilfer && pilfer!(tray, foodtype2)
    remove!(m, Any)
    add!(m, tray)
    wait!(m, 10u"minute")
    remove!(m, Any)         # Tuesday 12:25 or Saturday 12:25
    add!(m, MaintenanceDiet)
    wait!(m, 7u"hr" + 35u"minute" + (longRI ? 1u"d" : longRIduration - 4u"hr"))
end
function run!(::Experiment{:Clayton05_exp1}, models)
    results = DataFrame(group = String[], trial = Int[], action = String[],
                        foodtype = String[],
                        id = Int[], consistent = Bool[], treatment = String[],
                        items = Int[])
    id = 0
    for group in ["replenish", "consistent degrade", "partial degrade"]
        for i in 1:4
            id += 1
            m = models[id]
            for trial in 1:6
                Clayton05_trial!(m, results, group, id, trial)
            end
        end
    end
    results
end

function statistical_tests(exp::Experiment{:Clayton05_exp2}, data)
    tests = Test[]
    id = "group × foodtype first trial"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :trial .== 1),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = :foodtype,
                                     id = :id, data = :items),
                      exp.tests))
    id = "Group × Food Type × Trial for replenish, consistent degrade and partial degrade"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :group .!= "consistent pilfer",
                                                  :group .!= "partial pilfer"),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = [:trial, :foodtype],
                                     id = :id, data = :items),
                      exp.tests))
    for foodtype in ("nuts", "worms")
        id = "Group × Trial for $foodtype"
        push!(tests, Test(id,
                          splitplotanova(@where(data, :group .!= "consistent pilfer",
                                                      :group .!= "partial pilfer",
                                                      :foodtype .== foodtype),
                                         exp.tests[id].locals,
                                         betweenfactors = :group,
                                         withinfactors = :trial,
                                         id = :id, data = :items),
                          exp.tests))
    end
    for g in groupby(data, [:group, :foodtype])
        groupname = g.group[1]
        foodtype = g.foodtype[1]
        (groupname == "consistent pilfer" || groupname == "partial pilfer") && continue
        id = "Change in caching $foodtype $groupname"
        push!(tests, Test(id,
                          anova(g, @formula(items ~ trial + id), exp.tests[id].locals),
                          exp.tests))
    end
    id = "no difference between worms cache by replenish and partial degrade in trials 3-8"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :group .!= "consistent pilfer",
                                                  :group .!= "partial pilfer",
                                                  :group .!= "consistent degrade",
                                                  :foodtype .== "worms",
                                                  3 .<= :trial .<= 8),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = :trial,
                                     id = :id, data = :items),
                      exp.tests))
    id = "more worms cache by consistent degrade than partial degrade in trials 3-8"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :group .!= "consistent pilfer",
                                                  :group .!= "partial pilfer",
                                                  :group .!= "replenish",
                                                  :foodtype .== "worms",
                                                  3 .<= :trial .<= 8),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = :trial,
                                     id = :id, data = :items),
                      exp.tests))
    id = "more nuts cache by replenish than partial degrade in trials 4-8"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :group .!= "consistent pilfer",
                                                  :group .!= "partial pilfer",
                                                  :group .!= "consistent degrade",
                                                  :foodtype .== "nuts",
                                                  4 .<= :trial .<= 8),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = :trial,
                                     id = :id, data = :items),
                      exp.tests))
    id = "more nuts cache by consistent degrade than replenish in trials 4-8"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :group .!= "consistent pilfer",
                                                  :group .!= "partial pilfer",
                                                  :group .!= "partial degrade",
                                                  :foodtype .== "nuts",
                                                  4 .<= :trial .<= 8),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = :trial,
                                     id = :id, data = :items),
                      exp.tests))
    id = "First trial pilfer"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :group .!= "replenish",
                                                  :trial .== 1),
                                     exp.tests[id].locals,
                                     betweenfactors = :group,
                                     withinfactors = [:foodtype],
                                     id = :id, data = :items),
                      exp.tests))
    id = "compare pilfer, degrade"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :group .!= "replenish"),
                                     exp.tests[id].locals,
                                     betweenfactors = [:treatment, :consistent],
                                     withinfactors = [:foodtype, :trial],
                                     id = :id, data = :items),
                      exp.tests))
    TestCollection(tests)
end
function run!(::Experiment{:Clayton05_exp2}, models)
    results = DataFrame(group = String[], trial = Int[], action = String[],
                        foodtype = String[],
                        id = Int[], consistent = Bool[], treatment = String[],
                        items = Int[])
    id = 0
    for group in ["replenish", "consistent degrade", "partial degrade",
                  "consistent pilfer", "partial pilfer"]
        for i in 1:(group in ["consistent pilfer", "partial pilfer"] ? 5 : 4)
            id += 1
            m = models[id]
            for trial in 1:8
                Clayton05_trial!(m, results, group, id, trial,
                                 longRIduration = 28u"hr")
            end
        end
    end
    results
end

function _summarize(::Experiment{:Clayton05_exp3}, results)
    res = combine(groupby(results, [:group, :trial, :action, :foodtype]),
       d -> DataFrame(μ = mean(d.items), n = length(d.items)))
    for foodtype in ("pineapple", "salami")
        data = @where(results, :group .== "partial degrade", :treatment .== foodtype)
        push!(res, ["partial degrade", missing, foodtype, "cache",
                        mean(data.items), length(data.items)])
    end
    res
end
# key:      here - paper
#          group - group
#      treatment - foodtype
#          trial - trial
#       foodtype - degrade
function statistical_tests(exp::Experiment{:Clayton05_exp3}, data)
    tests = Test[]
    id = "overall"
    push!(tests, Test(id,
                      splitplotanova(data,
                                     exp.tests[id].locals,
                                     betweenfactors = [:group, :treatment],
                                     withinfactors = [:foodtype, :trial],
                                     id = :id, data = :items),
                      exp.tests))
    id = "trial 1"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :trial .== 1),
                                     exp.tests[id].locals,
                                     betweenfactors = [:group, :treatment],
                                     withinfactors = :foodtype, id = :id,
                                     data = :items),
                      exp.tests))
    for g in groupby(data, :group)
        group = g.group[1]
        push!(tests, Test(group,
                          splitplotanova(g,
                                         exp.tests[group].locals,
                                         betweenfactors = :treatment,
                                         withinfactors = [:foodtype, :trial],
                                         id = :id, data = :items),
                          exp.tests))
        if group == "consistent degrade"
            for subg in groupby(g, :trial)
                id = "$group trial $(subg.trial[1])"
                push!(tests, Test(id,
                                  splitplotanova(subg,
                                                 exp.tests[id].locals,
                                                 betweenfactors = :treatment,
                                                 withinfactors = :foodtype,
                                                 id = :id, data = :items),
                                  exp.tests))
            end
        end
    end
    TestCollection(tests)
end
function run!(::Experiment{:Clayton05_exp3}, models)
    results = DataFrame(group = String[], trial = Union{Int,Missing}[],
                        action = String[],
                        foodtype = String[],
                        id = Int[], consistent = Bool[], treatment = String[],
                        items = Int[])
    id = 0
    for group in ["consistent degrade", "partial degrade"]
        n = group == "consistent degrade" ? 6 : 8
        for i in 1:n
            id += 1
            m = models[id]
            for trial in 1:10
                Clayton05_trial!(m, results, group, id, trial,
                                 longRIduration = 28u"hr",
                                 foodtype1 = i <= n/2 ? Pineapple : Salami,
                                 foodtype2 = i <= n/2 ? Salami : Pineapple,
                                 treatment = i <= n/2 ? "salami" : "pineapple")
            end
        end
    end
    for i in 1:nrow(results)
        results.foodtype[i] = results.foodtype[i] == results.treatment[i] ? "degrading" : "nondegrading"
    end
    results
end


function _summarize(::Experiment{:Clayton05_exp4}, results)
    combine(groupby(results, [:trial, :action, :foodtype]),
        d -> DataFrame(μ = mean(d.items), n = length(d.items)))
end
function statistical_tests(exp::Experiment{:Clayton05_exp4}, data)
    tests = Test[]
    id = "overall"
    push!(tests, Test(id,
                      splitplotanova(data,
                                     exp.tests[id].locals,
                                     betweenfactors = [],
                                     withinfactors = [:foodtype, :trial],
                                     id = :id, data = :items),
                      exp.tests))
    id = "trial 4"
    push!(tests, Test(id,
                      anova(@where(data, :trial .== 4),
                            @formula(items ~ foodtype + id), exp.tests[id].locals),
                      exp.tests))
    for g in groupby(data, :foodtype)
        push!(tests, Test(g.foodtype[1],
                          anova(g, @formula(items ~ trial + id),
                                exp.tests[g.foodtype[1]].locals),
                          exp.tests))
    end
    push!(tests, Test("worms 1-2",
                      is_significantly_bigger(@where(data, :foodtype .== "worms"),
                                              condbigger = 1, condsmaller = 2,
                                              conditionkey = :trial,
                                              valuekey = :items, paired = true),
                      exp.tests))
    TestCollection(tests)
end
function run!(::Experiment{:Clayton05_exp4}, models)
    results = DataFrame(group = String[], trial = Union{Int,Missing}[],
                        action = String[],
                        foodtype = String[],
                        id = Int[], consistent = Bool[], treatment = String[],
                        items = Int[])
    for i in 1:6
        m = models[i]
        for trial in 1:4
            # TODO: how to deal with test at the end of trial 4?
            Clayton05_trial!(m, results, "", i, trial,
                             longRI = true, degrade = true,
                             longRIduration = trial in (1, 3) ? 76u"hr" : 52u"hr",
                             foodtype2 = Mealworm)
        end
    end
    results
end
