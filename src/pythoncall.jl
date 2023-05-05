run(name::String, models) = run!(Symbol(name), models)

add!(m::PythonCall.Py, f::FoodItem) = m.add_fooditem(f)
add!(m::PythonCall.Py, t::Tray) = m.add_tray(t)
add!(m::PythonCall.Py, o::InspectionObserver) = m.add_inspection_observer(o)
add!(m::PythonCall.Py, ::Type{MaintenanceDiet}) = m.add_maintenance_diet()

remove!(m::PythonCall.Py, f::FoodItem) = m.remove_fooditem(f)
remove!(m::PythonCall.Py, f::Food) = m.remove_food(f)
remove!(m::PythonCall.Py, t::Tray) = m.remove_tray(t)
remove!(m::InspectionObserver, o::InspectionObserver) = m.remove_inspection_observer(o)
remove!(m::PythonCall.Py, ::Type{MaintenanceDiet}) = m.remove_maintenance_diet()
remove!(m::PythonCall.Py, ::Type{Any}) = m.remove_anything()

countfooditems(m::PythonCall.Py, kind) = pyconvert(Int, m.countfooditems(kind))

wait!(m::PythonCall.Py, delta) = m.wait(delta)
