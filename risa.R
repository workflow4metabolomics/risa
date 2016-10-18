library(Risa)
library(xcms)

##############################################################################
## First Galaxy tool:
## Read an MTBLS study uploaded to Galaxy.
## Here I use the pre-packages mtbls2 available from
## https://bioconductor.org/packages/release/data/experiment/html/mtbls2.html

#isa <- readISAtab("path_to_unzipped_mtbls_archive_directory_in_galaxy")) 
isa <- readISAtab(find.package("mtbls2")) 

## A Metabolights study might have more than one assay
cbind(measurement=isa@assay.measurement.types,
      technology=isa@assay.technology.types,
      names=isa@assay.filenames)

## Altrernatively, directly extract only MS assays
getMSAssayFilenames(isa)

## So we might want to allow the user to select
## which of the assays to actually analyse

## Once one of the assays has been selected as "selectedAssay.filename"
## get the filenames and factors(=phenoData)

selectedAssay.filename <- "a_mtbl2_metabolite_profiling_mass_spectrometry.txt"

## A dataframe with one row per sample, and many informative columns:
assayDataFrame <- isa@assay.files[[selectedAssay.filename]]

## Of particular interest are these columns:

msfiles = assayDataFrame[[Risa:::isatab.syntax$raw.spectral.data.file]]
msfiles <- sapply(msfiles, function(f) system.file(f, package="mtbls2")) ## Add Full Path

sclass <- as.data.frame(isa["factors"][[1]])


## Now assemble the metadata from the ISA-Tab assay. 
## This is a mixture of dummy values and actual MTBLS2 metadata
sampleMetadata <-
    data.frame("Sample Name"= assayDataFrame[,"Sample Name"],
               sampleType = "sample",             # Fixed. Could also be blank/pool/sample
               injectionOrder = NA,               # Needed ? Part of ISA ? derive from mzML ?
               batch = "batch",                   # could be any factor/string identifying a batch
               subset = 0,                        # No idea what this means
               full = 0,                          # No idea what this means
               sampling = 0,                      # No idea what this means
               osmolality = 972,                  # No idea what this means
               age = 42,                          # Have an idea what that means :-)
               bmi = 25.96,                       # Have an idea what that means :-)
               gender = "M",                      # Have an idea what that means :-)
               stringsAsFactors=FALSE)

sampleMetadata <- cbind(sampleMetadata, sclass, 
               stringsAsFactors=FALSE)

## Prepare information for Galaxy:

write.table(sampleMetadata, file="sampleMetadata.tsv",
            quote=FALSE, row.names=FALSE, sep="\t")

##############################################################################
## Second Galaxy tool: 
## perform individual peak picking in the xcms tool,
## and the lapply() loop would be taken care of by Galaxy
## TODO: double check generated filenames are unique to avoid overwriting ?

dummy <- lapply(msfiles, FUN=function(f) {
    xs <- xcmsSet(f, method="centWave", prefilter=c(10,5000))
    saveRDS(xs, paste(basename(f), "rds", sep="."))
})

##############################################################################
## Third Galaxy tool: 
## Then we need a merge tool, that reads all the individually picked files
## and merges them into the same xcmsSet the previously existing xcmsSet tool did:

xss <- lapply (msfiles, FUN=function(f) readRDS(paste(basename(f), "rds", sep=".")))
xs2 <- do.call(xcms:::c.xcmsSet, xss)
phenoData(xs2) <- read.delim("sampleMetadata.tsv", sep="\t")
