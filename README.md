RISA
====

A Galaxy tool to import data from Metabolights database using Risa package.

To run the script `risa.R`, you will need to install the netCDF and some bioconductor packages.

First install netCDF. On macOS run:
```bash
brew tap homebrew/science
brew install netcdf
```

Then run R and install xcms, Risa and mtbls2 packages:
```R
source("http://bioconductor.org/biocLite.R")
biocLite(c('xcms', 'Risa', 'mtbls2'))
```
