# Cheke, L. G. and Clayton, N. S., Eurasian jays (Garrulus glandarius) overcome
# their current desires to anticipate two distinct future needs and plan for
# them appropriately, Biology Letters 8:171-175, 2011,
# http://dx.doi.org/10.1098/rsbl.2011.0909
#
# id-bird mapping: 1: Hoy, 2: Wiggins, 3: Hunter, 4: Ainsley
# Wiggins and Ainsley were fed with raisins instead of suet pellets. For
# simplicity I use suet pellets for all birds in this protocol.

function _summarize(::Experiment{:Cheke11_specsat}, data)
	combine(groupby(data, [:prefed, :action, :foodtype]),
				df -> DataFrame(μ = mean(df.items),
                                sem = sem(float.(df.items)),
								n = length(df.items)))
end
function statistical_tests(exp::Experiment{:Cheke11_specsat}, data)
    tests = Test[]
    push!(tests, Test("overall",
                      splitplotanova(data, exp.tests["overall"].locals,
                                     betweenfactors = [],
                                     withinfactors = [:prefed, :foodtype],
                                     id = :id, data = :items),
                      exp.tests))
    for action in ("cache", "eat")
        push!(tests, Test(action,
                          splitplotanova(@where(data, :action .== action),
                                         exp.tests[action].locals,
                                         betweenfactors = [],
                                         withinfactors = [:prefed, :foodtype],
                                         id = :id, data = :items),
                          exp.tests))
    end
    TestCollection(tests)
end
function run!(exp::Experiment{:Cheke11_specsat}, models; N = 4)
	results = DataFrame(prefed = String[], action = String[],
					    foodtype = String[], id = Int[], items = Float64[])
	for id in 1:N
		m = models[id]
		add!(m, MaintenanceDiet)
		for food in (PowderedPeanut, PowderedSuetPellet)
			remove!(m, MaintenanceDiet)
			wait!(m, 2u"hr")
			add!(m, food, 20)
			wait!(m, 15u"minute")
			remove!(m, Any)
			add!(m, Peanut, 40)
			add!(m, SuetPellet, 40)
			tray = Tray(0, rand(1:100))
			add!(m, tray)
			wait!(m, 15u"minute")
			prefed = lowercase(string(food))
			for typ in (Peanut, SuetPellet)
                push!(results, [prefed, "eat", lowercase(string(typ)), id,
								40 - countfooditems(m, typ)])
                push!(results, [prefed, "cache", lowercase(string(typ)), id,
								countcache(tray, typ)])
			end
			remove!(m, Any)
			add!(m, MaintenanceDiet)
			wait!(m, 21.5u"hr")
		end
	end
    results
end

function getfraction_Cheke11_planning(data)
	groups = groupby(data, :foodtype)
	df = join(groups..., on = [:trial, :tray, :id])
	total = df.items .+ df.items_1
	df.fractionprefed = zeros(length(df.items))
	for (i, t) in enumerate(total)
		if t == 0
			df.fractionprefed[i] = NA
		else
			df.fractionprefed[i] = df.items_1[i] / t
		end
	end
	df
end
function _summarize(::Experiment{:Cheke11_planning}, data)
	combine(groupby(data, [:trial, :foodtype, :tray, :action]),
				df -> DataFrame(μ = mean(df.items),
                                sem = sem(float.(df.items)),
								n = length(df.items)))
end
function statistical_tests(exp::Experiment{:Cheke11_planning}, data)
    tests = Test[]
    push!(tests, Test("foodtype & tray",
                      splitplotanova(data,
                                     exp.tests["foodtype & tray"].locals,
                                     betweenfactors = [],
                                     withinfactors = [:tray, :foodtype],
                                     id = :id, data = :items),
                      exp.tests))
    for trial in 1:3
        id = "Tray × foodtype interaction in trial $trial"
        push!(tests, Test(id,
                          splitplotanova(@where(data, :trial .== trial),
                                         exp.tests[id].locals,
                                         betweenfactors = [],
                                         withinfactors = [:tray, :foodtype],
                                         id = :id, data = :items),
                          exp.tests))
    end
    id = "Tray × foodtype interaction in trial 3 without hunter"
    push!(tests, Test(id,
                      splitplotanova(@where(data, :trial .== 3, :id .!= 3),
                                     exp.tests[id].locals,
                                     betweenfactors = [],
                                     withinfactors = [:tray, :foodtype],
                                     id = :id, data = :items),
                      exp.tests))
    TestCollection(tests)
end
function run!(exp::Experiment{:Cheke11_planning}, models; N = 4)
    results = DataFrame(trial = Int[], tray = String[], action = String[],
                        foodtype = String[],
						id = Int[], items = Float64[])
	for id in 1:N
		m = models[id]
		add!(m, MaintenanceDiet)
		for trial in 1:3
			# stage 1
		    trays = [Tray(traypos) for traypos in 1:2]
			remove!(m, MaintenanceDiet)
			wait!(m, 1u"hr")
			if trial == 1
				add!(m, MaintenanceDiet)
			elseif id == 2
				add!(m, PowderedSuetPellet, 20)
			else
				add!(m, PowderedPeanut, 20)
			end
            samefirst = true
			if id <= 2 # Hoy and Wiggins
				samefirst = false
			end
			foodtypeorder = [Peanut, SuetPellet]
			if id == 2
				reverse!(foodtypeorder)
			end
			wait!(m, 15u"minute")
            remove!(m, Any)
			add!(m, Peanut, 40)
			add!(m, SuetPellet, 40)
			add!(m, trays)
			wait!(m, 15u"minute")
			remove!(m, Any)
			add!(m, MaintenanceDiet)
			for traypos in 1:2
				for foodid in 1:2
					push!(results, [trial,
                                    ((samefirst && traypos == 1) || (!samefirst && traypos == 2)) ? "same" : "different",
                                    "cache",
                                    foodid == 1 ? "prefed" : "nonprefed",
									id, countcache(trays[traypos],
													foodtypeorder[foodid])])
				end
			end
			wait!(m, 3u"hr")
			# stage 2 & 3
			for stage in 2:3
				remove!(m, MaintenanceDiet)
				wait!(m, 1u"hr")
				if id == 1 && stage == 2 || id != 1 && stage == 3
					add!(m, PowderedSuetPellet, 20)
				else
					add!(m, PowderedPeanut, 20)
				end
				wait!(m, 15u"minute")
                remove!(m, Any)
                # cover tray 2 in stage 2 and tray 1 in stage 3
				cover!(trays[stage == 2 ? 2 : 1])
				add!(m, trays)
                # retrieve from tray 1 in stage 2 and tray 2 in stage 3
				wait!(m, 15u"minute")
				remove!(m, Any)
				add!(m, MaintenanceDiet)
				uncover!(trays[stage == 2 ? 2 : 1])
				wait!(m, 22.5u"hr")
			end
            pilfer!.(trays)
			wait!(m, 19.5u"hr")
		end
	end
    results
end

