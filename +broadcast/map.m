%[text] This function produces the index map for broadcasting the inputs together in a computation. 
%[text] The output is a row wise map of the indices for each input. That is to say the the output is an \[N, M\] array where N is the number of inputs and M is the number of elements in the broadcasted output.
function [index_map, output_size, sizes] = map(A, options)
    arguments(Repeating)
        A 
    end
    arguments
        options.Validate (1, 1) logical = false;
        options.SplitMap (1, 1) logical = false;
    end

    % Validate size compatibility and determine output size
    [output_size, sizes] = broadcast.size(A{:}, Validate=true);

    % Use a zeros array to broadcast the indices
    % store outside of loop to avoid reallocating
    expansion_matrix = zeros(output_size);
    N = numel(A);

    % Preallocates the output map for each of the inputs
    index_map = zeros([N, prod(output_size)]);

    % Computes the index map for each input
    for n = 1:N
        index_map(n, :) = row(matrix(sizes(n, :)) + expansion_matrix);
    end   

    % Allows the map to be returned as a 1xN cell array with elements of size sz
    if(options.SplitMap)
        index_map = reshape(permute(index_map, [2, 1]), [output_size, N]);
        index_map = num2cell(index_map, 1:ndims(index_map) - 1);
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
