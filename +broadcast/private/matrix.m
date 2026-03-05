%[text] Initializes an array of the given size with provided value.
function sz = matrix(sz)
    arguments(Input)
        sz (1, :) double {mustBeInteger(sz)};
    end

    % Either creates the matrix or returns empty double
    if(~isempty(sz))
        % Initializes an array where the value of each element is its linear index
        sz = reshape(1:prod(sz), sz);
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
