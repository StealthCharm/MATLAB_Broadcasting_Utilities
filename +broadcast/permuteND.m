%[text] This function is a utility focused on reducing the complexity of managing permutation logic when writing ND compatible functions.
%[text] The dim argument is automatically padded to include all non-listed dimensions of A, return the padded output, and optionally allow store the size of A from the same call. By default the output is automatically reshaped such that the output is a matrix with a height corresponding to the product of the `dim` argument dynamically adjusting the column count as needed. The function allows simple wrappers so employ skeleton logic to generalize the issue of ND permutations allowing static indexing patterns and fallback to pre-vectorized functions. For examples see `quot()`, `cumquot()`, and `cumdiff()`.
function [A, dimOrder, Asz] = permuteND(A, dim, options)
    arguments(Input)
        A;
        dim (1, :) double {mustBeInteger, mustBePositive} = unique([2, 1:ndims(A)], "stable");
    end
    arguments(Input)
        options.Dim double {mustBeInteger, mustBeScalarOrEmpty} = [];
        options.NDim double {mustBeInteger, mustBeScalarOrEmpty} = [];
    end

    % Record input size and determine permutation's dimension order
    [dimOrder, ndim] = broadcast.permuteDims(A, dim);
    Asz = size(A);

    % Permutes the input such that the output is in the correct order
    A = permute(A, dimOrder);
    A = reshape(A, [prod(Asz(dim)), prod(Asz(ndim))]);

    % Adjust the selected dimensions accordingly
    if(~isempty(options.Dim))
        Asz(dim) = (Asz(dim) .* (options.Dim < 0)) + options.Dim;
    end

    % Adjust the non-selected dimensions accordingly
    if(~isempty(options.NDim))
        Asz(ndim) = (Asz(ndim) .* (options.NDim < 0)) + options.NDim;
    end
end
%[text] ## More expensive implementation with size argument
%[text] This is the previous implementation I made prior to getting comfortable with permuted working algorithms. I thought that the size argument would be useful so included a nice "just works" API that resembles other size argument function syntaxes. In practice however, I don't use it at all so I'm removing that functionality to improve performance. Notice that the streamlined version is mostly inline, and eliminates all branching that isn't absolutely mandatory.
% function [A, dimOrder, Asz] = permuteND(A, dim, sz, options)
%     arguments(Input)
%         A;
%         dim (1, :) double {mustBeInteger, mustBePositive} = unique([2, 1:ndims(A)], "stable");
%     end
%     arguments(Input, Repeating)
%         sz (1, :) double {mustBeIntegerOrNaN};
%     end
%     arguments(Input)
%         options.Dim double {mustBeInteger, mustBeScalarOrEmpty} = [];
%         options.NDim double {mustBeInteger, mustBeScalarOrEmpty} = [];
%     end
% 
%     % Normalize the input arguments
%     sz = normalize_size(A, dim, sz);
%     dimOrder = permuteDims(A, dim);
% 
%     % Optionally returns the inputs size as output
%     if(nargout > 2)
%         Asz = generate_size(A, dim, dimOrder, options);
%     end
% 
%     % Permutes the input such that the output is in the correct order
%     A = permute(A, dimOrder);
% 
%     % Optionally reshapes the output
%     if(~isempty(A) && ~isempty(sz))
%         % Calls reshape with multiple size arguments
%         A = reshape(A, sz{:});
%     end
% end
%[text] This function handle formatting the reshape size arguments so that they're normalized and in the expected format.
% function sz = normalize_size(A, dimOrder, sz)
%     % Handle normalization for various patterns
%     if(isempty(sz))
%         % Default behavior is collapse to 2D with height of combined dimension length
%         sz = {prod(size(A, dimOrder)), []};
%     elseif(isSentinelSz(sz))
%         % Allow [] to signal keep the input the same size
%         sz = {};
%     else
%         % Normalize the input reshape size arguments
%         sz = cell2size(sz{:});
% 
%         % Add the last dimension as resizable if needed
%         if(~anymissing(sz) && numel(A) ~= prod(sz))
%             sz = [sz, nan];
%         end
% 
%         % Reform reshape arguments as cell to avoid syntax issues
%         sz = size2cell(sz);
%     end
% end
%[text] Determine if a single size was provided as \[\] or nan, which act as sentinels to signal not to perform the shape
% function tf = isSentinelSz(sz)
%     tf = isscalar(sz) && isMissingNum(sz{1});
% end
%[text] Checks that the input is either a scalar \[\] value, or a scalar nan value.
% function tf = isMissingNum(A)
%     tf = isnumeric(A) && (isempty(A) || (isscalar(A) && ismissing(A)));
% end
%[text] Generate the size output according to the manipulation rules.
% function Asz = generate_size(A, dim, dimOrder, options)
%     % Record the original input size
%     Asz = size(A);
% 
%     % Optionally tweak the dimension being used as though a reduction occurred
%     if(~isempty(options.Dim))
%         % Allows negative inputs to be relative
%         if(options.Dim < 0)
%             options.Dim = Asz(dim) + options.Dim;
%         end
% 
%         Asz(dim) = options.Dim;
%     end
% 
%     % Optionally tweak the dimension not specified as though a reduction occurred on them
%     if(~isempty(options.NDim))
%         ndim = setdiff(dimOrder, dim);
% 
%         % Allows negative inputs to be relative
%         if(options.NDim < 0)
%             options.NDim = Asz(ndim) + options.NDim;
%         end
% 
%         Asz(ndim) = options.NDim;
%     end
% end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
