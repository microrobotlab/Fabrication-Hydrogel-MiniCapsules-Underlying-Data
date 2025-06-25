# _Fabrication of hydrogel mini-capsules as carrier systems_ &ndash; Underlying data

This repository contains the **Underlying data** of the brief report _"Fabrication of hydrogel mini-capsules as carrier systems"_ by Roberti _et al._ published in **Open Research Europe** (DOI of latest version: [10.12688/openreseurope.16723.2](https://doi.org/10.12688/openreseurope.16723.2)).


## Data description

`Underlying data`  
&emsp;&#9492;`images\`: set of images used for the data analysis reported in the paper  
&emsp;&emsp;&#9492;`...`  
&emsp;&#9492;`data\`: dimensions measurements acquired with the microscope software from the images  
&emsp;&emsp;&#9492;`microscopy_measurements.csv`  
&emsp;&#9492;`results\`: outputs from the data analysis  
&emsp;&emsp;&#9492;`...`  
&emsp;&#9492;`Functions_ThicknessAnalysis.jl`: collections of functions for the data analysis  
&emsp;&#9492;`Software_ThicknessAnalysis.jl`: main script for reproducing the data analysis  
&emsp;&#9492;`Manifest.toml` and `Project.toml`: computational environment files    


### Content of `images`

All images are acquired using a Hirox microscope (model: HRX-01) and saved as `.jpg` files.
Magnification, objective, camera settings and light conditions used are reported in the legend on the images.
Each image represents one bead.
The file names indicate the CaCl&#8322; concentration (mM) at which the bead has been prepared and the sample number.


### Content of `data`

The `microscopy_measurements.csv` file contains the dimensions measurements acquired from the images in `images` with the microscope software.

Description of column headers:
* `NAME`: sample/image name
* `CaCl2`: CaCl&#8322; concentration (mM)
* `h_mis`: measured shell thickness (&mu;m) &mdash; empty if microscopy measurement was not possible
* `RCore`: measured core radius (&mu;m)

### Computational analysis

The two files `Software_ThicknessAnalysis.jl` and `Functions_ThicknessAnalysis.jl` are the scripts used for analyzing the data described above.
The former script uses the functions defined in the latter.

The analysis is performed in the ![Julia](https://julialang.org/assets/infra/logo.svg =x50) language, [v1.10](https://julialang.org/install/).
Once the correct version of Julia is installed, the computational environment including all specific dependencies can be exactly reproduced thanks to the `Manifest.toml` and `Project.toml` files.

### Content of `results`

The folder contains a `.svg` or `.png` version of all figure panels shown in the article.
It also includes a histogram of the core radii (`RcoreHistogram.svg`) and the following `.csv` output files:

* `microscopy_measurements_results.csv`: this file contains individual sample data already present in `microscopy_measurements.csv` plus the following data columns:
  * `Ym`: linearized and normalized shell thickness $(h/R_c + 1)^3 - 1$ (see article's equation 3)
  * `h_CaCl2`: expected shell thickness (&mu;m) based on CaCl&#8322; concentration and fitted $\alpha$ (see equation 2)
  * `Rmean`: mean of **red** color channel of pixels in the central spot of the bead image (R, color levels: 0&ndash;1)
  * `Rbgmean`: mean of **red** color channel of pixels in the central spot of the bead image minus mean of **red** color channel of pixels in the background (R&minus;bg)
  * `RBmean`: mean of **red** minus **blue** color channels of pixels in the central spot of the bead image (R&minus;B)
  * `h_RB`: expected shell thickness (&mu;m) based on the difference between **red** and **blue** color channels of pixels in the central spot of the bead image (R&minus;B)
* `microscopy_measurements_means.csv`: this file contains output data aggregated by CaCl&#8322; concentration, organized by the following columns
  * `CaCl2`: CaCl&#8322; concentration (mM)
  * `RCore`: mean core radius for each CaCl&#8322; concentration
  * `PDI_RCore`: polydispersity index (calculated as variance/mean&sup2; of the core radii) for each CaCl&#8322; concentration
  * `h_CaCl2`: expected shell thickness (&mu;m) based on CaCl&#8322; concentration and fitted $\alpha$
  * `RMeans_mean`: mean (over all samples of a CaCl&#8322; concentration) of the means of **red** color channel of pixels in the central spot of the bead image (R)
  * `RMeans_std`: standard deviation (over all samples of a CaCl&#8322; concentration) of the means of **red** color channel of pixels in the central spot of the bead image (R)
  * `RbgMeans_mean`: mean (over all samples of a CaCl&#8322; concentration) of the means of **red** color channel of pixels in the central spot of the bead image minus mean of **red** color channel of pixels in the background (R&minus;bg)
  * `RbgMeans_std`: standard deviation (over all samples of a CaCl&#8322; concentration) of the means of **red** color channel of pixels in the central spot of the bead image minus mean of **red** color channel of pixels in the background (R&minus;bg)
  * `RBMeans_mean`: mean (over all samples of a CaCl&#8322; concentration) of the means of **red** minus **blue** color channels of pixels in the central spot of the bead image (R&minus;B)
  * `RBMeans_std`: standard deviation (over all samples of a CaCl&#8322; concentration) of the means of **red** minus **blue** color channels of pixels in the central spot of the bead image (R&minus;B)
  * `h_RB`: expected shell thickness (&mu;m) based on the difference between **red** and **blue** color channels of pixels in the central spot of the bead image (R&minus;B)