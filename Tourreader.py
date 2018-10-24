#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Author - David M. Versluis
# 15-3-2018
# Part of my master thesis, "Solving the vehicle routing problem with a multi-agent Physarum model"

import numpy as np
import matplotlib.pyplot as plt
import skimage
import skimage.io
import math
from skimage import measure

#Input consists of the output of the behavior space from the Netlogo program.
#For each solution a text file with city locations and control, and four images, one of each (potential) plasmodium
#The third and fourth image may be blank, if no cities are controlled by the third or fourth plasmodium

print("how many runs?")
runs = int(input(">"))
print("how many problems?")
problems = int(input(">"))
print("how much capacity?")
capacity = int(input(">"))
print("Output file name?")
filename= str(input(">"))
print("Show plots? Y/N")
userinput = str(input(">"))
if userinput == "Y" or userinput == "y":
    plotting = True
else:
    plotting = False
    
#These can be changed if a specific problem in the middle should be analyzed
startnumber = 1
startproblem = 1

outputfile = open(filename,'w')
for variablenumber in range(startproblem,problems + 1): #Run multiple result sets
    allresults = []
    failure = 0
    success = 0
    for runnumber in range(startnumber,runs + 1): #Run once for each run
        datafilename = "results "+str(variablenumber)+" data4run " + str(runnumber)+".txt"
        data = open(datafilename)
        broken = False
        citylists  = [[[278.07,278.07]] for i in range(4)] #initialize each blob with the depot
        
        #Load the text file with data
        nextline = data.readline()
        while nextline != "":
            parts = nextline.strip()
            parts = parts.split(" ")
            parts = list(map(int, parts))
            thiscity = parts[:2]
            
            #convert coordinate systems
            thiscity[0] = thiscity[0] * 4
            thiscity[1] = 556 - thiscity[1] * 4
            citylists [parts[2]].append(thiscity) #append the city to the correct part
            nextline = data.readline()
        
        #Determine failure
        for citylist in citylists:
            if len(citylist) > capacity + 1: #The depot does not count against the capacity
                failure += 1
                broken = True
                break 
            success += 1     
        
        #Do not analyze invalid solutions any further
        if broken:
            continue
        
        totallength = 0
        
        #analyse each image, i.e. tour, seperately
        for imagenumber in range(0,4):
            #Load the image
            cities = citylists[imagenumber]
            if len(cities) == 1: #If this tour only contains the depot, skip it: it's empty
                continue
            tourlength = 0
            imagefilename = "results "+str(variablenumber)+" image" + str(imagenumber) +"run " + str(runnumber)+".png"
            img = skimage.io.imread(imagefilename,as_grey=True)
            
            # Find contours at a constant value of 0.2 (i.e. quite roughly)
            contours = measure.find_contours(img, 0.2)
            
            #Contours is of length equal to the number of different contours
            longestcontour = max(contours,key=len)
            
          
            #Start plotting, if applicable, by making the contour
            if plotting:
                fig,ax = plt.subplots()
                ax.plot(longestcontour[:, 1], longestcontour[:, 0], linewidth=2,color = '#5B82FB') 
           
            #Calculate the closest point in the contour for each city
            order = []
            
            #Determine plotcolor
            if imagenumber == 0:
                thiscolor = 'r'
            if imagenumber == 1:
                thiscolor = 'b'
            if imagenumber == 2:
                thiscolor = 'g'
                
            #Determine closest point on the contour for each city, and derive tour from that
            for city in cities:      
                nearest = 10000
                indexnumber = 0
                for point in longestcontour:
                    distance = math.hypot(city[0]-point[1],city[1]-point[0])
                    if distance < nearest:
                        nearest = distance
                        closest = point
                        closestindex = indexnumber
                    indexnumber += 1
                order.append(closestindex)
                #Plot lines to contour
                if plotting:
                    plt.plot([city[0],closest[1]],[city[1],closest[0]], linewidth=1,color = '#5B82FB') 
            indexnumbers = range(len(cities))
            tour = [x for _,x in sorted(zip(order,indexnumbers))]
           
            #Calculate tour length and add to total
            coordinates = cities
            tourlength = 0
            locationx = coordinates[tour[0]][0]
            locationy = coordinates[tour[0]][1]
            tourstops = len(tour)
            counter = 1
            while counter < tourstops:
                thisx = coordinates[tour[counter]][0] 
                thisy = coordinates[tour[counter]][1]
                xlength = max(locationx, thisx) - min(locationx, thisx)
                ylength = max(locationy, thisy) - min(locationy, thisy)
                tourlength += math.hypot(xlength,ylength)
                #Plot this line
                if plotting:
                    plt.plot([locationx,thisx],[locationy,thisy],color=thiscolor) 
                locationx = thisx
                locationy = thisy
                counter += 1
            xlength = max(locationx, coordinates[tour[0]][0]) - min(locationx, coordinates[tour[0]][0])
            ylength = max(locationy, coordinates[tour[0]][1]) - min(locationy, coordinates[tour[0]][1])
            tourlength += math.hypot(xlength, ylength)
            totallength += tourlength
            
            #Plot final line and image
            if plotting:
                plt.plot([locationx,coordinates[tour[0]][0]],[locationy,coordinates[tour[0]][1]],color=thiscolor)
                ax.imshow(img, interpolation='nearest', cmap=plt.cm.gray)
                plt.show()

            plt.close()
            
        #Convert data for output
        outputfile.write(str(totallength/4)+",")
        allresults.append(totallength/4)
    #Output data both in console and file, for each problem
    print("for problem " + str(variablenumber))
    print("mean = " + str(np.mean(allresults)))
    print("max  = " + str(max(allresults)))
    print("min  = " + str(min(allresults)))
    outputfile.write("\n")
    print(str(failure) + " failures")
outputfile.close()