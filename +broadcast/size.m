%[text] Uses MATLAB's built in broadcasting functionality to confirm that broadcasting is possible, and return the size of the output for the broadcasted arguments.
function [out_size, sizes] = size(A, opts)
    arguments(Repeating)
        A 
    end
    arguments
        opts.Validate (1, 1) logical = true;
        opts.StrictCompatiblity (1, 1) logical = true;
    end

    % Gather the size of each of the inputs
    % The n-th row is the size of the n-th input, all trailing dimensions needed to flatten are kept at 1
    sizes = element_size(A);

    % Return the size of output resultant of broadcasted operation from the inputs
    [isValid, out_size] = broadcast.isValidSize(sizes, opts.StrictCompatiblity);

    % Validate the input or normalize invalid results
    if(opts.Validate && ~isValid)
        % Throw error consistent with MATLAB broadcasting errors
        throwAsCaller(MException(message("MATLAB:sizeDimensionsMustMatch")));
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
