# Simulink Reference Model Finder

## Overview
This MATLAB script (ind_reference_models.m) recursively finds all reference models in a Simulink model hierarchy. It handles nested reference models and automatically loads missing models to prevent errors.

## Features
- **Recursive Search**: Finds reference models at all levels of the hierarchy
- **Automatic Model Loading**: Loads reference models if they're not already loaded
- **Error Handling**: Comprehensive error handling for various scenarios
- **User-Friendly Interface**: File selection dialog with clear progress reporting
- **Infinite Loop Prevention**: Tracks processed models to avoid circular references

## Usage

### Basic Usage
1. Open MATLAB
2. Navigate to the directory containing ind_reference_models.m
3. Run the script:
   `matlab
   find_reference_models()
   `
4. Select your Simulink model file (.slx or .mdl) when prompted
5. The script will automatically find and list all reference models

### Output
The script provides:
- Real-time progress updates during the search
- A numbered list of all found reference models
- Results saved to workspace variable eferenceModelsList

### Example Output
`
=== Simulink Reference Model Finder ===

Selected model: main_model.slx
Full path: C:\path\to\main_model.slx

Searching for reference models...
=====================================
Loading model: main_model
Found 2 Model Reference blocks in: main_model
  -> Reference model: sub_model_1
Loading model: sub_model_1
Found 1 Model Reference blocks in: sub_model_1
  -> Reference model: sub_model_2
Loading model: sub_model_2
Found 0 Model Reference blocks in: sub_model_2
  -> Reference model: sub_model_3
Loading model: sub_model_3
Found 0 Model Reference blocks in: sub_model_3

=== RESULTS ===
Total reference models found: 3

Reference models list:
---------------------
1. sub_model_1
2. sub_model_2
3. sub_model_3

Results saved to workspace variable: referenceModelsList
`

## Error Handling
The script handles various error scenarios:
- **No file selected**: Script terminates gracefully with error message
- **Missing reference models**: Attempts to automatically load missing models
- **Model loading errors**: Continues processing other models
- **Invalid model references**: Skips invalid references with warnings
- **Circular references**: Prevents infinite loops by tracking processed models

## Requirements
- MATLAB with Simulink
- Simulink models (.slx or .mdl files)

## Notes
- The script automatically loads models as needed
- Results are saved to the workspace variable eferenceModelsList
- All loaded models remain in memory after script completion
- The script works with both .slx and .mdl file formats
