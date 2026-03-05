function [tf, sz, sizes] = isBroadcastCompatible(A, options)
    arguments(Input, Repeating)
        A
    end
    arguments(Input)
        options.Strict (1, 1) logical = true;
    end

    % Gather the size of each input
    sizes = element_size(A);

    % Check the validity
    [tf, sz] = broadcast.isValidSize(sizes, options.Strict);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
