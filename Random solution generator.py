#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import random as rndm
import math
import numpy

def create_data_array(problemnumber):

    foldername = "20 city problemdata"
    datafilename = "/home/david/data/"+foldername+"/problem " + str(problemnumber)+".txt"
    print( datafilename)
    data = open(datafilename)
    nextline = data.readline()
    locations = [[]]
    while nextline != "":
        parts = nextline.strip()
        parts = parts.split(" ")
        parts = list(map(int, parts))
        thiscity = parts[:2]
        if locations == [[]]:
            locations = [thiscity]
        else:
            locations.append(thiscity) 
        nextline = data.readline()    
    return locations

def main(maxruns,capacity = 9,plasmodia = 3,mincap = 2): #all integers
    for problemnumber in range(1,21):
        coordinates = create_data_array(problemnumber)
        #destlist = [0,1,2,3,4,5,6,7,8,9]
        destlist = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]
        citynumber = len(destlist)
        runs = 0
        tourlist = []
        #mincap = round(citynumber / plasmodia)
        while runs < maxruns:
            runs += 1
            rndm.shuffle(destlist)
            tourcounter = 0
            totallength = 0
            while True:
                tours = [0]
                pivot1 = rndm.randint(mincap,capacity) #randomly pick a valid capacity
                tours.append(destlist[0:pivot1])
                for i in range(1,plasmodia):
                    if ((citynumber - pivot1) <= capacity):
                        tours.append(destlist[pivot1:citynumber])
                        pivot1 = citynumber
                        break
                    newpivot = rndm.randint(mincap,capacity) #randomly pick a valid capacity
                    newtot = pivot1 + newpivot
                    tours.append(destlist[pivot1:newtot])
                    pivot1 = newtot
                if pivot1 == citynumber:
                    break
            if len(tours) < plasmodia + 1:
                tours.append([])
            tourcounter= 0
            while tourcounter < plasmodia:
                tourcounter += 1
                print(tourcounter)
                tour = tours[tourcounter]
                print(tour)
                tourlength = 0
                locationx = 69
                locationy = 69
                tourstops = len(tour)
                counter = 0
                while counter < tourstops:
                    thisx = coordinates[tour[counter]][0] #The x-coordinate of the relevant delivery of the tour
                    thisy = coordinates[tour[counter]][1]
                    xlength = max(locationx, thisx) - min(locationx, thisx)
                    ylength = max(locationy, thisy) - min(locationy, thisy)
                    tourlength += math.hypot(xlength,ylength)
                    locationx = thisx
                    locationy = thisy
                    counter += 1
                    print(tourlength)
                xlength = max(locationx, 69) - min(locationx, 69)
                ylength = max(locationy, 69) - min(locationy, 69)
                tourlength += math.hypot(xlength, ylength)
                print(tourlength)
                totallength += tourlength
                #print(tourlength)
        
                
            tourlist.append(totallength)
            #print(totallength)
            totallength = str(totallength)
            #f.write(totallength)
            #f.write('\n')
        f = open('20city'+ str(plasmodia) + 'plasmodium' + str(capacity) + 'cap problem' +  str(problemnumber) + 'randomsolutions','w')
        for i in range(len(tourlist)):
            output = tourlist[i]
            f.write(str(output)+"\n")
        f.close()
        print(numpy.mean(tourlist))
        print(min(tourlist))