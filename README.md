<p align="center">
  <img src="https://raw.githubusercontent.com/jbrea/FoodCachingExperiments.jl/master/fig1.png" />
</p>

## Simulate Food Caching Experiments in Julia and Python

The code in this repository defines a domain specific language to describe food
caching experiments. This repository is a submodule of [FoodCaching](https://github.com/jbrea/FoodCaching).

* Examples of experimental protocols are in [src/protocols](src/protocols).
* Raw and processed experimental results with real food caching birds are in [data](data). 
* Run `julia scripts/process_experiments.jl` to regenerate the processed results from the raw experimental results.
* An example of a model that can be simulated on these protocols is in
    [examples/dummy_model.jl](examples/dummy_model.jl). For more examples see
    [FoodCachingModels](https://github.com/jbrea/FoodCachingModels.jl).
* See [examples/dummy_model.py](examples/dummy_model.py) for how to use this from python.

To run the code in this repository, download [julia](https://julialang.org/downloads/) (at least version 1.7) and activate and instantiate this project. This can be done in a julia REPL with the following lines of code:
```julia
using Pkg
# download code
Pkg.develop(url = "https://github.com/jbrea/FoodCachingExperiments.jl")
# activate project
cd(joinpath(Pkg.devdir(), "FoodCachingExperiments"))
Pkg.activate(".")
# install dependencies
Pkg.instantiate()

# run a script
include(joinpath("scripts", "process_experiments.jl"))

using FoodCachingExperiments
```

