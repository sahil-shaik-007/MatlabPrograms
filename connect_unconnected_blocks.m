function connect_unconnected_blocks()
    % CONNECT_UNCONNECTED_BLOCKS - Connects unconnected blocks to ground or terminator blocks
    % This script finds all unconnected ports in a Simulink model and connects them
    % to either ground blocks (for input ports) or terminator blocks (for output ports)
    % Handles reference subsystems, variant subsystems, nested subsystems, and special blocks
    
    fprintf('=== Simulink Unconnected Block Connector ===\n\n');
    
    try
        % Get model file from user
        [filename, filepath] = uigetfile('*.slx;*.mdl', 'Select Simulink Model File');
        
        % Check if user cancelled file selection
        if isequal(filename, 0) || isequal(filepath, 0)
            fprintf('Error: No model file selected. Script terminated.\n');
            return;
        end
        
        % Construct full file path
        fullPath = fullfile(filepath, filename);
        [~, modelName, ~] = fileparts(filename);
        
        fprintf('Selected model: %s\n', filename);
        fprintf('Full path: %s\n\n', fullPath);
        
        % Load the model
        fprintf('Loading model: %s\n', modelName);
        load_system(modelName);
        
        % Initialize counters
        unconnectedInputs = 0;
        unconnectedOutputs = 0;
        connectionsMade = 0;
        processedSubsystems = {};
        
        % Process the main model and all subsystems recursively
        fprintf('Processing model and all subsystems...\n');
        fprintf('=====================================\n');
        
        [unconnectedInputs, unconnectedOutputs, connectionsMade] = processModelRecursively(modelName, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems);
        
        % Display results
        fprintf('\n=== RESULTS ===\n');
        fprintf('Unconnected input ports found: %d\n', unconnectedInputs);
        fprintf('Unconnected output ports found: %d\n', unconnectedOutputs);
        fprintf('Total connections made: %d\n', connectionsMade);
        
        if connectionsMade > 0
            fprintf('\nModel has been modified. Consider saving the model.\n');
            fprintf('Use: save_system(''%s'')\n', modelName);
        else
            fprintf('\nNo unconnected ports found. Model is already properly connected.\n');
        end
        
        % Save results to workspace variables
        assignin('base', 'unconnectedInputs', unconnectedInputs);
        assignin('base', 'unconnectedOutputs', unconnectedOutputs);
        assignin('base', 'connectionsMade', connectionsMade);
        fprintf('\nResults saved to workspace variables: unconnectedInputs, unconnectedOutputs, connectionsMade\n');
        
    catch ME
        fprintf('\nError occurred: %s\n', ME.message);
        fprintf('Error location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        
        % Clean up any loaded models
        try
            if exist('modelName', 'var')
                close_system(modelName, 0);
            end
        catch
            % Ignore cleanup errors
        end
    end
end

function [unconnectedInputs, unconnectedOutputs, connectionsMade] = processModelRecursively(modelPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems)
    % Recursively process a model and all its subsystems
    
    % Check if this subsystem has already been processed to avoid infinite loops
    if any(strcmp(processedSubsystems, modelPath))
        return;
    end
    
    % Add current model to processed list
    processedSubsystems{end+1} = modelPath;
    
    try
        fprintf('Processing: %s\n', modelPath);
        
        % Find all blocks in the current model/subsystem
        allBlocks = find_system(modelPath, 'Type', 'Block');
        
        fprintf('  Found %d blocks in: %s\n', length(allBlocks), modelPath);
        
        % Process each block
        for i = 1:length(allBlocks)
            blockPath = allBlocks{i};
            blockName = get_param(blockPath, 'Name');
            blockType = get_param(blockPath, 'BlockType');
            
            % Skip certain block types that do not need connections
            skipTypes = {'Scope', 'Display', 'ToWorkspace', 'ToFile', 'FromWorkspace', 'FromFile'};
            if any(strcmp(blockType, skipTypes))
                continue;
            end
            
            % Handle different types of subsystems
            if strcmp(blockType, 'SubSystem')
                % Check if it is a reference subsystem
                if strcmp(get_param(blockPath, 'Variant'), 'on')
                    fprintf('    Found variant subsystem: %s\n', blockName);
                    % Process variant subsystem
                    [unconnectedInputs, unconnectedOutputs, connectionsMade] = processVariantSubsystem(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems);
                elseif strcmp(get_param(blockPath, 'ReferenceBlock'), '')
                    % Regular subsystem - process recursively
                    fprintf('    Found regular subsystem: %s\n', blockName);
                    [unconnectedInputs, unconnectedOutputs, connectionsMade] = processModelRecursively(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems);
                else
                    % Reference subsystem
                    fprintf('    Found reference subsystem: %s\n', blockName);
                    [unconnectedInputs, unconnectedOutputs, connectionsMade] = processReferenceSubsystem(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems);
                end
            elseif strcmp(blockType, 'ModelReference')
                % Model reference block
                fprintf('    Found model reference: %s\n', blockName);
                [unconnectedInputs, unconnectedOutputs, connectionsMade] = processModelReference(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems);
            elseif strcmp(blockType, 'Inport')
                % Inport block - connect to terminator if unconnected
                fprintf('    Found Inport block: %s\n', blockName);
                [unconnectedInputs, unconnectedOutputs, connectionsMade] = processInportBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade);
            elseif strcmp(blockType, 'Outport')
                % Outport block - connect to ground if unconnected
                fprintf('    Found Outport block: %s\n', blockName);
                [unconnectedInputs, unconnectedOutputs, connectionsMade] = processOutportBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade);
            elseif strcmp(blockType, 'From')
                % From block - connect to terminator if unconnected
                fprintf('    Found From block: %s\n', blockName);
                [unconnectedInputs, unconnectedOutputs, connectionsMade] = processFromBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade);
            elseif strcmp(blockType, 'Goto')
                % Goto block - connect to ground if unconnected
                fprintf('    Found Goto block: %s\n', blockName);
                [unconnectedInputs, unconnectedOutputs, connectionsMade] = processGotoBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade);
            else
                % Regular block - check for unconnected ports
                [unconnectedInputs, unconnectedOutputs, connectionsMade] = processRegularBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade);
            end
        end
        
    catch ME
        fprintf('  Error processing %s: %s\n', modelPath, ME.message);
    end
end

function [unconnectedInputs, unconnectedOutputs, connectionsMade] = processInportBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade)
    % Process Inport blocks - connect to terminator if unconnected
    
    try
        % Check if Inport has any connections
        inputPorts = get_param(blockPath, 'PortHandles');
        if ~isempty(inputPorts.Outport)
            portHandle = inputPorts.Outport(1);
            lineHandle = get_param(portHandle, 'Line');
            
            if lineHandle == -1  % No line connected
                unconnectedOutputs = unconnectedOutputs + 1;
                fprintf('      Unconnected Inport found: %s\n', blockPath);
                
                % Connect to terminator block
                if connectToTerminator(blockPath, 1)
                    connectionsMade = connectionsMade + 1;
                    fprintf('        -> Connected to terminator block\n');
                else
                    fprintf('        -> Failed to connect to terminator block\n');
                end
            end
        end
        
    catch ME
        fprintf('      Error processing Inport block %s: %s\n', blockPath, ME.message);
    end
end

function [unconnectedInputs, unconnectedOutputs, connectionsMade] = processOutportBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade)
    % Process Outport blocks - connect to ground if unconnected
    
    try
        % Check if Outport has any connections
        inputPorts = get_param(blockPath, 'PortHandles');
        if ~isempty(inputPorts.Inport)
            portHandle = inputPorts.Inport(1);
            lineHandle = get_param(portHandle, 'Line');
            
            if lineHandle == -1  % No line connected
                unconnectedInputs = unconnectedInputs + 1;
                fprintf('      Unconnected Outport found: %s\n', blockPath);
                
                % Connect to ground block
                if connectToGround(blockPath, 1)
                    connectionsMade = connectionsMade + 1;
                    fprintf('        -> Connected to ground block\n');
                else
                    fprintf('        -> Failed to connect to ground block\n');
                end
            end
        end
        
    catch ME
        fprintf('      Error processing Outport block %s: %s\n', blockPath, ME.message);
    end
end

function [unconnectedInputs, unconnectedOutputs, connectionsMade] = processFromBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade)
    % Process From blocks - connect to terminator if unconnected
    
    try
        % Check if From block has any connections
        inputPorts = get_param(blockPath, 'PortHandles');
        if ~isempty(inputPorts.Outport)
            portHandle = inputPorts.Outport(1);
            lineHandle = get_param(portHandle, 'Line');
            
            if lineHandle == -1  % No line connected
                unconnectedOutputs = unconnectedOutputs + 1;
                fprintf('      Unconnected From block found: %s\n', blockPath);
                
                % Connect to terminator block
                if connectToTerminator(blockPath, 1)
                    connectionsMade = connectionsMade + 1;
                    fprintf('        -> Connected to terminator block\n');
                else
                    fprintf('        -> Failed to connect to terminator block\n');
                end
            end
        end
        
    catch ME
        fprintf('      Error processing From block %s: %s\n', blockPath, ME.message);
    end
end

function [unconnectedInputs, unconnectedOutputs, connectionsMade] = processGotoBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade)
    % Process Goto blocks - connect to ground if unconnected
    
    try
        % Check if Goto block has any connections
        inputPorts = get_param(blockPath, 'PortHandles');
        if ~isempty(inputPorts.Inport)
            portHandle = inputPorts.Inport(1);
            lineHandle = get_param(portHandle, 'Line');
            
            if lineHandle == -1  % No line connected
                unconnectedInputs = unconnectedInputs + 1;
                fprintf('      Unconnected Goto block found: %s\n', blockPath);
                
                % Connect to ground block
                if connectToGround(blockPath, 1)
                    connectionsMade = connectionsMade + 1;
                    fprintf('        -> Connected to ground block\n');
                else
                    fprintf('        -> Failed to connect to ground block\n');
                end
            end
        end
        
    catch ME
        fprintf('      Error processing Goto block %s: %s\n', blockPath, ME.message);
    end
end

function [unconnectedInputs, unconnectedOutputs, connectionsMade] = processVariantSubsystem(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems)
    % Process variant subsystem by activating each variant
    
    try
        % Get variant choices
        variantChoices = get_param(blockPath, 'VariantChoices');
        
        if ~isempty(variantChoices)
            fprintf('      Processing variant choices for: %s\n', get_param(blockPath, 'Name'));
            
            % Process each variant
            for i = 1:length(variantChoices)
                try
                    % Activate this variant
                    set_param(blockPath, 'Variant', variantChoices{i});
                    
                    % Process the activated variant
                    fprintf('        Activating variant: %s\n', variantChoices{i});
                    [unconnectedInputs, unconnectedOutputs, connectionsMade] = processModelRecursively(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems);
                    
                catch ME
                    fprintf('        Error processing variant %s: %s\n', variantChoices{i}, ME.message);
                end
            end
        else
            % No variant choices, process as regular subsystem
            [unconnectedInputs, unconnectedOutputs, connectionsMade] = processModelRecursively(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems);
        end
        
    catch ME
        fprintf('      Error processing variant subsystem: %s\n', ME.message);
    end
end

function [unconnectedInputs, unconnectedOutputs, connectionsMade] = processReferenceSubsystem(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems)
    % Process reference subsystem
    
    try
        % Get the reference block path
        refBlock = get_param(blockPath, 'ReferenceBlock');
        
        if ~isempty(refBlock)
            fprintf('      Processing reference block: %s\n', refBlock);
            
            % Load the reference block if not already loaded
            [refPath, refName] = fileparts(refBlock);
            if ~bdIsLoaded(refName)
                try
                    load_system(refBlock);
                    fprintf('        Loaded reference block: %s\n', refName);
                catch ME
                    fprintf('        Could not load reference block %s: %s\n', refName, ME.message);
                    return;
                end
            end
            
            % Process the reference block recursively
            [unconnectedInputs, unconnectedOutputs, connectionsMade] = processModelRecursively(refName, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems);
        end
        
    catch ME
        fprintf('      Error processing reference subsystem: %s\n', ME.message);
    end
end

function [unconnectedInputs, unconnectedOutputs, connectionsMade] = processModelReference(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems)
    % Process model reference block
    
    try
        % Get the referenced model name
        refModelName = get_param(blockPath, 'ModelName');
        
        if ~isempty(refModelName) && ~strcmp(refModelName, 'ModelName')
            fprintf('      Processing referenced model: %s\n', refModelName);
            
            % Load the referenced model if not already loaded
            if ~bdIsLoaded(refModelName)
                try
                    load_system(refModelName);
                    fprintf('        Loaded referenced model: %s\n', refModelName);
                catch ME
                    fprintf('        Could not load referenced model %s: %s\n', refModelName, ME.message);
                    return;
                end
            end
            
            % Process the referenced model recursively
            [unconnectedInputs, unconnectedOutputs, connectionsMade] = processModelRecursively(refModelName, unconnectedInputs, unconnectedOutputs, connectionsMade, processedSubsystems);
        end
        
    catch ME
        fprintf('      Error processing model reference: %s\n', ME.message);
    end
end

function [unconnectedInputs, unconnectedOutputs, connectionsMade] = processRegularBlock(blockPath, unconnectedInputs, unconnectedOutputs, connectionsMade)
    % Process regular blocks for unconnected ports
    
    try
        % Check for unconnected input ports
        inputPorts = get_param(blockPath, 'PortHandles');
        if ~isempty(inputPorts.Inport)
            for j = 1:length(inputPorts.Inport)
                portHandle = inputPorts.Inport(j);
                lineHandle = get_param(portHandle, 'Line');
                
                if lineHandle == -1  % No line connected
                    unconnectedInputs = unconnectedInputs + 1;
                    fprintf('    Unconnected input port found: %s (port %d)\n', blockPath, j);
                    
                    % Connect to ground block
                    if connectToGround(blockPath, j)
                        connectionsMade = connectionsMade + 1;
                        fprintf('      -> Connected to ground block\n');
                    else
                        fprintf('      -> Failed to connect to ground block\n');
                    end
                end
            end
        end
        
        % Check for unconnected output ports
        if ~isempty(inputPorts.Outport)
            for j = 1:length(inputPorts.Outport)
                portHandle = inputPorts.Outport(j);
                lineHandle = get_param(portHandle, 'Line');
                
                if lineHandle == -1  % No line connected
                    unconnectedOutputs = unconnectedOutputs + 1;
                    fprintf('    Unconnected output port found: %s (port %d)\n', blockPath, j);
                    
                    % Connect to terminator block
                    if connectToTerminator(blockPath, j)
                        connectionsMade = connectionsMade + 1;
                        fprintf('      -> Connected to terminator block\n');
                    else
                        fprintf('      -> Failed to connect to terminator block\n');
                    end
                end
            end
        end
        
    catch ME
        fprintf('    Error processing block %s: %s\n', blockPath, ME.message);
    end
end

function success = connectToGround(blockPath, portNumber)
    % Connect an unconnected input port to a ground block
    
    success = false;
    
    try
        % Get block position
        blockPos = get_param(blockPath, 'Position');
        blockWidth = blockPos(3) - blockPos(1);
        blockHeight = blockPos(4) - blockPos(2);
        
        % Calculate ground block position (to the left of the block)
        groundX = blockPos(1) - 100;
        groundY = blockPos(2) + (portNumber - 1) * (blockHeight / max(1, get_param(blockPath, 'Ports')));
        
        % Create ground block name
        groundName = sprintf('%s_Ground_%d', get_param(blockPath, 'Name'), portNumber);
        
        % Add ground block
        groundPath = [get_param(blockPath, 'Parent') '/' groundName];
        add_block('built-in/Ground', groundPath);
        
        % Set ground block position
        set_param(groundPath, 'Position', [groundX-20, groundY-10, groundX+20, groundY+10]);
        
        % Connect ground to input port
        add_line(get_param(blockPath, 'Parent'), [groundName '/1'], [get_param(blockPath, 'Name') '/' num2str(portNumber)]);
        
        success = true;
        
    catch ME
        fprintf('        Error connecting to ground: %s\n', ME.message);
    end
end

function success = connectToTerminator(blockPath, portNumber)
    % Connect an unconnected output port to a terminator block
    
    success = false;
    
    try
        % Get block position
        blockPos = get_param(blockPath, 'Position');
        blockWidth = blockPos(3) - blockPos(1);
        blockHeight = blockPos(4) - blockPos(2);
        
        % Calculate terminator block position (to the right of the block)
        terminatorX = blockPos(3) + 100;
        terminatorY = blockPos(2) + (portNumber - 1) * (blockHeight / max(1, get_param(blockPath, 'Ports')));
        
        % Create terminator block name
        terminatorName = sprintf('%s_Terminator_%d', get_param(blockPath, 'Name'), portNumber);
        
        % Add terminator block
        terminatorPath = [get_param(blockPath, 'Parent') '/' terminatorName];
        add_block('built-in/Terminator', terminatorPath);
        
        % Set terminator block position
        set_param(terminatorPath, 'Position', [terminatorX-20, terminatorY-10, terminatorX+20, terminatorY+10]);
        
        % Connect output port to terminator
        add_line(get_param(blockPath, 'Parent'), [get_param(blockPath, 'Name') '/' num2str(portNumber)], [terminatorName '/1']);
        
        success = true;
        
    catch ME
        fprintf('        Error connecting to terminator: %s\n', ME.message);
    end
end
