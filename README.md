# svo-raycaster
A hardware raycaster written in Verilog

This is the verilog code and testbench I developed in my master thesis, [Efficient Ray Tracing of Sparse Voxel Octrees on an FPGA](http://brage.bibsys.no/xmlui/handle/11250/255856).

The raycaster modules should be relatively clean, but it's not very useful in it's current state. All it does is take in ray data (must be precalculated and put in memory), a pointer to an octree, trace every given ray trough that octree, and draw the resulting depth to an image in memory.

This project was embedded in an ORPSoCv2 system, and executed on a Digital Atlys FPGA. If you want to create a similar set up, you need to fetch [ORPSoCv2 from here](http://opencores.org/or1k/Main_Page).

## raycaster1

This is the latest version used in the thesis.

## raycaster2

This version was an attempt at calculating the ray parameters based on the view and projection matrix in hardware. This should have provided a dramatic speedup, since the final version of the raycaster was more or less limited by the bandwidth required to fetch ray parameter data. If I remember correctly, I did not manage to get this version to work properly.

## sim

This is the standalone testbench for the raycaster. It does not really depend on ORPSoCv2, but in its current state it may need to be fixed up a bit before it runs without it.

## orlink

A tool based around [FPGALink](https://github.com/makestuff/libfpgalink/wiki/FPGALink), which allowed me direct access to the wishbone bus on the FPGA from my test tools on my laptop. Very useful. But not clean enough that I felt it deserved its own github repository (yet).


