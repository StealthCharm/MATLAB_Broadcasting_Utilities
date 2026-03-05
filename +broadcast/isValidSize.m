%[text] This function takes in a row-wise matrix of argument sizes and returns a logical indicating whether the sizes are compatible for broadcasting.
function [valid, sz] = isValidSize(sizes, strict)
    arguments
        sizes double {mustBeInteger, mustBeNonnegative};
        strict (1, 1) logical = true;
    end

    % This manipulation acts to zero-ize elements that are length 1
    % mask those values and multiple by the max, then sum the masks
    % this effectively switches the ones to the max value of a column
    % which means a diff() call can then be used since if all values
    % are the same the output should be a zeros array. I have received
    % interesting comments about these sorts of methods, but tis how I
    % think about stuff... and testing shows its also a bit faster so
    % yeah... leave me alone, i even explained it...
    %
    % Masks scalar/singleton (and optionally empty) dim sizes 
    %     mask = any(sz == cat(3, 1, ~strict), 3);
    %
    % Binary mask replaces 1's and 0's with the max size in that dimension
    %     (sz .* mask)
    %
    % Binary mask zero-izes all 1's and zeros
    %     (sizes .* ~mask)
    %
    % There summation acts to replace all 1's and 0's with the column max
    %     (sz .* mask) + (sizes .* ~mask)
    %
    % If elements are the same diff returns zeros so we negate to get logical map of equivalent consecutive value
    %     ~diff((sz .* mask) + (sizes .* ~mask))
    %
    % Reducing by columns means we identify which dimensions are incompatible
    %     all(~diff((sz .* mask) + (sizes .* ~mask)), 1)

    % Allocate the max size (broadcasted output size) to avoid caller having to recompute max
    sz = max(sizes, [], 1);

    % Determine which elements to replace so that we are comparing properly
    mask = any(sizes == cat(3, 1, strict), 3);

    % Check validity condition
    valid = all(~diff((sz .* mask) + (sizes .* ~mask)), 1);

    % Replace any incompatible dimensions in the size output with nan as sentinel
    sz(~all(sizes, 1)) = nan;

    % Condense check for the output
    valid = all(valid);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
