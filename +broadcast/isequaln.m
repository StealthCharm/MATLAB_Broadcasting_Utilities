%[text] This function is a broadcasted implementation of `isequaln()` for element wise comparisons on complex input objects where the relational operator is not an equivalency check.
function tf = isequaln(A, B)
    % Gather the operator pairings and output size
    [map, sz] = broadcast_map(A, B);

    % Preallocate the output
    tf = false(sz);

    % Perform each comparison
    for n = 1:numel(tf)
        tf(n) = isequaln(A(map(1, n)), B(map(2, n)));
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
