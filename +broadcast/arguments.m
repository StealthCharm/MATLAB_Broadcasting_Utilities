%[text] This function expands the arguments to the size of the broadcasted output argument.
function args = arguments(args)
    arguments(Input, Repeating)
        args 
    end
    arguments(Output, Repeating)
        args 
    end

    % Determine the broadcasted output size 
    [sz, arg_sizes] = broadcast.size(args{:});
    
    % Determine the replication size of each argument
    rep_sz = sz ./ arg_sizes;
    
    % Replicate the inputs to extent them to full size
    for n = 1:numel(args)
        args{n} = repmat(args{n}, rep_sz(n, :));
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
