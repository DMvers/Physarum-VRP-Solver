Complementary material for “Solving the vehicle routing problem with a multi-agent Physarum model”, D.M.Versluis

Contents:
Physarum VRP solver (.nlogo)
Tourreader program (.py)
VRP generator (.py)
Random solution generator (.py)
A modified version of a branch and bound algorithm implementation by Tomasz Wąsiński (.py)
A sample VRP problem (.txt)
The fourty VRP problems used for generating results in the thesis, divided into those with ten and those with twenty cities (.txt)
One sample run of the Physarum VRP solver on problem 1, which can be loaded into the Tour reader script (.png, .csv, and .txt)

The Physarum VRP solver includes its own manual, in the "info" tab. It can be started with its default settings by pressing setup and then go.

The tourreader and VRP generator programs can be run as scripts.

The random solution generator can be run from the "main" method. The script will need to be altered with the relevant folder name(s) for your local computer to load the problems

The Branch and Bound solver can be run from its folder through the terminal, using the command
	python3 -m CVRPSolver -ProblemInstance 10cit20.test -BnB
Replacing 10cit20 with the desired problem. Three are included.