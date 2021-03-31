# Raby, C. R. and Alexis, D. M. and Dickinson, A. and Clayton, N. S., Planning
# for the future by western scrub-jays, Nature 445:919-921, 2007,
# http://dx.doi.org/10.1038/nature05575

function _summarize(::Experiment{:Raby07_planningforbreakfast}, data)
    combine(groupby(data, [:tray, :action]),
				df -> DataFrame(μ = mean(df.items), sem = sem(df.items)))
end
function statistical_tests(exp::Experiment{:Raby07_planningforbreakfast}, data)
    test = is_significantly_bigger(data, conditionkey = :tray,
                                   condbigger = "no-breakfast",
                                   condsmaller = "breakfast", valuekey = :items)
    TestCollection(Test("More pine nuts in no-breakfast compartment",
                     test,
                     exp.tests))
end
function run!(exp::Experiment{:Raby07_planningforbreakfast}, models; N = 8)
    results = DataFrame(tray = String[], action = String[], id = Int[], items = Float64[])
	for id in 1:N
		m = models[id]
		trays = [Tray(i) for i in 1:2]
		for day in 1:7
			add!(m, MaintenanceDiet) # start at 9am on first day
			wait!(m, 8u"hr")
			remove!(m, MaintenanceDiet)
			add!(m, trays)
			wait!(m, 1.5u"hr")
			if day == 7
				add!(m, Pinenut, 30)
			else
				add!(m, PowderedPinenut, 30)
			end
			wait!(m, 30u"minute")
			if day == 7
				push!(results, ["breakfast", "cache", id, countcache(trays[1])])
				push!(results, ["no-breakfast", "cache", id, countcache(trays[2])])
				break
			end
			remove!(m, Any)
			wait!(m, 12u"hr")
			if (id + day) % 2 == 0
				add!(m, PowderedPinenut, 30)
				add!(m, trays[1])
			else
				add!(m, trays[2])
			end
			wait!(m, 2u"hr")
			remove!(m, Any)
		end
	end
	results
end

function _summarize(::Experiment{:Raby07_breakfastchoice}, results)
	combine(groupby(results, [:tray, :action, :foodtype]),
				df -> DataFrame(μ = mean(df.items), sem = sem(df.items)))
end
function statistical_tests(exp::Experiment{:Raby07_breakfastchoice}, data)
    id = "More different food cache"
    test = splitplotanova(data,
                          exp.tests[id].locals,
                          betweenfactors = [],
                          withinfactors = [:tray, :foodtype],
                          id = :id, data = :items)
    TestCollection(Test(id, test, exp.tests))
end
function run!(exp::Experiment{:Raby07_breakfastchoice}, models; N = 9)
    results = DataFrame(tray = String[], action = String[], foodtype = String[],
						id = Int[], items = Float64[])
	for id in 1:N
		m = models[id]
		trays = [Tray(i) for i in 1:2]
		for day in 1:7
			add!(m, MaintenanceDiet) # start at 9am on first day
			wait!(m, 8u"hr")
			remove!(m, MaintenanceDiet)
			add!(m, trays)
			wait!(m, 1.5u"hr")
			if day == 7
				add!(m, Peanut, 30)
				add!(m, Kibble, 30)
			else
				add!(m, PowderedPeanut, 30)
				add!(m, PowderedKibble, 30)
			end
			wait!(m, 30u"minute")
			if day == 7
				push!(results, ["same", "cache", "peanut", id, countcache(trays[1], Peanut)])
				push!(results, ["same", "cache", "kibble", id, countcache(trays[2], Kibble)])
				push!(results, ["other", "cache", "peanut", id, countcache(trays[2], Peanut)])
				push!(results, ["other", "cache", "kibble", id, countcache(trays[1], Kibble)])
				break
			end
			remove!(m, Any)
			wait!(m, 12u"hr")
			if (id + day) % 2 == 0
				add!(m, PowderedPeanut, 30)
				add!(m, trays[1])
			else
				add!(m, PowderedKibble, 30)
				add!(m, trays[2])
			end
			wait!(m, 2u"hr")
			remove!(m, Any)
		end
	end
	results
end
