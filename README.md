# Simulink Model Utilities

## Overview
This repository contains MATLAB scripts for working with Simulink models:

1. **find_reference_models.m** - Recursively finds all reference models in a Simulink model hierarchy
2. **connect_unconnected_blocks.m** - Connects unconnected blocks to ground or terminator blocks with comprehensive subsystem and special block support

## Scripts

### 1. Reference Model Finder (find_reference_models.m)

Recursively finds all reference models in a Simulink model hierarchy. It handles nested reference models and automatically loads missing models to prevent errors.

#### Features
- **Recursive Search**: Finds reference models at all levels of the hierarchy
- **Automatic Model Loading**: Loads reference models if they're not already loaded
- **Error Handling**: Comprehensive error handling for various scenarios
- **User-Friendly Interface**: File selection dialog with clear progress reporting
- **Infinite Loop Prevention**: Tracks processed models to avoid circular references

#### Usage
1. Open MATLAB
2. Navigate to the directory containing find_reference_models.m
3. Run the script:
   `matlab
   find_reference_models()
   `
4. Select your Simulink model file (.slx or .mdl) when prompted
5. The script will automatically find and list all reference models

### 2. Enhanced Unconnected Block Connector (connect_unconnected_blocks.m)

Connects unconnected blocks in a Simulink model to either ground blocks (for input ports) or terminator blocks (for output ports). This enhanced version handles all types of subsystems, nested structures, and special blocks comprehensively.

#### Features
- **Comprehensive Subsystem Support**: Handles regular, reference, variant, and model reference subsystems
- **Special Block Handling**: Properly handles Inport, Outport, From, and Goto blocks
- **Recursive Processing**: Processes deeply nested subsystem hierarchies
- **Variant Subsystem Support**: Activates and processes all variant choices
- **Reference Subsystem Handling**: Automatically loads and processes reference blocks
- **Model Reference Support**: Handles referenced models recursively
- **Automatic Detection**: Finds all unconnected input and output ports
- **Smart Connections**: Connects input ports to ground blocks and output ports to terminator blocks
- **Intelligent Positioning**: Places ground/terminator blocks in appropriate locations
- **Block Type Filtering**: Skips blocks that do not require connections (Scopes, Displays, etc.)
- **Infinite Loop Prevention**: Tracks processed subsystems to avoid circular references
- **Comprehensive Reporting**: Provides detailed statistics and progress tracking
- **Robust Error Handling**: Continues processing even if individual subsystems fail

#### Supported Block Types
- **Regular Subsystems**: Standard nested subsystems
- **Reference Subsystems**: Library blocks and reference subsystems
- **Variant Subsystems**: Subsystems with multiple variant choices
- **Model References**: Referenced models (.slx/.mdl files)
- **Inport Blocks**: Connects unconnected Inport blocks to terminator blocks
- **Outport Blocks**: Connects unconnected Outport blocks to ground blocks
- **From Blocks**: Connects unconnected From blocks to terminator blocks
- **Goto Blocks**: Connects unconnected Goto blocks to ground blocks
- **Regular Blocks**: Standard Simulink blocks with input/output ports
- **Nested Structures**: Subsystems within subsystems at any depth

#### Connection Logic
- **Input Ports** (including Goto blocks, Outport blocks): Connected to **Ground blocks**
- **Output Ports** (including Inport blocks, From blocks): Connected to **Terminator blocks**

#### Usage
1. Open MATLAB
2. Navigate to the directory containing connect_unconnected_blocks.m
3. Run the script:
   `matlab
   connect_unconnected_blocks()
   `
4. Select your Simulink model file (.slx or .mdl) when prompted
5. The script will automatically process all subsystems and connect unconnected ports

#### Example Output
`
=== Simulink Unconnected Block Connector ===

Selected model: complex_model.slx
Full path: C:\path\to\complex_model.slx

Loading model: complex_model
Processing model and all subsystems...
=====================================
Processing: complex_model
  Found 12 blocks in: complex_model
    Found regular subsystem: Controller_Subsystem
Processing: complex_model/Controller_Subsystem
  Found 8 blocks in: complex_model/Controller_Subsystem
    Found Inport block: Input_Signal
      Unconnected Inport found: complex_model/Controller_Subsystem/Input_Signal
        -> Connected to terminator block
    Found Outport block: Output_Signal
      Unconnected Outport found: complex_model/Controller_Subsystem/Output_Signal
        -> Connected to ground block
    Found From block: Data_From
      Unconnected From block found: complex_model/Controller_Subsystem/Data_From
        -> Connected to terminator block
    Found Goto block: Data_Goto
      Unconnected Goto block found: complex_model/Controller_Subsystem/Data_Goto
        -> Connected to ground block
    Found reference subsystem: PID_Controller
      Processing reference block: lib_controllers/PID_Controller
        Loaded reference block: PID_Controller
Processing: PID_Controller
  Found 5 blocks in: PID_Controller
    Found variant subsystem: Filter_Options
      Processing variant choices for: Filter_Options
        Activating variant: LowPass
Processing: PID_Controller/Filter_Options
  Found 3 blocks in: PID_Controller/Filter_Options
        Activating variant: HighPass
Processing: PID_Controller/Filter_Options
  Found 3 blocks in: PID_Controller/Filter_Options
    Found model reference: Sensor_Model
      Processing referenced model: Sensor_Model
        Loaded referenced model: Sensor_Model
Processing: Sensor_Model
  Found 6 blocks in: Sensor_Model
    Unconnected input port found: Sensor_Model/Gain (port 1)
      -> Connected to ground block
    Unconnected output port found: Sensor_Model/Sum (port 1)
      -> Connected to terminator block

=== RESULTS ===
Unconnected input ports found: 3
Unconnected output ports found: 3
Total connections made: 6

Model has been modified. Consider saving the model.
Use: save_system('complex_model')

Results saved to workspace variables: unconnectedInputs, unconnectedOutputs, connectionsMade
`

#### Advanced Capabilities
- **Deep Nesting**: Handles subsystems within subsystems at any depth
- **Mixed Types**: Processes models with multiple subsystem types
- **Special Block Support**: Properly handles Inport, Outport, From, and Goto blocks
- **Automatic Loading**: Loads missing reference blocks and models automatically
- **Variant Processing**: Processes all variant choices in variant subsystems
- **Circular Reference Prevention**: Avoids infinite loops in complex hierarchies
- **Error Recovery**: Continues processing even if individual components fail

## Requirements
- MATLAB with Simulink
- Simulink models (.slx or .mdl files)
- Simulink libraries (for reference subsystems)

## Notes
- Both scripts automatically load models as needed
- Results are saved to workspace variables for further analysis
- All loaded models remain in memory after script completion
- The scripts work with both .slx and .mdl file formats
- Always save your models after running the unconnected block connector as it modifies the model structure
- The enhanced connector handles complex model hierarchies including reference subsystems containing other reference subsystems
- Variant subsystems are processed by activating each variant choice individually
- Model references are automatically loaded and processed recursively
- Special blocks (Inport, Outport, From, Goto) are handled with appropriate connection logic

## Use Cases
- **Model Validation**: Ensure all ports are properly connected before simulation
- **Model Cleanup**: Automatically fix unconnected blocks in complex models
- **Reference Model Analysis**: Find all reference models in a project
- **Hierarchical Processing**: Handle deeply nested subsystem structures
- **Variant System Management**: Process all variants in variant subsystems
- **Library Integration**: Work with Simulink library blocks and reference subsystems
- **Signal Flow Management**: Handle unconnected From/Goto tag pairs
- **Interface Management**: Connect unconnected Inport/Outport blocks
