function find_reference_models()
    % FIND_REFERENCE_MODELS - Recursively finds all reference models in a Simulink model
    % This script takes a .slx model as input and creates a list of all reference models
    % including nested reference models.
    
    fprintf('=== Simulink Reference Model Finder ===\n\n');
    
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
        
        % Initialize list to store all reference models
        allReferenceModels = {};
        processedModels = {}; % To avoid infinite loops
        
        % Find all reference models recursively
        fprintf('Searching for reference models...\n');
        fprintf('=====================================\n');
        
        allReferenceModels = findReferenceModelsRecursive(modelName, allReferenceModels, processedModels);
        
        % Display results
        fprintf('\n=== RESULTS ===\n');
        fprintf('Total reference models found: %d\n\n', length(allReferenceModels));
        
        if ~isempty(allReferenceModels)
            fprintf('Reference models list:\n');
            fprintf('---------------------\n');
            for i = 1:length(allReferenceModels)
                fprintf('%d. %s\n', i, allReferenceModels{i});
            end
        else
            fprintf('No reference models found in the selected model.\n');
        end
        
        % Save results to workspace variable
        assignin('base', 'referenceModelsList', allReferenceModels);
        fprintf('\nResults saved to workspace variable: referenceModelsList\n');
        
    catch ME
        fprintf('\nError occurred: %s\n', ME.message);
        fprintf('Error location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        
        % Clean up any loaded models
        try
            close_system(modelName, 0);
        catch
            % Ignore cleanup errors
        end
    end
end

function referenceModels = findReferenceModelsRecursive(modelName, referenceModels, processedModels)
    % Recursively find reference models in a Simulink model
    
    % Check if model is already processed to avoid infinite loops
    if any(strcmp(processedModels, modelName))
        return;
    end
    
    % Add current model to processed list
    processedModels{end+1} = modelName;
    
    try
        % Load the model if not already loaded
        if ~bdIsLoaded(modelName)
            fprintf('Loading model: %s\n', modelName);
            load_system(modelName);
        end
        
        % Find all Model Reference blocks in the current model
        modelRefBlocks = find_system(modelName, 'BlockType', 'ModelReference');
        
        fprintf('Found %d Model Reference blocks in: %s\n', length(modelRefBlocks), modelName);
        
        % Process each Model Reference block
        for i = 1:length(modelRefBlocks)
            try
                % Get the referenced model name
                refModelName = get_param(modelRefBlocks{i}, 'ModelName');
                
                % Check if its a valid reference model
                if ~isempty(refModelName) && ~strcmp(refModelName, 'ModelName')
                    fprintf('  -> Reference model: %s\n', refModelName);
                    
                    % Add to list if not already present
                    if ~any(strcmp(referenceModels, refModelName))
                        referenceModels{end+1} = refModelName;
                    end
                    
                    % Recursively search in the reference model
                    referenceModels = findReferenceModelsRecursive(refModelName, referenceModels, processedModels);
                end
            catch ME
                fprintf('  Warning: Could not process block %s: %s\n', modelRefBlocks{i}, ME.message);
            end
        end
        
    catch ME
        fprintf('Error processing model %s: %s\n', modelName, ME.message);
        
        % Try to load reference models that might be missing
        try
            loadMissingReferenceModels(modelName);
        catch
            % Ignore loading errors
        end
    end
end

function loadMissingReferenceModels(modelName)
    % Attempt to load missing reference models
    
    try
        % Get all Model Reference blocks
        modelRefBlocks = find_system(modelName, 'BlockType', 'ModelReference');
        
        for i = 1:length(modelRefBlocks)
            try
                refModelName = get_param(modelRefBlocks{i}, 'ModelName');
                
                if ~isempty(refModelName) && ~strcmp(refModelName, 'ModelName')
                    % Try to find and load the model file
                    modelFile = which(refModelName);
                    
                    if isempty(modelFile)
                        % Try common extensions
                        extensions = {'.slx', '.mdl'};
                        for j = 1:length(extensions)
                            potentialFile = [refModelName extensions{j}];
                            if exist(potentialFile, 'file')
                                modelFile = potentialFile;
                                break;
                            end
                        end
                    end
                    
                    if ~isempty(modelFile) && ~bdIsLoaded(refModelName)
                        fprintf('Attempting to load missing model: %s from %s\n', refModelName, modelFile);
                        load_system(modelFile);
                    end
                end
            catch
                % Continue with next block if this one fails
            end
        end
    catch
        % Ignore errors in this helper function
    end
end
