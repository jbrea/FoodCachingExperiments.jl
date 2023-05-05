from juliacall import Main as jl
from random import randrange

jl.seval('using FoodCachingExperiments')

class Jay:
    items = []
    trays = []
    observers = []
    md = True
    def add_fooditem(self, item):
        self.items.append(item)
    def remove_fooditem(self, item):
        self.items.remove(item)
    def remove_food(self, kind):
        for item in self.items:
            if item.id == kind:
                self.items.remove(item)
    def add_tray(self, tray):
        self.trays.append(tray)
    def remove_tray(self, tray):
        self.trays.remove(tray)
    def add_inspection_observer(self, o):
        self.observers.append(o)
    def remove_inspection_observer(self, o):
        self.observers.remove(o)
    def add_maintenance_diet(self):
        self.md = True
    def remove_maintenance_diet(self):
        self.md = False
    def remove_anything(self):
        self.items.clear()
        self.trays.clear()
        self.observers.clear()
    def countfooditems(self, kind):
        n = 0
        for item in self.items:
            if item.id == kind and item.eatable:
                n += item.n
        for tray in self.trays:
            for item in tray.eatableitems:
                if item.id == kind:
                    n += item.n
        return n
    def wait(self, delta):
        print("waiting " + str(delta))
        # do something e.g.
        for item in self.items:
            item.n -= randrange(3) # eat food items

js = [Jay() for _ in range(jl.nbirds("Cheke11_specsat"))]
result = jl.FoodCachingExperiments.run("Cheke11_specsat", js)

jl.summarize("Cheke11_specsat", result)

jl.statistical_tests("Cheke11_specsat", result)

jl.target("Cheke11_specsat")
