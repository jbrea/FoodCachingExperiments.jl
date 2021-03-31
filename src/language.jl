# These are the objects encountered in the caching experiments
@enum Food begin
    Mealworm = 1
    Waxworm
    Peanut
    SuetPellet
    Pinenut
    Kibble
    Cricket
    Pineapple
    Salami
    Stone
end
struct MaintenanceDiet end
const N_FOODTYPE = length(instances(Food))
mutable struct FoodItem
    id::Food
    n::Int
    freshness::Float64
    eatable::Bool
    cacheable::Bool
end
function Base.:(==)(f1::FoodItem, f2::FoodItem)
    f1.id == f2.id &&
    f1.n == f2.n &&
    f1.freshness == f2.freshness &&
    f1.eatable == f2.eatable &&
    f1.cacheable == f2.cacheable
end
(id::Food)(n = 1, cacheable = true, eatable = id != Stone, freshness = 1.) = FoodItem(id, n, freshness, eatable, cacheable)
for foodtype in instances(Food)
    powderedform = Symbol(:Powdered, foodtype)
    @eval @__MODULE__() begin
        $powderedform(n = 1) = $foodtype(n, false)
    end
end
isnut(f) = f == Peanut || f == Pinenut
isnut(f::FoodItem) = isnut(f.id)
isworm(f) = f == Mealworm || f == Waxworm
isworm(f::FoodItem) = isworm(f.id)
ismeat(f) = isworm(f) || f == Salami || f == Cricket || f == SuetPellet || f == Kibble
ismeat(f::FoodItem) = ismeat(f.id)
isfruit(f) = f == Pineapple
isfruit(f::FoodItem) = isfruit(f.id)
foodindex(f) = Int(f)
foodindex(f::FoodItem) = foodindex(f.id)

mutable struct Tray
	appearance::Int
    position::Int
	closed::Bool
	eatableitems::Array{FoodItem, 1}
end
function Base.:(==)(x::Tray, y::Tray)
    x.appearance == y.appearance &&
    x.position == y.position &&
    x.closed == y.closed &&
    x.eatableitems == y.eatableitems
end

Tray(p = 0, a = rand(Int); closed = false) = Tray(a, p, closed, FoodItem[])
degrade!(tray::Tray) = degrade!(tray, 0)
function degrade!(tray::Tray, foodtype)
    for o in tray.eatableitems
        (foodtype == 0 || o.id == foodtype) && (o.freshness = 0.)
    end
end
pilfer!(tray::Tray) = empty!(tray.eatableitems)
function pilfer!(tray::Tray, foodtype)
    tray.eatableitems = filter(x -> x.id != foodtype, tray.eatableitems)
end
countcache(tray::Tray) = countcache(tray, Any)
countcache(tray::Tray, typ) = countfooditems(tray.eatableitems, typ)
function countfooditems(array, typ)
	n = 0
	for o in array
		if o.id == typ || typ == Any
			n += o.n
		end
	end
	n
end
countfooditems(tray::Tray, typ) = countfooditems(tray.eatableitems, typ)
add!(model, typ, n) = add!(model, typ(n))
add!(model, objects::AbstractVector) = add!.(Ref(model), objects)
add!(list::Vector{FoodItem}, typ, n) = add!(list, typ(n))
function add!(list::Vector{FoodItem}, new_item::FoodItem; only_push = false)
    for item in list
        if item.id == new_item.id &&
           item.freshness == new_item.freshness &&
           item.eatable == new_item.eatable &&
           item.cacheable == new_item.cacheable
            only_push || (item.n += new_item.n)
            return list
        end
    end
    push!(list, new_item)
end
add!(tray::Tray, typ, n) = add!(tray.eatableitems, typ, n)
cover!(tray::Tray) = tray.closed = true
uncover!(tray::Tray) = tray.closed = false

struct InspectionObserver
	trayappearances::Array{Int, 1}
end
InspectionObserver() = InspectionObserver(Tray[])
countinspections(o) = length(o.trayappearances)
function countinspections(o::InspectionObserver, tray::Tray, N = typemax(Int))
	n = 0
    for appearance in Iterators.take(o.trayappearances, N)
		if appearance == tray.appearance
			n += 1
		end
	end
	n
end
firstinspection(o, tray) = countinspections(o, tray, 1)
observe!(o, tray) = push!(o.trayappearances, tray.appearance)


# Models need to implement the following functions
function add! end
function remove! end
function wait! end
function countfooditems end
