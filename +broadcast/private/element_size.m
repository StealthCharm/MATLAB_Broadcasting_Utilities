%[text] This function returns the size of each element in a cell array. This is useful for normalization so that results can be flattened. 
%[text] This can be done trivially with things like `cellfun()`, or even simple iterative loops, but testing has shown that the most performative way to achieve this is to first do a dimensionality pass, then preallocate a vector to store the results in. It seems counter intuitive that calling `ndims()` just to store the element count of the size return to then have to recalculate the `size()` and store it would be quicker, at least to me, but from all my testing that has been the case; and not insignificantly so.
function [sz, dim] = element_size(A, dims, opts)
    arguments
        A 
        dims (1, :) double {mustBeInteger} = 0;
    end
    arguments
        opts.Max (1, 1) logical = false;
    end

    % Short circuits for simple cases to improve performance
    switch(numel(A))
        case 0
            % No inputs returns empty output
            sz = [];

        case 1
            % Inline size collection
            sz = size(A{1}, 1:max(ndims(A{1}), dims));

        case 2
            % Vertically concatenate the size of each input
            dims = 1:max([ndims(A{1}), ndims(A{2}), dims], [], "all");
            sz = [size(A{1}, dims); size(A{2}, dims)];

        otherwise
            % Generalized solution for arbitrary input count
            sz = case_03(A, dims);
    end

    if(nargin == 1)
        % If a padding dimension is not provided the max dimension of any input is just the width
        dim = width(sz);
    else
        % If we padded the dimension then well check which column is the last with a non 1 size
        dim = find(~all(sz == 1, 1), 1, "last");
    end

    % Handle optional output formatting
    if(opts.Max)
        % Returns the maximum length in each dimension; useful for checking broadcasted output sizes
        sz = max(sz, [], 1);
    end
end
%[text] This is the generalized algorithm to gather the size of each element in the cell array. To improve performance this has been avoided for simple cases `(sizes < 2)`. It is worth noting that the performance of gathering variadic sizes was tested and all methods of gather the size of an element, to then pad and concatenate, or perform jagged writes, performed worse than padding the dimension vector of the `size()` call.
function sz = case_03(A, dims)
    % Check the max dimension to gather
    dim = max(cellDims(A), dims);
    dims = 1:dim;

    % Preallocate output
    sz = ones([dim, numel(A)]);

    % In testing column wise writes were faster even with necessary transpose call
    for n = 1:width(sz)
        sz(:, n) = size(A{n}, dims);
    end

    % Transpose output to ensure row-wise output
    sz = transpose(sz);
end
%[text] Small utility to gather the dimension count of each element in a cell array without the overhead of cellfun, note that the optimized older syntax of `cellfun("ndims", A)` can not be used here since it returns invalid results for any class implementing a `size()` method, any class inheriting from primitive object classes; this includes many built-in type classes such as datetime, duration, calendarDuration, string, and categorical. To avoid the issue, or introducing overhead to detect the conditions that make `cellfun("ndims", A)` invalid, a preallocation and simple loop are used.
function dims = cellDims(A)
    dims = zeros(size(A));

    for n = 1:numel(dims)
        dims(n) = ndims(A{n});
    end

    dims = max(dims, [], "all");
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
