# de Kort, Selvino R. and Correia, Sérgio P. C. and Alexis, Dean M. and
# Dickinson, Anthony and Clayton, Nicola S., The control of food-caching
# behavior by Western scrub-jays (Aphelocoma californica). Journal of
# Experimental Psychology: Animal Behavior Processes 33:361-370, 2007.
# http://dx.doi.org/10.1037/0097-7403.33.4.361
#

function _summarize(::Experiment{:deKort07_exp1}, results)
	combine(groupby(results, [:exp, :group, :action, :trial]),
				 df -> DataFrame(μ = mean(df.cache), sem = sem(df.cache)))
end
function statistical_tests(exp::Experiment{:deKort07_exp1}, data)
    tests = Test[]
    for g in groupby(data, :exp)
        id = "Experiment $(g.exp[1])"
        test = Test(id,
                    splitplotanova(g,
                                   exp.tests[id].locals,
                                   betweenfactors = :group,
                                   withinfactors = :trial,
                                   id = :id, data = :cache),
                    exp.tests)
        push!(tests, test)
    end
    TestCollection(tests)
end
function run!(exp::Experiment{:deKort07_exp1}, models; N = 16, samemodels = false)
    results = DataFrame(exp = String[], group = String[], action = String[],
                        trial = Int[],
						id = Int[], cache = Int[])
	id = 0
	for exp in ("a", "b")		# experiments
		id = samemodels ? 0 : id
		for i in 1:N			# birds
			id += 1
			m = models[id]
			add!(m, MaintenanceDiet)
			for trial in 1:6	# trials
				remove!(m, MaintenanceDiet)
				wait!(m, 3u"hr")
				add!(m, Mealworm, 50)
				trayx = Tray(0, trial)
				add!(m, trayx)
				wait!(m, 15u"minute")
				remove!(m, Any)
				add!(m, MaintenanceDiet)
				cache = countcache(trayx)
				wait!(m, 28.25u"hr")
				remove!(m, MaintenanceDiet)
				wait!(m, 1u"hr")
				group = "replenish"
				if exp == "a" && id > div(N, 2)
					degrade!(trayx)
					group = "degrade"
				elseif exp == "b" && id % 2 == 1
					pilfer!(trayx)
					group = "pilfer"
				end
				push!(results, [exp, group, "cache", trial, id, cache])
				add!(m, trayx)
				wait!(m, 10u"minute")
				remove!(m, Any)
				add!(m, MaintenanceDiet)
				wait!(m, 20u"minute" + 15u"hr" + 1u"d")
			end
		end
	end
	results
end

function _summarize(::Experiment{:deKort07_exp2}, results)
	combine(groupby(results, [:exp, :tray, :action, :trial]),
				 df -> DataFrame(μ = mean(df.cache), sem = sem(df.cache)))
end
function statistical_tests(exp::Experiment{:deKort07_exp2}, data)
    groups = groupby(data, [:exp])
    tests = Test[]
    for g in groups
        id = "Experiment $(g.exp[1]) tray × trial"
        test = Test(id,
                    splitplotanova(g,
                                   exp.tests[id].locals,
                                   betweenfactors = [],
                                   withinfactors = [:tray, :trial],
                                   id = :id, data = :cache),
                    exp.tests)
        push!(tests, test)
        subgroups = groupby(g, :tray)
        for (i, sb) in enumerate(subgroups)
            id = "Experiment $(g.exp[1]), tray $(sb.tray[1])"
            test = Test(id,
                        anova(sb, @formula(cache ~ trial + id), exp.tests[id].locals),
                        exp.tests)
            push!(tests, test)
        end
    end
    push!(tests, Test("Experiment a, trial 6",
                      is_significantly_bigger(@where(groups[1], :trial .== 6),
                                         condbigger = "replenish",
                                         condsmaller = "degrade",
                                         conditionkey = :tray,
                                         valuekey = :cache),
                      exp.tests))
    push!(tests, Test("Experiment b, trial 4",
                      is_significantly_bigger(@where(groups[2], :trial .== 4),
                                         condbigger = "replenish",
                                         condsmaller = "pilfer",
                                         conditionkey = :tray,
                                         valuekey = :cache),
                      exp.tests))
    TestCollection(tests)
end
function run!(exp::Experiment{:deKort07_exp2}, models; Na = 10, Nb = 8, N = 0, samemodels = false)
    results = DataFrame(exp = String[], tray = String[], action = String[],
                        trial = Int[],
						id = Int[], cache = Int[])
	id = 0
	for exp in ("a", "b")		# experiments
		id = samemodels ? 0 : id
		for i in 1:(N != 0 ? N : exp == "a" ? Na : Nb)	# birds
			id += 1
			m = models[id]
			add!(m, MaintenanceDiet)
			for trial in 1:(exp == "a" ? 6 : 4)	# trials
				remove!(m, MaintenanceDiet)
				wait!(m, 3u"hr")
				add!(m, Mealworm, 25)
				trayx = Tray(0, trial)
				trayy = Tray(1, trial + 10)
				add!(m, trayx)
				add!(m, trayy)
				wait!(m, 15u"minute")
				remove!(m, Any)
				add!(m, MaintenanceDiet)
				cachex = countcache(trayx)
				cachey = countcache(trayy)
				wait!(m, 28.25u"hr")
				remove!(m, MaintenanceDiet)
				wait!(m, 1u"hr")
				if exp == "a"
					degrade!(trayx)
					tray = "degrade"
				else
					pilfer!(trayx)
					tray = "pilfer"
				end
				push!(results, [exp, tray, "cache", trial, id, cachex])
				push!(results, [exp, "replenish", "cache", trial, id, cachey])
				add!(m, trayx)
				add!(m, trayy)
				wait!(m, 10u"minute")
				remove!(m, Any)
				add!(m, MaintenanceDiet)
				wait!(m, 20u"minute" + 15u"hr" + 1u"d")
			end
		end
	end
	results
end

function _summarize(::Experiment{:deKort07_exp3}, results)
	combine(groupby(results, [:tray, :trial, :action]),
				 df -> DataFrame(μ = mean(df.cache), sem = sem(df.cache)))
end
function statistical_tests(exp::Experiment{:deKort07_exp3}, data)
    tests = Test[]
    id = "tray × trial"
    push!(tests, Test(id,
                      splitplotanova(data,
                                     exp.tests[id].locals,
                                     betweenfactors = [:tray],
                                     withinfactors = [:trial],
                                     id = :id, data = :cache),
                      exp.tests))
    groups = groupby(data, :tray)
    for g in groups
        id = "Tray $(g.tray[1])"
        push!(tests, Test(id,
                          anova(g, @formula(cache ~ trial + id), exp.tests[id].locals),
                          exp.tests))
    end
    TestCollection(tests)
end
function run!(exp::Experiment{:deKort07_exp3}, models; N = 7)
    results = DataFrame(tray = String[], trial = Int[], action = String[],
						id = Int[], cache = Int[])
	for id in 1:N			# birds
		m = models[id]
		add!(m, MaintenanceDiet)
		for trial in 1:10	# trials
			remove!(m, MaintenanceDiet)
			wait!(m, 3u"hr")
			add!(m, Waxworm, 30)
			trayx = Tray(0, trial)
			trayy = Tray(1, trial + 10)
			add!(m, trayx)
			add!(m, trayy)
            cover!(trayy)
			wait!(m, 15u"minute")
			add!(m, Waxworm, 10)
			uncover!(trayy)
			cover!(trayx)
			wait!(m, 15u"minute")
			remove!(m, Any)
			add!(m, MaintenanceDiet)
			uncover!(trayx)
			cachex = countcache(trayx)
			cachey = countcache(trayy)
			wait!(m, 28u"hr")
			remove!(m, MaintenanceDiet)
			wait!(m, 1u"hr")
			pilfer!(trayx)
			push!(results, ["period1", trial, "cache", id, cachex])
			push!(results, ["period2", trial, "cache", id, cachey])
			add!(m, trayx)
			add!(m, trayy)
			wait!(m, 10u"minute")
			remove!(m, Any)
			add!(m, MaintenanceDiet)
			wait!(m, 20u"minute" + 15u"hr" + 1u"d")
		end
	end
	results
end

function _summarize(::Experiment{:deKort07_exp4}, results)
	combine(groupby(results, [:exp, :group, :action, :tray]),
				 df -> DataFrame(μ = mean(df.cache), sem = sem(df.cache)))
end
function statistical_tests(exp::Experiment{:deKort07_exp4}, data)
    groups = groupby(data, :exp)
    tests = Test[]
    id = "group × tray"
    test = Test(id,
                splitplotanova(groups[1],
                               exp.tests[id].locals,
                               betweenfactors = :group, withinfactors = :tray,
                               id = :id, data = :cache),
                exp.tests)
    push!(tests, test)
    push!(tests, Test("experimental group caches more in B than control",
                      is_significantly_bigger(@where(groups[1], :tray .== "B"),
                                              conditionkey = :group,
                                              condbigger = "experimental",
                                              condsmaller = "control",
                                              valuekey = :cache, paired = false),
                      exp.tests))
    push!(tests, Test("number of worms cache in A is the same across groups",
                      isnot_significantly_different(@where(groups[1], :tray .== "A"),
                                                    conditionkey = :group,
                                                    condition1 = "experimental",
                                                    condition2 = "control",
                                                    valuekey = :cache, paired = false),
                      exp.tests))
    push!(tests, Test("experimental group cache same numbers in A and B",
                      isnot_significantly_different(@where(groups[1], :group .== "experimental"),
                                                    conditionkey = :tray,
                                                    condition1 = "A",
                                                    condition2 = "B",
                                                    valuekey = :cache,
                                                    paired = false),
                      exp.tests))
    push!(tests, Test("control group caches more in A than in B",
                      is_significantly_bigger(@where(groups[1], :group .== "control"),
                                                     conditionkey = :tray,
                                                     condbigger = "A",
                                                     condsmaller = "B",
                                                     valuekey = :cache,
                                                     paired = false),
                      exp.tests))
    id = "Effect of tray on the worms cache"
    push!(tests, Test(id,
                      anova(groups[2], @formula(cache ~ tray + id), exp.tests[id].locals),
                      exp.tests))
    push!(tests, Test("more in B than A",
                      is_significantly_bigger(groups[2],
                                              conditionkey = :tray,
                                              condbigger = "B",
                                              condsmaller = "A",
                                              valuekey = :cache, paired = true),
                      exp.tests))
    push!(tests, Test("more in C than A",
                      is_significantly_bigger(groups[2],
                                              conditionkey = :tray,
                                              condbigger = "C",
                                              condsmaller = "A",
                                              valuekey = :cache, paired = true),
                      exp.tests))
    push!(tests, Test("same in B and C",
                      isnot_significantly_different(groups[2],
                                                    conditionkey = :tray,
                                                    condition1 = "B",
                                                    condition2 = "C",
                                                    valuekey = :cache, paired = true),
                      exp.tests))
    TestCollection(tests)
end
function run!(exp::Experiment{:deKort07_exp4}, models; Na = 8, Nb = 4, N = 0, samemodels = false)
	results = DataFrame(exp = String[], group = String[], tray = String[],
                        action = String[],
						id = Int[], cache = Int[])
	id = 0
	for exp in ("a", "b")						# experiments
		id = samemodels ? 0 : id
		for i in 1:(N != 0 ? N : exp == "a" ? Na : Nb)		# birds
			id += 1
			m = models[id]
			add!(m, MaintenanceDiet)
            for trial in 3:5	# 2 pretraining (not modeled), 2 training, 1 testing
				remove!(m, MaintenanceDiet)
				wait!(m, 3u"hr")
				add!(m, Waxworm, 30)
				trayx = Tray(0, trial)
				add!(m, trayx)
				if trial > 2
					trayy = Tray(1, trial + 10)
					if trial < 5; cover!(trayy); end
					add!(m, trayy)
                    if exp == "b"
                        trayz = Tray(2, trial + 20)
                        if trial < 5; cover!(trayz); end
                        add!(m, trayz)
                    end
				end
				wait!(m, 15u"minute")
				if trial == 5
					group = id > div(Na, 2) && exp == "a" ? "control" : "experimental"
					push!(results, [exp, group, "A", "cache", id, countcache(trayx)])
					push!(results, [exp, group, "B", "cache", id, countcache(trayy)])
					if exp == "b"
						push!(results, [exp, group, "C", "cache", id, countcache(trayz)])
					end
                    remove!(m, Any)
                    break # end of experiment
				end
				remove!(m, Any)
				add!(m, MaintenanceDiet)
				wait!(m, 28.25u"hr")
				remove!(m, MaintenanceDiet)
				wait!(m, 1u"hr")
				if trial > 2
					uncover!(trayy)
					add!(m, trayy)
					if exp == "b"
						uncover!(trayz)
						add!(m, trayz)
					end
					if id <= div(Na, 2) || exp == "b"
						trayy.eatableitems = deepcopy(trayx.eatableitems)
						empty!(trayx.eatableitems)
					end
				end
				add!(m, trayx)
				wait!(m, 10u"minute")
				remove!(m, Any)
				add!(m, MaintenanceDiet)
				wait!(m, 20u"minute" + 15u"hr" + 1u"d")
			end
			wait!(m, 11u"d")
		end
	end
	results
end

