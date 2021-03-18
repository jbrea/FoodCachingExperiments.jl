_ft(id, day) = isodd(id + day)
function run!(::Experiment{:Amodio20_exp1}, models)
    results = DataFrame(id = Int[], action = String[], foodtype = String[], A = Int[], B = Int[], C = Int[])
    for id in eachindex(models)
        m = models[id]
        trays = [Tray(i) for i in 1:3] # A, B, C
        for day in 1:9
            remove!(m, Any)
            wait!(m, 12u"hr")
            add!(m, trays[_abc(id, day)])
            if _ft(id, day)
                add!(m, PowderedKibble, 50)
            else
                add!(m, PowderedPeanut, 50)
            end
            wait!(m, 15u"minute")
            remove!(m, Any)
            add!(m, MaintenanceDiet)
            if day == 9
                wait!(m, 3u"hr")
                remove!(m, Any)
                add!(m, trays)
                add!(m, Kibble, 25)
                add!(m, Peanut, 25)
                wait!(m, 15u"minute")
                remove!(m, Any)
                push!(results, [id; "cache"; "peanut"; countcache.(trays, Peanut)])
                push!(results, [id; "cache"; "kibble"; countcache.(trays, Kibble)])
            else
                wait!(m, 3u"hr")
                remove!(m, Any)
                add!(m, trays)
                wait!(m, 15u"minute")
                add!(m, MaintenanceDiet)
                wait!(m, 8.5u"hr")
            end
        end
    end
    results
end

# 1. Rome 2. Quito 3. Lisbon 4. Caracas 5. Wellington 6. Washington
_nf(id, day) = isodd(id + day)
_abc(id, day) = (day + div(id - 1, 2) - 1) % 3 + 1
function run!(::Experiment{:Amodio20_exp2}, models)
    results = DataFrame(id = Int[], action = String[], A = Int[], B = Int[], C = Int[])
    for id in eachindex(models)
        m = models[id]
        trays = [Tray(i) for i in 1:3] # A, B, C
        for day in 1:9
            remove!(m, Any)
            wait!(m, 12u"hr")
            add!(m, trays[_abc(id, day)])
            if _nf(id, day)
                add!(m, PowderedKibble, 50)
            end
            wait!(m, 15u"minute")
            remove!(m, Any)
            add!(m, MaintenanceDiet)
            if day == 9
                wait!(m, 3u"hr")
                remove!(m, Any)
                add!(m, trays)
                add!(m, Kibble, 50)
                wait!(m, 15u"minute")
                remove!(m, Any)
                push!(results, [id; "cache"; countcache.(trays)])
            else
                wait!(m, 3u"hr")
                remove!(m, Any)
                add!(m, trays)
                wait!(m, 15u"minute")
                add!(m, MaintenanceDiet)
                wait!(m, 8.5u"hr")
            end
        end
    end
    results
end
