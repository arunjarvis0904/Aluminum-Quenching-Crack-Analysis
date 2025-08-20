# Aluminum Quenching & Crack Analysis

## Overview
Research internship project at NIT Tiruchirappalli focused on thermal stress behavior of aerospace-grade Al 7075 alloy plates under quenching conditions.

## Tools & Methods
- COMSOL Multiphysics (Thermal stress & heat transfer simulations)
- MATLAB (Image processing for crack quantification)
- Experimental Quenching setup

## Work Done
- Simulated quenching to analyze heat transfer and stress distribution
- Studied hot crack morphology under cryogenic conditions
- Applied MATLAB image analysis for crack severity quantification
- Correlated simulation and experimental results

## How to work
12grid.m
This script divides an input image into a 12×12 grid, splitting it into smaller image patches.

12binary.m
This script converts each grid patch into a binary image (black and white) and then combines them back into a full binary representation of the image.

fd_analysis.m
This script performs fractal dimension (FD) analysis on the binary image to measure its complexity.

Other MATLAB files
Additional helper scripts/functions used for preprocessing and analysis.

## Outcome
Provided insights into quenching-induced cracks in aluminum alloys, improving understanding of failure mechanisms in aerospace materials.
