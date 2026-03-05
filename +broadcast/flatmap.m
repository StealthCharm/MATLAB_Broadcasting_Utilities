%[text] This function produces a flattened broadcast array.
%[text] The output is a cell row vector with the inputs of all input arguments. The map contains a row for each input with a column count equivalent to the number of elements in the broadcasted output; each index in the map corresponds the the linear index of the element in the flattened output cell array.
function [A, map, sz, sizes] = flatmap(A, options)
    arguments(Repeating)
        A 
    end
    arguments
        options.SplitMap (1, 1) logical = false;
        options.UnwrapInputs (1, :) logical {mustBeScalarOrEqualSize(options.UnwrapInputs, A)} = cellfun("isclass", A, "cell");
        options.Validate (1, 1) logical = false;
    end

    % Gather the broadcasting map information 
    [map, sz, sizes] = broadcast.map(A{:}, Validate=true);
    
    % Compute the offset of each element in all inputs to allow static indexing post flattening
    flat_stride = [0; cumsum(prod(sizes(1:end-1, :), 2), 1)];
    map = map + flat_stride;
    
    % Flatten inputs that are to be unwrapped
    for n = row(find(options.UnwrapInputs))
        A{n} = row(A{n});
    end
    
    % Flatten inputs that are not be unwrapped
    for n = row(find(~options.UnwrapInputs))
        A{n} = num2cell(row(A{n}));
    end
    
    % Flatten the inputs
    A = horzcat(A{:});

    % Allows the map to be returned as a 1xN cell array with elements of size sz
    if(options.SplitMap)
        map = reshape(permute(map, [2, 1]), [sz, nargin]);
        map = num2cell(map, 1:ndims(map) - 1);
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
