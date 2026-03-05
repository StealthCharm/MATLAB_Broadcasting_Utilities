%[text] This small utility pads the `dim` argument appropriately so that includes all dimension of argument `A`; unlisted dimensions of `A` are appended to the end of the `dim` argument in ascending order.
function [dimOrder, ndim] = permuteDims(A, dims, options)
    arguments(Input)
        A
        dims (1, :) double {mustBeInteger, mustBePositive} = [];
        options.Max (1, 1) double {mustBeInteger} = 0;
    end
    arguments(Output)
        dimOrder (1, :) double;
        ndim (1, :) double;
    end

    % In the worst decision ever these two classes have decided to lie about 
    % their shape requiring we check explicitly... don't get me started...
    if(isa(A, "symfun") || isa(A, "symfunmatrix"))
        A = formula(A);
    end

    % To fill the partial dimension vector we ensure to consider trailing singleton inclusion from the 
    % input and take the unique elements from either set preferring the input order to maintain priority.
    [dimOrder, ~, ndim] = union(dims, 1:max([ndims(A), dims, options.Max]), "stable");
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
