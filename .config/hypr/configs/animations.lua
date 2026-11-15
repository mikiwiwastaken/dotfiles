-- Curves
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })

-- Springs
hl.curve("snappy", { type = "spring", mass = 0.8, stiffness = 600, dampening = 38 })
hl.curve("pop", { type = "spring", mass = 0.8, stiffness = 500, dampening = 30 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default", style = "" })

hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "easeOutQuint", style = "" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "linear", style = "loop" })

hl.animation({ leaf = "windows", enabled = true, speed = 2.5, spring = "snappy", style = "" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, spring = "pop", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "quick", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.5, spring = "snappy", style = "" })

hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.2, bezier = "almostLinear", style = "" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.8, bezier = "quick", style = "" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 2, bezier = "easeOutQuint", style = "" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 2, bezier = "easeOutQuint", style = "" })

hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "easeOutQuint", style = "" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1.2, spring = "snappy", style = "popin 90%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.2, bezier = "quick", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.2, bezier = "almostLinear", style = "" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1, bezier = "almostLinear", style = "" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 2, spring = "snappy", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2, spring = "snappy", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2, spring = "snappy", style = "slide" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 4, bezier = "quick", style = "" })
