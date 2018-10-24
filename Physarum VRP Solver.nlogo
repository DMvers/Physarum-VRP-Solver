globals [ratio0 ratio1 ratio2 ratio3 claimedcities particle-colours sensor-angles rotation-angles city-patches ants0 ants1 ants2 ants3  convex-hull cities0 cities1 cities2 cities3]
breed [ cities city ]
breed [ ants ant ]
patches-own [ food-base phero-0 phero-1 phero-2 phero-3 phero-4 phero-5 phero-6 phero-7 phero-8 phero-9 damp-factor in-city?  in-convex-hull?]
ants-own [ class steps-underway ]
cities-own [ classlist largestclass]

to setup ; Neccesary for "go" function to work
  clear-all
  set-default-shape ants "square"
  set-default-shape cities "square"
  ask patches
  [
    set food-base n-values nr-of-types [ 0 ]
    foreach n-values nr-of-types [ ? ] [ run (word "set phero-" ? " 0") ]
    set damp-factor ifelse-value (distancexy 69 69 < max-pxcor) [ 1 ] [ 1 / (distancexy 69 69) ^ 2  ];This always returns 1 in my implementations
  ]
  set particle-colours [red blue green pink orange yellow violet sky cyan brown]
  create-and-separate-cities
  create-convex-hull ;Makes a convex hull based on the city placement
  make-particles nr-of-particles ;place initial particles up to the maximum
  place-food
  reset-ticks
end

to ensure-particles [desired] ;Called both at setup and every tick
  let current count ants
  if current < minimum-particles [ make-particles minimum-particles - current stop ] ; If there are too few particles, make more. Usually only happens if min-ants-in-neighbourhood is low or 0
  if current > desired [ ask n-of (current - desired) ants [ die ] ] ;If there are too many, kill the excess
end

to make-particles [ n ] ; these new ants are created in the depot, ensuring connectivity of the depot with the other destinations if population were to become low
  create-ants n [
    set hidden? hideparticles ; new particles start hidden (can cause confusion if new particles are made while other are visible)
    run (word "place-particle-" particle-place-method); This can either place them all at the depot or in the convex hull.
    set class who mod nr-of-types
    set color item class particle-colours
    set size 1
  ]
end

to place-particle-center ; this will keep all the particles at the center initially
   setxy 69 69
end


to place-particle-depot ; this will keep all the particles at an area around the center initially, which is the depot
   setxy 69 69
   move-to one-of patches in-radius cityradius

end

to place-particle-convex ; use the previously generated convex hull to place particles
  move-to one-of convex-hull
end

to place-food ;Make the depot always a source of food for both types
    ask patch (69) (69)[
      ask patches in-radius max-pxcor [
        foreach n-values nr-of-types [ ? ] [
          set food-base replace-item ? food-base (item ? food-base + (intensity distance myself * citynumber))
        ]
      ]
    ]
end

to-report intensity [ d ] ; Within the radius of the food itself, report its normal strength, outside report a lower strength, as it has dropped of due to distance
  if d > food-radius [ report food-radius / (d ^ 2) * food-strength ]
  report food-strength
end

to go  ;called every tick
  set sensor-angles   n-list 3 sensor-angle   ; cache angles
  set rotation-angles n-list 3 rotation-angle ; ditto
  ensure-particles nr-of-particles ;kills or creates new particles if above maximum or minimum

  set ants0  count ants with [color = red]
  set ants1 count ants with [color = blue]
  set ants2 count ants with [color = green]
  set ants3 count ants with [color = yellow]
  let totalants ants0 + ants1 + ants2 + ants3

  ask patches [
    set food-base n-values nr-of-types [ 0 ]
  ]

  let counter 0
  while [ counter < nr-of-types]
  [
    run (word "set cities" counter " 0")
    set counter counter  + 1 ]

  ;Determine the dominant particle kind for each city
  ask cities [
    set hidden? hidecities
    let class0 0
    let class1 0
    let class2 0
    let class3 0

    ask ants in-radius cityradius [
      ;workaround, terribly inefficient and hard to expand, but it works
      ;Checks what class the each nearby ant is for every city, so that all can be compared.
      ifelse class = 0 [ set class0 class0 + 1] ; count how many ants of type 0 there are
      [ifelse class = 1 [ set class1 class1 + 1] ; count how many of type 1, etc.
        [ifelse class = 2 [ set class2 class2 + 1]
          [if class = 3 [ set class3 class3 + 1]
          ]
        ]
      ]
    ]

    set classlist (list class0 class1 class2 class3)
    let locallargest max classlist
    if locallargest > 0 [
      if locallargest >= city-claim-minimum [
        set largestclass arg-max classlist
        run (word "set cities"largestclass " cities"largestclass " + 1")
      ]
    ]


  ]

  let citieslist (list cities0 cities1 cities2 cities3) ; put all the totals in a list for easy access
  set claimedcities sum citieslist ;total number of claimed cities

  ;Remove and place relevant pheromones
  ask cities
  [
     ; Let all cities remove hormones around themselves
     ask patch-here[
        ask patches in-radius max-pxcor[
            foreach n-values nr-of-types [ ? ] [
              set food-base replace-item ? food-base (item ? food-base - intensity distance myself)  ]
        ]
      ]

    let largestpresence max classlist

    ifelse largestpresence < city-claim-minimum[
      ; If there is no dominant particle kind, place all kinds of attractant
       ask patch-here[
        ask patches in-radius max-pxcor[
            foreach n-values nr-of-types [ ? ] [
              set food-base replace-item ? food-base (item ? food-base + (2 * intensity distance myself))
              ;set food-base replace-item ? food-base (item ? food-base + intensity distance myself)
            ]
        ]
      ]
       set color white ;cities should be white if no ant type is dominant
    ]
    [ ;If there is a dominant particle kind, place the corresponding attractant
     let largestclassforpatch arg-max classlist ;has to be a different variable
     ask patch-here[
        ask patches in-radius max-pxcor[
          set food-base replace-item largestclassforpatch food-base (item largestclassforpatch food-base + (2 * intensity distance myself))
        ]
      ]
      set color item largestclass particle-colours
    ]

  ]

  place-food ;This places attractant for the depot

  ask patches [ update-patches ];This causes the new attractant to actually be applied


  ;Diffuse the attractant
  foreach n-values nr-of-types [ ? ] [
    run (word "diffuse phero-" ? " diffuserate")
  ]

  ;Set the ratio that limits particle growth for each kind of particle
  set ratio0 (1 - item 0 citieslist / capacity)
  set ratio1 (1 - item 1 citieslist / capacity)
  set ratio2 (1 - item 2 citieslist / capacity)
  set ratio3 (1 - item 3 citieslist / capacity)
  ask ants [ move ]
  tick

  ;The convex placing method must be halted manually
  if particle-place-method = "center" or  particle-place-method = "depot" [ if claimedcities = citynumber [stop]]
end

to move
  if probability-of-death > 0 [if random-float 1.0 < probability-of-death [ die ]] ; Small chance of dying each turn if enabled, but is 0 by default
  if random-float 1.0 < sensing-frequency [  check-may-live ] ; check if this particle should die due to overpopulation. Does not occur with default settings

  let pheromone-levels map [ pheromone-at ? ] sensor-angles
  left item (arg-max pheromone-levels) rotation-angles

  if not in-convex-hull? [ die ] ; Do not let particles stray from the region

  let antclass -1 ; By default, there is no reason a particle can't move somewhere: there are no ants of class -1, so it will never block anthing
  ask ants-on patch-ahead step-size[
    set antclass class ; note what class the ant in front of you is, if there is one
    ]
  if-else can-move? step-size and (class != antclass)[  ; If the ant in front of you is of your class, you can't move there
    fd step-size ; forward, then deposit pheromone
      run (word "set phero-" class " phero-" class " + " food-deposit)

    let reproduction  0.5

    if class = 3 [set reproduction ratio3]
    if class = 2 [set reproduction ratio2]
    if class = 1 [set reproduction ratio1]
    if class = 0 [set reproduction ratio0]

if random-float 1.0 < reproduction [  try-to-split ] ;try to reproduce with a certain chance, dependant in capacity and number of claimed cities
         ]
     [
    right random-float 360 ; choose a random new orientation
     ]
     set hidden? hideparticles


end


to-report pheromone-at [ angle ]
  let sensed-patch patch-left-and-ahead angle sensor-offset
  if sensed-patch = nobody [ report 0 ]
  report [ pheromone-mix ] of sensed-patch
end

to-report pheromone-mix ; This is altered to make the pheromone types not interact
  let my-class [ class ] of myself
   report run-result (word "phero-" my-class )
end

to update-patches
 foreach n-values nr-of-types [ ? ] [
    run (word "set phero-" ? " 0.95 * 0.95 * damp-factor * (item " ? " food-base + phero-" ? ")")
  ]
 update-visualization
end

to update-visualization
    let index arg-max n-values nr-of-types [ run-result (word "phero-" ?) ]
  ifelse which-to-visualize = "all"[
  set pcolor scale-color item index particle-colours run-result (word "phero-" index) 0 pheromone-ceiling]
  [set pcolor scale-color item which-to-visualize particle-colours run-result (word "phero-" which-to-visualize) 0 pheromone-ceiling

    ]
end

to monocolor
   let index arg-max n-values nr-of-types [ run-result (word "phero-" ?) ]
   ifelse which-to-visualize = "all"[
  set pcolor scale-color item index particle-colours run-result (word "phero-" index) 0 0]
  [set pcolor scale-color item which-to-visualize particle-colours run-result (word "phero-" which-to-visualize) 0 0

    ]
end


to-report arg-max [ l ]               ; l = [7 2 9 9 5]
  let indices n-values length l [ ? ] ;     [0 1 2 3 4]
  let maximum max l                   ; 9
  report one-of filter [ item ? l = maximum ] indices ; 2 of 3
end

to-report n-list [ n l ] ; n-list 5 45 = [-45 -22.5 0 22.5 45]
  report n-values n [ l * (2 * ? - (n - 1)) / (n - 1) ]
end

to check-may-live ; is called by some ants each tick, if local density is too high, die
  if count ants in-radius neighbourhood-size > max-ants-in-neighbourhood [ die ]
end


to create-and-separate-cities ; create cities, make sure they are 25 patches apart and not too close to the border
if how-to-place-cities = "Load File" [
      file-close-all
      file-open (word "problem " problemnumber ".txt")
      while [not file-at-end?]
      [let thisline file-read-line
        let spacepos position " " thisline
        let linelength length thisline
        let coord1 substring thisline 0 spacepos
        let coord2startpos spacepos + 1
        let coord2 substring thisline coord2startpos linelength
        set coord1 read-from-string coord1
        set coord2 read-from-string coord2
        create-cities 1 [
        set shape "circle" set size 2
        set color white setxy coord1 coord2
        ]

        ]
      set citynumber count cities
  ]

  if how-to-place-cities = "randomly" [
      let busy? true
  create-cities citynumber [ set shape "circle" set size 2 ;city radius set to 1 for display purposes
   set color white]
  while [ busy? ] [
    set busy? false
    ask cities [
      move-to min-one-of patches [ distance myself ] display
      let too-close other cities in-radius 20
      if any? too-close [
        let x one-of too-close face x
        fd (0 - random-poisson 2) display
        set busy? true
      ]
      if abs(xcor) > max-pxcor - 6 - sensor-offset or abs(ycor) > max-pycor - 6 - sensor-offset  [
        facexy 0 0 rt random-float 15 fd random-poisson 2 display
        set busy? true
      ]
    ]
  ]
  ]
   if how-to-place-cities = "Setup A" ; Two parralel lines of three cities on opposing sides
   [
     set citynumber 6
     create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 30 0
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 30 5
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 30 -5
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy -30 5
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy -30 0
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy -30 -5
  ]
   ]

    if how-to-place-cities = "Setup B" ; Cities arranged in a large square around the depot
   [
     set citynumber 6
     create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 40 0
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 40 40
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 40 -40
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy -40 40
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy -40 0
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy -40 -40
  ]
   ]


    if how-to-place-cities = "Setup C" ; Two groups of three, on opposing sides of the depot
   [set citynumber 6
     create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 40 40
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 40 30
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 30 40
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy -30 -40
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy -40 -30
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy -40 -40
  ]
   ]


    if how-to-place-cities = "Setup D" ; A city set generated with the "random" setting
   [ set citynumber 10
     create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 43 93
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 82 69
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 62 57
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 64 81
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 69 104
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 92 102
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 82 48
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 61 36
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 45 72
  ]
  create-cities 1 [
    set shape "circle" set size 2
    set color white setxy 103 42
  ]
   ]

  ask patches [ set in-city? false ]
  ask patch (69) (69)[ set in-city? true]
  ask cities [ ask patches in-radius cityradius [ set in-city? true ] ]
  set city-patches patches with [ in-city? ]
  ask cities[
    ask patch-here[
      ask patches in-radius max-pxcor [
        foreach n-values nr-of-types [ ? ] [
              set food-base replace-item ? food-base (item ? food-base + intensity distance myself)
            ]
      ]
    ]
  ]
end

to try-to-split ; this is called by some of the ants each tick, if local density is low they divide
  let large-n patches in-radius neighbourhood-size
  if count ants-on large-n < min-ants-in-neighbourhood [
    let positiontogo one-of large-n with [ not any? ants-here ]
    if positiontogo  != nobody [ ; large-n is sometimes empty, not sure why
    hatch 1 [
      move-to positiontogo
    ]
    ]
  ]
end


to create-convex-hull ; Due to the larger default city radius, this convex hull is intentionally larger than in previous implementations, and is strictly speaking not the convex hull of the cites anymore
  ask patches [ set in-convex-hull? in-convex-hull ]
  set convex-hull patches with [ in-convex-hull? ]
end

to-report in-convex-hull ;Whether a certain patch is or is not in the convex hull
  if in-city? [ report true ]
  let degrees [ towards myself ] of city-patches
  let lower filter [ ? <= 180 ] degrees
  let upper filter [ ? >  180 ] degrees
  if not empty? lower and not empty? upper and (360 + max lower) - min upper < 180 [
    report false
  ]
  report max degrees - min degrees >= 180
end

to show-convex-hull ; show the convex hull for a tick
  if any? convex-hull with [ pcolor != green ] [
    ask convex-hull [ set pcolor green ]
  ]

end

to print-view ; used by the behavior space to export the view, so that a human can grade it
  export-view (word "results " problemnumber " image" which-to-visualize "run " run-number ".png")
end

to print-data ;creates a text file with city location and control, to be read by the tour reading software
  file-close-all
  file-open (word "results " problemnumber " data" which-to-visualize "run " run-number ".txt")
  ask cities[
    file-write xcor
    file-write ycor
    file-write largestclass
    file-print ""
  ]
  file-close

  let plotfilename (word "plot " problemnumber " data" which-to-visualize "run " run-number ".csv")
  export-plot "Number of ants by color" plotfilename

end

to update-turtles ;updates the hidecities and hideparticles settings without advancing the model
  ask cities [set hidden? hidecities]
  ask ants [set hidden? hideparticles]

end
@#$#@#$#@
GRAPHICS-WINDOW
240
10
806
597
-1
-1
4.0
1
10
1
1
1
0
0
0
1
0
138
0
138
1
1
1
ticks
30.0

BUTTON
80
10
235
43
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
80
45
235
78
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
810
40
1010
73
sensor-offset
sensor-offset
0
5
2.6
0.1
1
NIL
HORIZONTAL

SLIDER
810
75
1010
108
sensor-angle
sensor-angle
0
100
45
5
1
NIL
HORIZONTAL

SLIDER
810
145
1010
178
step-size
step-size
0
5
1
1
1
NIL
HORIZONTAL

SLIDER
65
180
237
213
nr-of-particles
nr-of-particles
0
20000
5000
100
1
NIL
HORIZONTAL

SLIDER
810
110
1010
143
rotation-angle
rotation-angle
0
100
45
5
1
NIL
HORIZONTAL

SLIDER
810
420
982
453
pheromone-ceiling
pheromone-ceiling
0.5
50
0.5
0.5
1
NIL
HORIZONTAL

SLIDER
810
275
982
308
food-radius
food-radius
0
50
2.5
0.5
1
NIL
HORIZONTAL

SLIDER
65
250
237
283
nr-of-types
nr-of-types
1
10
2
1
1
NIL
HORIZONTAL

TEXTBOX
815
260
975
301
City and depot settings
11
0.0
1

SLIDER
810
310
982
343
food-strength
food-strength
0
5.0
0.4
0.05
1
NIL
HORIZONTAL

CHOOSER
65
285
235
330
particle-place-method
particle-place-method
"center" "convex" "depot"
2

MONITOR
160
550
235
595
Total particles
count ants
17
1
11

SLIDER
1020
145
1195
178
probability-of-death
probability-of-death
0
0.001
0
0.0001
1
NIL
HORIZONTAL

SLIDER
810
365
982
398
diffuserate
diffuserate
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
1020
275
1192
308
city-claim-minimum
city-claim-minimum
1
1
1
1
1
NIL
HORIZONTAL

SLIDER
810
215
1015
248
max-ants-in-neighbourhood
max-ants-in-neighbourhood
0
5000
5000
5
1
NIL
HORIZONTAL

SLIDER
65
415
237
448
citynumber
citynumber
2
20
20
1
1
NIL
HORIZONTAL

CHOOSER
1020
420
1190
465
which-to-visualize
which-to-visualize
"all" 0 1 2 3 4 5 6 7 8 9
0

SLIDER
810
180
1012
213
min-ants-in-neighbourhood
min-ants-in-neighbourhood
0
200
75
5
1
NIL
HORIZONTAL

TEXTBOX
825
20
975
38
Particle settings
11
0.0
1

TEXTBOX
825
350
975
368
Pheromone settings
11
0.0
1

TEXTBOX
830
405
980
423
Visualization
11
0.0
1

TEXTBOX
1025
260
1175
278
City-specific settings
11
0.0
1

SLIDER
1020
310
1192
343
cityradius
cityradius
1
10
5
1
1
NIL
HORIZONTAL

SLIDER
65
215
237
248
minimum-particles
minimum-particles
0
5000
1000
50
1
NIL
HORIZONTAL

BUTTON
810
545
975
578
NIL
show-convex-hull
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
65
375
235
408
run-number
run-number
1
100
1
1
1
NIL
HORIZONTAL

BUTTON
810
465
1017
498
Update pheromone visualization
 ask patches [ update-visualization ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
50
620
570
1025
City control by color
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"unclaimed" 1.0 0 -7500403 true "" "plot count cities with [color = white]"
"red" 1.0 0 -2674135 true "" "plot count cities with [color = red]"
"blue" 1.0 0 -13345367 true "" "plot count cities with [color = blue]"
"green" 1.0 0 -10899396 true "" "plot count cities with [color = green]"
"yellow" 1.0 0 -1184463 true "" "plot count cities with [color = yellow]"
"orange" 1.0 0 -955883 true "" "plot count cities with [color = orange]"
"pink" 1.0 0 -2064490 true "" "plot count cities with [color = pink]"
"violet" 1.0 0 -8630108 true "" "plot count cities with [color = violet]"
"sky" 1.0 0 -13791810 true "" "plot count cities with [color = sky]"
"cyan" 1.0 0 -11221820 true "" "plot count cities with [color = cyan]"
"brown" 1.0 0 -6459832 true "" "plot count cities with [color = brown]"

PLOT
590
620
1150
1030
Number of ants by color
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Red" 1.0 0 -2674135 true "" "plot count ants with [color = red]"
"Blue" 1.0 0 -13345367 true "" "plot count ants with [color = blue]"
"Green" 1.0 0 -10899396 true "" "plot count ants with [color = green]"
"Total" 1.0 0 -7500403 true "" "plot count ants"
"Yellow" 1.0 0 -1184463 true "" "plot count ants with [color = yellow]"
"Orange" 1.0 0 -955883 true "" "plot count ants with [color = orange]"
"Pink" 1.0 0 -2064490 true "" "plot count ants with [color = pink]"
"Violet" 1.0 0 -8630108 true "" "plot count ants with [color = violet]"
"Sky" 1.0 0 -13791810 true "" "plot count ants with [color = sky]"
"Cyan" 1.0 0 -11221820 true "" "plot count ants with [color = cyan]"
"Brown" 1.0 0 -6459832 true "" "plot count ants with [color = brown]"

SLIDER
1020
110
1195
143
neighbourhood-size
neighbourhood-size
1
20
5
1
1
NIL
HORIZONTAL

CHOOSER
65
135
235
180
how-to-place-cities
how-to-place-cities
"Load File" "randomly" "Setup A" "Setup B" "Setup C" "Setup D"
0

SLIDER
1020
40
1195
73
food-deposit
food-deposit
0
5
1
0.1
1
NIL
HORIZONTAL

SLIDER
1020
75
1195
108
sensing-frequency
sensing-frequency
0
1
0.2
0.1
1
NIL
HORIZONTAL

BUTTON
55
525
152
558
export view
print-view
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1020
180
1195
213
capacity
capacity
0
20
14
1
1
NIL
HORIZONTAL

SWITCH
1020
505
1190
538
hideparticles
hideparticles
0
1
-1000

SWITCH
1020
470
1190
503
hidecities
hidecities
1
1
-1000

BUTTON
57
485
227
518
export city control and locations
print-data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
810
505
1017
538
Update particle and city visibility
update-turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
65
335
237
368
problemnumber
problemnumber
1
40
1
1
1
NIL
HORIZONTAL

BUTTON
80
80
235
113
One step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
65
120
200
138
Initialization
11
0.0
1

TEXTBOX
65
465
215
483
Export
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

A particle-based Physarum model to solve capacitated vehicle routing problems

## HOW IT WORKS

Based on the shrinking blob and diffusion and non-diffusion multi colony Physarum models of Gerard Vreeswijk. Various features have been combined and altered to create a shrinking blob for each type, each of which represents a truck.


There are many changes or additions in this model. Its functioning is described in the thesis.

Solutions are read as normal for solving the travelling salesman problem with a shrinking blob, with three differences:

1. Cities are not fully uncovered, but will have some ants around them, roughly to the distance of the city-radius variable. Cities are counted as being on the point on the outside of the blob closest to them.
2. The types are read separately, using the which-to-visualize variable the tours are determined with no reference to the other, using only the cities colored the same as the type. Because each of the cities is clearly claimed by one kind, this is consistent.
3. There is a central depot that is inserted in all tours as if it were a city.

##USAGE
Individual runs can be set manually, but data is more easily generated using the behaviorspace. By default, it can be set up to run all 20 problems present in the folder in a row, with 5 runs for each problem. This may take a while, more than an hour. Pheromone ceiling should be set to the lowest value for optimal results in processing. The output is generated automatically, and can be converted into VRP solutions by the tourreadered.py script.

To generate a single run, simply select setup and then go. The model halts automatically. Data can be exported with the relevant buttons.

## SETTINGS

###setup
Clears all previous particles and cities, places new cities and particles according to cities-number, nr-of-particles and particle-place-method. Cities are kept separate to ensure the final solution can be read.

###go
Runs the model. The order of events is as follows:
1. ants are made if there are less than the minimum, or die if there are more than the maximum (nr-of-particles)
2. the ants sense and then try to move, placing pheromone if successful, after which ants check if they should create a new ant due to underpopulation, depending on the reproduction frequency
3. city ownership is determined and pheromone is placed
4. pheromone is placed at the depot
5. pheromone is diffused (if relevant) and dampened

###One step
Execute the go method once, halt immediatly after one step

###how-to-place-cities
Whether a deterministic city setup should be used, cities should be placed randomly, or loaded from a file. A file titled "problem x" is expected, where x is the value of the problemnumber variable. The file should consist of two values on each line, the x and y coordinate, one set for each city.

###nr-of-particles
The number of particles to place initially, according to the particle-place-method. The actual number of particles will vary as are born in low-density areas according to min-ants-in-neighbourhood. This value is used as a maximum, if there are more ants than this number, they will die until they are once more below it.

###minimum-particles
Should the total number of ants go below this number, new ants will be created in the depot

###nr-of-types
This allows for a choice of how many types of ants should exist.

###particle-place-method
Particles can either all start at the center, within the  depot area, or be spread around the convex hull. The depot place method is used in the thesis.

###problemnumber
Used to determine what problem to import, and what to name exported files

###run-number
Used internally to keep track of the current run. Also used in naming exported files.

###citynumber
The number of cities to generate in the setup. Automatically set tot the right value when loading a file or default placement method.

###export city control and locations
Exports a text file with the current cities locations and claiming status, used by the tourreader script to determine the tour.

###export view
Exports the current view

###sensor-offset
How far away the offset of each sensor is, default of 2.6

###sensor-angle
What the angle between sensors is, 45 degrees by default

###rotation-angle
How far each ant rotates when it does so, 40 degrees by default. Having this value lower than the sensor angle allow ants to generally stay within their existing pheromone blob/lane.

###step-size
How far ants move when they do so, 1 by default

###min-ants-in-neighbourhood
How many ants must be in the neigbourhood for the ant to not produce a child. The child will be of the same kind as the parent. This will prevent holes from forming in the blobs, so that all cities remain connected to the depot.

###max-ants-in-neighbourhood
How many ants may be in the neighbourhood (a radius of defined by neighbourhood-size patches) before the ant dies. This includes ants of all kinds. This setting is important to separate the blobs, decreasing their overlap.

###food-deposit
How much food should be deposited when a particle succesfully moves

###sensing-frequency
In how many ticks, on average, each particle should sense to see if it should die or reproduce (according to max-ants=in-neighbourhood and min-ants-in-neighbourhood)

###neighbourhood-size
Defines the size of the neighboorhood used for death and reproduction

###probability-of-death
Each ant has a chance of dying each tick equal to this. 0 by default, as shrinkage is already done by killing ants in crowded regions.

###capacity
What the capacity of each particle kind is.

###food-radius
This affects the drop-off of pheromone from depots and cities, at a smaller radius drop-off is faster.

###food-strength
This affects how much pheromone is deposited at all cities and the depot, a higher strength means more pheromone.

###city-claim-minimum
How many ants are necessary for a city to be claimed. If both kinds have numbers lower than this, the city will act as if the kinds are present in equal numbers (i.e. both types of pheromone will be produced)

###cityradius
The radius a city commands, for purposes of generating the convex hull and counting ants. This must be somewhat large, to limit the effect of random fluctuations in the ant type ratio, and to allow ants to remain around the city.

###diffuserate
How much of the content of each patch should diffuse to the eight neighbouring patches (in ratio, not absolute numbers). 0.2 by default.

###pheromone-ceiling
The ceiling determines at what point a patch is visually saturated with pheromone, i.e. it is fully white. This can be raised or lowered as needed to better view the intricacies of the pheromone pattern. It has no influence on the model.

###which-to-visualize
Whether both or just one of the pheromone types should be visible. Particularly useful for creating a solution, as pheromone types are hard to distinguish at borders.

###Update pheromone visualization
This instantly updates the visualization, useful in conjunction with the which-to-visualize setting.

###hidecities
Cities are hidden if this is on.

###hideparticles
Particles are hidden if this is on.

###Update particle and city visualization
This instantly updates the visualization, useful in conjunction with the which-to-visualize setting

###show-convex-hull
Shows the extent of the convex hull, as used for placing particles inside and eliminating all particles that exit it. It is actually slightly larger than the convex hull around the visualized cities, because the actual cities (where the pheromone is placed) are larger, at least with the default city radius setting.


## CREDITS AND REFERENCES

Authored by David M. Versluis, as part of my master thesis, "Solving the vehicle routing problem with a multi-agent Physarum model"
Based on the shrinking blob and diffusion and diffusion-less multi-colony Physarum models of Gerard Vreeswijk.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
set hidecities true
set hideparticles true</setup>
    <go>go</go>
    <final>set which-to-visualize "all"
 ask patches [ update-visualization ]
print-view
set which-to-visualize 0
 ask patches [ update-visualization ]
print-view
set which-to-visualize 1
 ask patches [ update-visualization ]
print-view
set which-to-visualize 2
 ask patches [ update-visualization ]
print-view
set which-to-visualize 3
 ask patches [ update-visualization ]
print-view
set which-to-visualize 4
set hidecities false
update-turtles
 ask patches [ update-visualization ]
print-view
set hidecities true
print-data</final>
    <exitCondition>ticks &gt; 1000</exitCondition>
    <metric>count turtles</metric>
    <steppedValueSet variable="run-number" first="1" step="1" last="1"/>
    <steppedValueSet variable="problemnumber" first="1" step="1" last="1"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
