# import functions to be extended
import FoodCachingExperiments: add!, remove!, wait!, countfooditems
# import some types and functions
import FoodCachingExperiments: Tray, Food, FoodItem, InspectionObserver, MaintenanceDiet, observe!

# Define a DummyModel that can keep track of available caching trays, food items
# and inspection observers that record the number of inspections a bird makes to
# a certain tray.
struct DummyModel
    trays::Vector{Tray}
    foodtypes::Vector{FoodItem}
    observers::Vector{InspectionObserver}
end
DummyModel() = DummyModel([], [], [])

# For the DummyModel, adding different objects appends them to the appropriate list.
add!(m::DummyModel, f::FoodItem) = push!(m.foodtypes, f)
add!(m::DummyModel, t::Tray) = push!(m.trays, t)
add!(m::DummyModel, o::InspectionObserver) = push!(m.observers, o)
add!(::DummyModel, ::Type{MaintenanceDiet}) = nothing

# For the DummyModel, removing objects pops them from the respective lists.
remove!(m::DummyModel, f::FoodItem) = removefromlist!(m.foodtypes, f)
remove!(m::DummyModel, f::Food) = removefromlist!(m.foodtypes, x -> x.id == f)
remove!(m::DummyModel, t::Tray) = removefromlist!(m.trays, t)
remove!(m::DummyModel, o::InspectionObserver) = removefromlist!(m.observers, o)
remove!(::DummyModel, ::Type{MaintenanceDiet}) = nothing
function remove!(m::DummyModel, ::Type{Any})
    for list in (:trays, :foodtypes, :observers)
        empty!(getproperty(m, list))
    end
end
# helper functions for removal
removefromlist!(list, obj) = removefromlist!(list, x -> x == obj)
removefromlist!(list, f::Function) = removefromlist!(list, findfirst(f, list))
removefromlist!(list, i::Int) = splice!(list, i)
removefromlist!(::Any, ::Nothing) = nothing

# Count all food items that are freely available and cached in trays.
function countfooditems(m::DummyModel, typ)
	n = countfooditems(m.foodtypes, typ)
	for tray in m.trays
		n += countfooditems(tray, typ)
	end
	n
end

# The DummyModel removes random numbers of items from the freely available ones
# and caches random numbers of items in the available caching trays. The
# difference between removed and cached items gets interpreted as eaten items.
# Also, when trays are available the DummyModel inspects randomly one of them.
function wait!(m::DummyModel, delta, extracondition = nothing)
    for foodtype in m.foodtypes
        n = rand(1:20) # number of items to remove
        if n > foodtype.n  # trying to remove more items than available
            n = foodtype.n
            removefromlist!(m.foodtypes, foodtype)
        else
            foodtype.n -= n # decrement the number of avaiable items
        end
        for tray in m.trays
            n == 0 && break
            n_cache = rand(1:n)
            add!(tray, foodtype.id, n_cache) # cache some items
            n -= n_cache
        end
    end
    for o in m.observers
        if length(m.trays) > 0
            observe!(m.observers[1], rand(m.trays))
        end
    end
end
