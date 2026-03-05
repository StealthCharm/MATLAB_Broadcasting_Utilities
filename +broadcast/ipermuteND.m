%[text] This function performs the same functionality as ipermute with added functionality to reduce boilerplate when performing dimensional manipulations.
%[text] In addition to automatically prepending unspecified dimensions to the dimOrder, this function allows a size to be specified; the output of the permutation will be reshaped accordingly. If the sz argument is unused, no reshape will occur; if \[\] is used as the size argument, the output of the ipermute operation will be reshaped so that is size matches that of the input; otherwise the size can be specified as it would in reshape directly, or as a double array with NaN specifying where to use \[\].
function A = ipermuteND(A, dimOrder, sz)
    arguments(Input)
        % The input to permute
        A;

        % The order of the dimensional permutation
        dimOrder (1, :) double {mustBeInteger, mustBePositive};

        % The size to reshape the argument to
        sz (1, :) double {mustBeInteger, mustBeNonnegative};
    end

    % Permutes the input such that the output is in the correct order
    A = ipermute(reshape(A, sz(dimOrder)), dimOrder);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
