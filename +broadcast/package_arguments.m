%[text] This function acts to package broadcasted argument values. Useful when testing, not recommended for production due to data duplication.
function args = package_arguments(A, options)
    arguments(Input, Repeating)
        A
    end
    arguments(Input)
        options.UnwrapInputs (1, :) logical {mustBeScalarOrEqualSize(options.UnwrapInputs, A)} = cellfun("isclass", A, "cell");
        options.UnwrapPackages (1, :) logical = cellfun("isclass", A, class(A{1}));
    end

    % Generate the flattened argument vector and index map
    [A, map, sz] = broadcast.flatmap(A{:}, UnwrapInputs=options.UnwrapInputs);

    % Preallocate the output
    args = cell(sz);

    % Process output argument pairings based on whether flattening is desired
    if(options.UnwrapPackages)
        % Flattens the argument elements into a row vector
        for n = 1:width(map)
            args{n} = [A{map(:, n)}];
        end
    else
        % Keeps each argument separated in a cell
        for n = 1:width(map)
            args{n} = A(map(:, n));
        end
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
