Below is the step by step instruction to reproduce the results as shown.

Step 1. Download Data (instructions are at the bottom in the %%Download data section)

Step 2. Type 'paths' (without quotes) in the command window to add all folder subpaths to current path

Step 3. To generate results for LPOCV with manually selected hyperparameters run 'CompMultiSVM2' in the command window
        To generate results for synthetically generated data run 'CompMultiSVM3' 
        To generate results for LPOCV with algorithmically selected hyperparameters, run 'CompMultiSVM4'

Step 3. Check the results

      The results including table of accuracy and AUC, and plots in the paper will be stored in 
      /yourpath/TensorStochasticMachineLearning/results/


%%========================
%% Downloading Data Sets
%%========================

ADNI
========================

Step 1. Get access to confidential ADNI data

      Visit the source website https://ida.loni.usc.edu/login.jsp?project=ADNI.

      Complete the data use agreement and submit your application.

      Once approved, you'll receive login credentials for the ADNI Image & Data Archive (IDA).

Step 2. Download plasma data

      In the "Search & Download" dropdown menu, select "Study Files".

      In the sidebar on the left, choose "Biospecimen" -> "Biospecimen Results".

      Find and download "Biomarkers Consortium Plasma Proteomics Project RBM Multiplex Data and Primer (Zip file)" 
      
      From the folder, extract "adni_plasma_qc_multiplex_11Nov2010.csv" and save to /yourfolder

Step 3. Download phenotype data

      Also in the "Search & Download" section, find "ADNIMERGE - Packages for R" and download "ADNIMERGE_0.0.1.tar.gz".

      run the following code in R:

        install.packages("Hmisc")
        install.packages("/your/path/to/ADNIMERGE_0.0.1.tar.gz", repos = NULL, type = "source")
        library(ADNIMERGE)
        data("adnimerge")
        m12 <- subset(adnimerge, VISCODE=='m12')
        bl <- subset(adnimerge, VISCODE=='bl')
        write.csv(m12, "/yourfolder/adni_phenotype_m12.csv", quote = F, row.names = F)
        write.csv(bl, "/yourfolder/adni_phenotype_bl.csv", quote = F, row.names = F)

Step 4. Generate the data
      
      Now we have original data ready for use:
        "/yourfolder/adni_plasma_qc_multiplex_11Nov2010.csv"
        "/yourfolder/adni_phenotype_m12.csv"

      Open /yourpath/TensorStochasticMachineLearning/source/Modules/PrepADNI.m, 
      and change file paths for plasma and phenotype to your data location. 
      Then run PrepADNI.m. The binary datasets will be stored in /source/ADNI_data
===========================================================================

CSF

Step 1. and Step 2 are the same as for ADNI data

Step 3. Download CSF data

      Choose 'select study' to be ADNI. In the "Search & Download" dropdown menu, select "Study Files".

      In the sidebar on the left, choose "Biospecimen" -> "Biospecimen Results".

      Find and download "CruchagaLab CSF SOMAscan7k Protein matrix postQC"
     
      Save the file "CruchagaLab_CSF_SOMAscan7k_Protein_matrix_postQC_20230620.csv"  to /yourfolder

Step 4. Generate the data
     
      Now we have original data ready for use:
        "/yourfolder/CruchagaLab_CSF_SOMAscan7k_Protein_matrix_postQC_20230620.csv"
        "/yourfolder/adni_phenotype_bl.csv"

      Open /yourpath/TensorStochasticMachineLearning/source/Modules/PrepCSF.m,
      and change file paths for plasma and phenotype to your data location.
      Then run PrepCSF.m. The binary datasets will be stored in /source/data/CSF_data
===================================
newAD 
====================================
GCM 

This data set is already included in the 'data' folder; in InitializeParameters.m you may therefore set parameters.data.path = ''
====================================
Remote Sensing

Refer to Deforest_Read_Me_Data-2.pdf
======================================




  



