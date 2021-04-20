# FoodCachingExperiments

The code in this repository defines a domain specific language to describe food
caching experiments. This repository is a submodule of [FoodCaching](../FoodCaching).

* Examples of experimental protocols are in [src/protocols](src/protocols).
* Raw and processed experimental results with real food caching birds are in [data](data). 
* Run `julia scripts/process_experiments.jl` to regenerate the processed results from the raw experimental results.
* An example of a model that can be simulated on these protocols is in
    [examples/dummy_model.jl](examples/dummy_model.jl). For more examples see
    [FoodCachingModels](../FoodCachingModels).
