function run!(::Experiment{:Hypothetical}, models)
    results = DataFrame(id = Int[], action = String[], A = Int[], B = Int[])
    for id in eachindex(models)
        m = models[id]
        trays = [Tray(i) for i in 1:4] # C, D, A, B
        for day in 1:9
            cid = floor(Int, ((day-1)) % 2 + 1)
            add!(m, trays[cid]) # compartment to spend the day from 10am onwards
            add!(m, MaintenanceDiet)
            wait!(m, 6.75u"hr")
            remove!(m, Any)
            if day == 9
                add!(m, trays[3:4])
                add!(m, Kibble, 10) # test
                wait!(m, 15u"minute")
                remove!(m, Any)
                push!(results, [id; "cache"; countcache.(trays[3:4])])
                break # end of experiment
            else
                add!(m, trays[3:4])
                add!(m, PowderedKibble, 10)
                wait!(m, 15u"minute") # getting used to seeing them in the evening
                remove!(m, Any)
                add!(m, MaintenanceDiet)
                wait!(m, 3u"hr")
            end
            remove!(m, Any)
            wait!(m, 12u"hr") # morning
            add!(m, trays[cid == 1 ? 3 : 4]) # compartment to wake up hungry
            wait!(m, 1u"hr")
            remove!(m, Any)
            wait!(m, 1u"hr")
            add!(m, MaintenanceDiet)
        end
    end
    results
end
