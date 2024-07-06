## SynCOM IDL Procedures

Welcome to the SynCOM IDL procedures repository! This set of procedures allows users to generate high-resolution simulations of transient solar wind flows. Below, you'll find an explanation of the key functions and how to use them.

### 1. `syncomprams`

The `syncomprams` procedure initializes the parameters required to build the SynCOM image.

**Usage:**
```idl
syncomprams, ModPramsStruct, SYNCOM_N_BLOBS=5000
```
Parameters:

ModPramsStruct: A structure containing the basic inputs for building the SynCOM image.

SYNCOM_N_BLOBS: Specifies the minimum number of blobs in the image. Default is 1000.


### 2. `SYNCOM_LOAD`
The SYNCOM_LOAD procedure constructs arrays based on ModPramsStruct to initialize and accelerate the image processing.

**Usage:**
```idl
SYNCOM_LOAD, ModPramsStruct, LoadStruc
```
Parameters:

ModPramsStruct: The structure with input parameters for the SynCOM image.

LoadStruc: A structure used to store arrays that facilitate faster image processing.


### 3. `SYNCOM`
The SYNCOM procedure generates synthetic image sets using the parameters and structures defined previously.

**Usage:**
```idl
SYNCOM, ModPramsStruct, LoadStruc, syncom_data, "test_simple", 100., 0., 2.
```
Parameters:

ModPramsStruct: The structure with input parameters for the SynCOM image.

LoadStruc: The structure containing preloaded arrays for faster processing.

syncom_data: The output array that will hold the synthetic image sets.

"test_simple": A string to be used as a prefix in the file names of the generated images.

100.: The final time for the image sequence.

0.: The initial time for the image sequence.

2.: A scale factor for enlarging blobs and smoothing the background. The standard value is 1.

**Example Workflow:**
Here's a complete example of how to use these procedures together:

#### 1. Initialize parameters
```idl
syncomprams, ModPramsStruct, SYNCOM_N_BLOBS=5000
```
#### 2. Load structures for faster processing
```idl
SYNCOM_LOAD, ModPramsStruct, LoadStruc
```
#### 3. Generate synthetic images
```idl
SYNCOM, ModPramsStruct, LoadStruc, syncom_data, "test_simple", 100., 0., 2.
```
This sequence will generate a set of synthetic images with the specified parameters and save them with the prefix "test_simple".

## Contact
For any questions or further assistance, please feel free to open an issue or contact us directly.
