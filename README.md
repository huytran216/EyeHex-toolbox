# EyeHex-toolbox
By Huy Tran<sup>1</sup> and Ariane Ramaekers<sup>2</sup>  
1. Faculty of Medical and Heath Technology, Tampere University, Finland  
2. Flyteam, Laboratory of Nuclear Dynamics, UMR3664, Institut Curie, France  
Corresponding email: huy.tran@tuni.fi  

## Introduction
EyeHex is a MATLAB toolbox for ommatidia segmentation from 2D images of Drosophila eyes. The toolbox contains multiple Graphical User Interfaces allowing users to perform:
1. manual ommatidia segmentation (for generation of training data for the external machine learning module)  
1. automatic mapping ommatidia to a hexagonal grid, and   
1. manual verification/correction of auto-segmented ommatidia.    

The toolbox is to be used in combination with the machine learning module from WEKA-trainable segmentation plug-in [1] (included in Fiji toolbox [2]) to preprocess input 2D images.

For a (slightly) more detailed guide, check `Manual/Readme.docx` file.


## Software requirements
MATLAB (tested with version 2016b or later)  
Fiji toolbox (download from https://fiji.sc/)  

## Sample data
To familiarize yourself with EyeHex, you can download/unzip or clone the sample data from: https://github.com/huytran216/EyeHex_sample_data.

The sample dataset contains two images. You can use one image to generate training data and apply trained classification to the other.

## Setup
It is recommended that you backup and create a new empty (e.g. `Sample_data/` as below) data folder for each dataset (e.g. new strains, or new developmental conditions). This allows EyeHex to manage both training, input and output data automatically and makes future analyses convenient. 

1. Create a subfolder `raw/` in the data folder and place all the input 2D images (e.g. `img*.tif`) in this folder.
1. If the images' multifocused stacks are available, create a subfolder `raw_stack/` and place the stack images in this folder. The index of the stack should be at the end of stack images' filenames  (e.g. `img1_001.tif`)
1. Download/Unzip or clone this EyeHex repository to a separate folder.

![alt text](https://github.com/huytran216/EyeHex-toolbox/blob/main/Manual/Img/Path.png?raw=true)
*Examples of the data/ folder structure, with two raw images. 

## Preparing training data
This step will help users generate training data for the machine learning module. It needs to be done once whenever a new type of image (from e.g. electron microscope, brightfield microscope…) or a drastic change in microscopy settings is introduced.

In EyeHex folder, browse to `Script/` folder via MATLAB and run the script `MAIN_manual_segmentation.m` (press <kbd>F5</kbd>) to run the manual segmentation GUI. A diaplog prompting for the path to the raw input 2D image (e.g. `sample_data/raw/img1.tif` for the sample dataset) will appear.

On the GUI, with mouse and keyboard, you can add ommatidia patches (press <kbd>A</kbd>), remove ommatidia patches (press <kbd>R</kbd>). Each patch is a group of at least 3 adjacent ommatida. Try to add patches both at the middle and near the edges of the eye to get the most inclusive training data. You can also define the eye region (press <kbd>I</kbd>) and the non-eye region (press <kbd>O</kbd>).

Finally, press <kbd>CTRL</kbd>+<kbd>E</kbd> to export the image labeling the ommatidia and their boundaries (by default to `training_raw/` and `training_label/` subfolders in the main data folder).

Press <kbd>F1</kbd> to check out all the hotkeys.

![alt text](https://github.com/huytran216/EyeHex-toolbox/blob/main/Manual/Img/Manual_segmentation.png?raw=true)  
*Manual segmentation for the training data. From a few manually labeled ommatidia (A), a hexagonal patch is spawned, with the ommatidia centers (red solid circles) and boundaries (black) visualized in panel B. A labeled image (C) is then exported, containing information on the ommatidia region (pixel value 0), the boundary regions (pixel value 1) and non-labeled region (pixel value 2). The example image (img1.tif) is taken from a brightfield microscope.*

## Automated preprocessing with machine learning
This step allows to generate the probability image of ommatidia region, in contrast to the boundary region, based on the trained classifier using the data from the previous step. Here, a macro for Fiji is provided to easily load the training data and apply the classifier to the all eye images.  
Start Fiji and run the macro TrainClassifier_gui.bsh in WekaMacro/ folder (by dragging the file to Fiji interface and press <kbd>F5</kbd>).  
A user interface will appear, prompting you to select the path to directories of the data folder.

The WEKA plug-in in Fiji will train the classifier with the training data (in `training_raw/` and `training_label/` subfolders of the data folder) and apply the classifier to all images in `raw/` subfolder. For each image, a tiff file containing the probability map of the ommatidia region is created and saved to `probability_map/` subfolder.

![alt text](https://github.com/huytran216/EyeHex-toolbox/blob/main/Manual/Img/MachineLearning.png?raw=true)
*Automated preprocessing with WEKA-Fiji tool: The trained classifier will convert the raw image (A) to the ommatidia probability map (B) and eye probability map (C).*

## Hexagonal grid expansion
This step generates a hexagonal grid of ommatidia from the learned ommatidia probability map. This grid is spawned from the first 3 user-prompted adjacent ommatidia, which forms the origin and the axes for the grid. This grid will attempt to expand from this origin to detect as much ommatidia as possible (up to 1200).  

In EyeHex folder, browse to `Script/` folder via MATLAB and type `MAIN_hexagon_expand.m` in MATLAB command window. A diaplog prompting for the path to the raw input 2D images to be segmentented will appear. Selection of multiple images is possible.

For each image, the ommatidia probability map of the input image will be displayed. Click on the center of three adjacent ommatidia, preferably in the middle of the eye, then press <kbd>Enter</kbd>.
The program will spawn the hexagonal grid from these three ommatidia. The spawning process will be displayed in real time in the same figure panel and also saved into `tmp/` subfolder in the data folder.

![alt text](https://github.com/huytran216/EyeHex-toolbox/blob/main/Manual/Img/Hexagon_expansion.png?raw=true)
*Expansion of hexagonal grid from (A) three manually added adjacent ommatidia. The grid is then expanded automatically layer by layer of ommatidia (B-D) and eventually covers the whole eye.*

## Manual correction
As ommatidia at the eye’s edges are heavily tilted, it is difficult for the machine learning module to recognize them properly. Also, non-eye region is not defined, leading to over-spawning of ommatidia during the automatic hexagonal grid expansion. Therefore, a final manual correction is required.  

In EyeHex folder, browse to `Script/` folder via MATLAB and type `MAIN_manual_correction.m` in MATLAB command window to run the manual correction GUI. A diaplog prompting for the path to the raw input 2D image for correction (e.g. `sample_data/raw/img1.tif` for the sample dataset) will appear.

From this GUI, you can add (press <kbd>A</kbd>) or remove (press <kbd>R</kbd>) ommatidia. You will focus mostly on the edges of the eye where errors might appear. You can save and load the correction progress by pressing <kbd>CTRL</kbd> + <kbd>H</kbd> (to save progress) and <kbd>CTRL</kbd> + <kbd>L</kbd> (to load progress).  
Once done, press <kbd>CTRL</kbd> + <kbd>E</kbd> to export the full segmentation results. This includes *the image label*, containing the ommatidia masks to `output_label/` subfolder of the dataset. Also exported is a *csv file* to `output_csv/` subfolder with information about each ommatidium's index, the x and y position of its center and its coordinate on the hexagonal axes.

You can press <kbd>F1</kbd> to access all the hotkeys (zoom in/out, save/load progress).

![alt text](https://github.com/huytran216/EyeHex-toolbox/blob/main/Manual/Img/Manual_correction.png?raw=true)
*Manual correction after automatic ommatidia detection: (A,C) raw image overlaid with automatic ommatidia segmentation. (B-D) manually corrected ommatidia segmentation. Panel C-D is a zoom-in region of panel A-B. In (A-D), automatically detected ommatidia are shown as green circles, manually added ommatidia are shown as red circles and manually removed ommatidia are shown as red dots. The example image (img2.tif) is taken from a brightfield microscope.*

## Label alignment
As the hexagonal grid expansion is performed based on the probability map, rather than the raw image, there might be some small misalignments between the exported label image and the raw image. If you want to know the exact ommatidia position, to extract features from individual ommatidia or to create new training data, you can manually realign the label image to match the raw image.  
1. In the manual correction GUI, after the ommatidia has been manually segmented, press <kbd>CTRL</kbd> + <kbd>I</kbd> to enter the alignment interface.  
1. Select a few (~10) anchor points at the center and at the edges of the eye with hotkeys <kbd>A</kbd> (add) and <kbd>R</kbd> (remove).
1. Drag and drop the anchor points so that the boundary labels match with the boundary in the original image.
1. Press <kbd>Enter</kbd>. The program will automatically generate the aligned label image and overwrite the current one in `data/label/` folder. You will also have an option to export it as training data for the machine learning module (similar to the first manual segmentation process).

# License
See License.md  
Copyright (C) 2021 Huy Tran

## References
[1] Arganda-Carreras, I.; Kaynig, V. & Rueden, C. et al. (2017), "Trainable Weka Segmentation: a machine learning tool for microscopy pixel classification.", Bioinformatics (Oxford Univ Press) 33 (15).  
[2] Schindelin, J.; Arganda-Carreras, I. & Frise, E. et al. (2012), "Fiji: an open-source platform for biological-image analysis", Nature methods 9(7): 676-682.



