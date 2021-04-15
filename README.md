# EyeHex-toolbox
By Huy Tran and Ariane Ramaekers  
Flyteam, Laboratory of Nuclear Dynamics, UMR3664, Institut Curie  
Corresponding email: huy.tran@curie.fr  

## Introduction
FlyHex is a MATLAB toolbox for ommatidia segmentation from 2D images of Drosophila eyes. The toolbox contains multiple Graphical User Interfaces allowing users to (1) perform manual ommatidia segmentation (for generation of training data for the external machine learning module), (2) mapping ommatidia to hexagonal grid, and (3) manual verification/correction of auto-segmented ommatidia.  
The toolbox is to be used in combination with the machine learning module from WEKA-trainable segmentation plug-in [1] (included in Fiji toolbox [2]) to preprocess input 2D images.  

## Software requirements
MATLAB (tested with version 2016b or later)  
Fiji toolbox (download from https://fiji.sc/)  

## Installation
Download and extract zip file or clone from github.  
Place all the input images (e.g. `img*.tif`) of the fly eyes into `Script/data/original/` folder.

## Preparing training data
This step will help users generate training data for the machine learning module. It needs to done once whenever a new type of image (from e.g. electron microscope, brightfield microscope…) or a drastic change in microscopy settings is introduced.  

Browse to `Script/` folder via MATLAB and type `MAIN_manual_segmentation(input_file)` in MATLAB command window to run the manual segmentation GUI. The `input_file` is the full name of the input image (e.g. `'img1.tif'`) in string format.  
```matlab
    MAIN_manual_segmentation('img1.tif')
```
With the GUI, you can press `A` to add ommatidia patches, `R` to remove patches, `Ctrl+E` to export the ommatidia and boundaries labeled image to `Script/data/weka_label/` folder.  
Press `F1` to check out all the hotkeys.


## References



