%[text] This function is a generalized function broadcaster, functionally it is similar to both `cellfun()` and `arrayfun()` the difference being: the arguments do not need to be the same size, only broadcast compatible; in addition cell arrays and homogeneous arrays can be mixed using the `'UnwrapInputs'` option, by default all cell array arguments are unwrapped; and finally can be used parallelization with the `'InParallel'` option.
%[text] Note that when using parallel execution, all input arguments are broadcasted to each worker; this means that parallelization is likely only going to be beneficial if the bottleneck is function execution time.
function B = bcfun(fcn, A, options)
    arguments(Input)
        fcn {mustBeFunction};
    end
    arguments(Input, Repeating)
        A
    end
    arguments(Input)
        options.Fold (1, 1) logical = false;
        options.InParallel (1, 1) logical = false;
        options.UnwrapInputs (1, :) logical {mustBeScalarOrEqualSize(options.UnwrapInputs, A)} = cellfun("isclass", A, "cell");
        options.UniformOutput (1, 1) logical = true;
        options.Lazy (1, 1) logical = true;
    end
    arguments(Output)
        B
    end

    if(options.Lazy)
        B = bcfun_lazy(fcn, A, options);
    else
        [A{:}] = broadcast.arguments(A{:});
        B = fcn(A{:});
    end

    %#ok<*PFBNS>
end
%[text] Lazy broadcasting using index maps.
function B = bcfun_lazy(fcn, A, options)
    % Gather the broadcast indexing map with flattened argument array
    [A, map, sz] = broadcast_flatmap(A{:}, UnwrapInputs=options.UnwrapInputs);

    % Preallocate the output
    % NOTE: While you could make a direct allocation using the result of the first operation I have found that to be
    % problematic in the event that the class of the elements are not consistent. Consider the case where your first
    % output is a string, and you preallocate a string array. When attempting to write a pattern object, instead of
    % "upgrading" the array to a pattern array, the pattern is cast to a string, breaking the functionality. To avoid
    % this a cell array will be used for intermediate storage; I agree that semantically the horzcat() at the end should
    % behave identically to assignment... I've not always seen that to be the case. In any case using horzcat() or
    % vertcat() which a reshape, instead of cell2mat() which is significantly slower, is still relatively fast. If more
    % performance is desired than is given here it is recommended you write a specific implementation for your use case
    % instead of trying to utilize this generic broadcasting utility.
    B = cell(sz);

    % Dispatch to folded vs varargin implementation
    if(options.Fold)
        if(options.InParallel)
            parfor n = 1:width(map)
                B{n} = fold(fcn, A(map(:, n)));
            end
        else
            for n = 1:width(map)
                B{n} = fold(fcn, A(map(:, n)));
            end
        end
    else
        if(options.InParallel)
            parfor n = 1:width(map)
                B{n} = fcn(A{map(:, n)});
            end
        else
            for n = 1:width(map)
                B{n} = fcn(A{map(:, n)});
            end
        end
    end

    % Flatten the output if desired
    if(options.UniformOutput)
        B = reshape([B{:}], sz);
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
