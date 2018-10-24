import random as rndm
import math

maxcities = 20
margin = 25 #How far to stay from the edge
maxproblems = 20
problemnumber = 0
envirowidth = 138
mindistance = 10
while problemnumber < maxproblems:
    problemnumber +=1
    filename = "problem " + str(problemnumber) + ".txt"
    f = open(filename,'w')
    cities = []
    while len(cities) < maxcities:#This loop creates a single set of cities at appropriate distances
        locationOK = True
        coorx = rndm.randint(margin,envirowidth - margin) #No x lower than margin, to ensure it fits well within the environment
        coory = rndm.randint(margin,envirowidth - margin)
        if cities:
            for city in cities:
                xlength = max(city[0], coorx ) - min(city[0], coorx )
                ylength = max(city[1], coory) - min(city[1], coory)
                distance = math.hypot(xlength,ylength)
                #print(distance)
                if distance < mindistance:
                    locationOK = False
                    break
        else:
            locationOK = True #The first city can never be rejected
        if locationOK: #If location was rejected, the loop will return to the start and generate a new coordinate
            thiscity = [coorx,coory]
            cities.append(thiscity)
            f.write(str(thiscity[0]))
            f.write(" ")
            f.write(str(thiscity[1]))
            f.write('\n')
    print("problem " + str(problemnumber) + " done")
    print(cities)
    f.close()
print("done")