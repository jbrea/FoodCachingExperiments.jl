# Correia, Sérgio P.C. and Dickinson, Anthony and Clayton, Nicola S., Western
# Scrub-Jays Anticipate Future Needs Independently of Their Current Motivational
# State, Current Biology 17 (10), 856-861, http://dx.doi.org/10.1016/j.cub.2007.03.063
#
function _summarize(::Experiment{:Correia07_exp1}, results)
	combine(groupby(results, [:prefed, :action, :foodtype]),
				 df -> DataFrame(μ = mean(df.count), sem = sem(df.count)))
end
function statistical_tests(exp::Experiment{:Correia07_exp1}, data)
    groups = groupby(data, [:prefed])
    tests = Test[]
    id = "interaction"
    push!(tests, Test(id,
                      splitplotanova(data,
                                     exp.tests[id].locals,
                                     betweenfactors = [],
                                     withinfactors = [:prefed, :foodtype],
                                     id = :id, data = :count),
                      exp.tests))
    for g in groups
        if g.prefed[1] in ("both", "none")
            push!(tests, Test("prefed $(g.prefed[1])",
                              isnot_significantly_different(g,
                                                            conditionkey = :foodtype,
                                                            condition1 = "kibble",
                                                            condition2 = "pinenut",
                                                            valuekey = :count),
                              exp.tests))
        else
            conditions = ["kibble", "pinenut"]
            if g.prefed[1] == "kibble"
                reverse!(conditions)
            end
            push!(tests, Test("prefed $(g.prefed[1])",
                              is_significantly_bigger(g, conditionkey = :foodtype,
                                                      condbigger = conditions[1],
                                                      condsmaller = conditions[2],
                                                      valuekey = :count),
                              exp.tests))
        end
    end
    TestCollection(tests)
end
function run!(exp::Experiment{:Correia07_exp1}, models; N = 11)
    results = DataFrame(prefed = String[], action = String[],
                        foodtype = String[], id = Int[],
						count = Int[])
	for id in 1:N
		m = models[id]
		for prefed in ("pinenut", "kibble", "both", "none")
			if prefed in ("pinenut", "both"); add!(m, Pinenut, 100); end
			if prefed in ("kibble", "both"); add!(m, Kibble, 100); end
			wait!(m, 3u"hr")
			remove!(m, Any)
			add!(m, Pinenut, 30)
			add!(m, Kibble, 30)
			wait!(m, 10u"minute")
			push!(results, [prefed, "eat", "pinenut", id, 30 - countfooditems(m, Pinenut)])
			push!(results, [prefed, "eat", "kibble", id, 30 - countfooditems(m, Kibble)])
			remove!(m, Any)
			add!(m, MaintenanceDiet)
			wait!(m, 50u"minute" + 20u"hr") # next day; not specified in paper
			remove!(m, MaintenanceDiet)
		end
	end
	results
end

function _summarize(::Experiment{:Correia07_exp2}, results)
	combine(groupby(results, [:trial, :group, :foodtype, :action]),
				 df -> DataFrame(μ = mean(df.count), sem = sem(df.count)))
end
function statistical_tests(exp::Experiment{:Correia07_exp2}, data)
    groups = groupby(data, :action)
    tests = Test[]
    for g in groups
        if g.action[1] == "eat"
            id = "eat"
            test = Test(id,
                        splitplotanova(g,
                                       exp.tests[id].locals,
                                       betweenfactors = :group,
                                       withinfactors = [:foodtype, :trial],
                                       id = :id, data = :count),
                        exp.tests)
            push!(tests, test)
        else
            id = "cache"
            test = Test(id,
                        splitplotanova(g,
                                       exp.tests[id].locals,
                                       betweenfactors = [:group, :prefed],
                                       withinfactors = [:foodtype, :trial],
                                       id = :id, data = :count),
                        exp.tests)
            push!(tests, test)
            ddata = combine(groupby(g, [:trial, :group, :action, :id]),
                       df ->  begin
#                            df.foodtype[1] != df.foodtype[2] &&
#                            length(df.foodtype) == 2 || error(df)
                           sum(df.count) > 0 ? df.count[df.foodtype[1] == "prefed" ? 1 : 2]/sum(df.count) : missing end)
            dropmissing!(ddata, disallowmissing = true)
            ddata.x1 = float.(ddata.x1)
            for i in 1:3 # trials
                x = @where ddata :trial .== i :group .== "same"
                y = @where ddata :trial .== i :group .== "different"
                if length(x.x1) > 0 && length(y.x1) > 0
                    test = Test("trial $i: proportion cache",
                                utest(x.x1, y.x1),
                                exp.tests)
                    push!(tests, test)
                elseif length(y.x1) > 0
                    push!(tests, Test("trial $i: proportion cache",
                                      NoTest("no caching in same condition"),
                                      exp.tests,
                                      [1.]))
                else
                    push!(tests, Test("trial $i: proportion cache",
                                      NoTest("no caching at all"),
                                      exp.tests,
                                      [1.]))
                end
            end
        end
    end
    TestCollection(tests)
end
function run!(exp::Experiment{:Correia07_exp2}, models; N = 11)
	results = DataFrame(trial = Int[], group = String[],
                        prefed = String[], foodtype = String[],
						action = String[], id = Int[], count = Int[])
	for id in 1:N
		m = models[id]
		for trial in 1:3
		    tray = Tray()
            if id % 2 == 0
                prefed = Pinenut
            else
                prefed = Kibble
            end
            add!(m, prefed, 100)
            wait!(m, 3u"hr")
            remove!(m, Any)
            add!(m, Pinenut, 30)
            add!(m, Kibble, 30)
            add!(m, tray)
            wait!(m, 10u"minute")
            group = id > N/2 ? "different" : "same"
            for foodtype in (Pinenut, Kibble)
                food = foodtype == prefed ? "prefed" : "nonprefed"
                push!(results, [trial, group, string(prefed), food,
                                "eat", id, 30 - countfooditems(m, foodtype)])
                push!(results, [trial, group, string(prefed), food,
                                "cache", id, countcache(tray, foodtype)])
            end
            remove!(m, Any)
            wait!(m, 30u"minute")
            if group == "same"
                add!(m, prefed, 100)
            else
                add!(m, setdiff([Pinenut, Kibble], [prefed])[1], 100)
            end
            wait!(m, 3u"hr")
            remove!(m, Any)
            add!(m, tray)
            wait!(m, 10u"minute")
            remove!(m, Any)
            add!(m, MaintenanceDiet)
            wait!(m, 10u"minute" + 16u"hr") # next day; not specified in paper
            remove!(m, MaintenanceDiet)
		end
	end
	results
end
