## SynCOM IDL Procedures

Welcome to the SynCOM IDL procedures repository! This set of procedures allows users to generate high-resolution simulations of transient solar wind flows. Below, you'll find an explanation of the key functions and how to use them.

### 1. `syncomprams`

The `syncomprams` procedure initializes the parameters required to build the SynCOM image.

**Usage:**
```idl
syncomprams, ModPramsStruct, SYNCOM_N_BLOBS=5000

Parameters:

ModPramsStruct: A structure containing the basic inputs for building the SynCOM image.
SYNCOM_N_BLOBS (optional): Specifies the minimum number of blobs in the image. Default is 5000.
