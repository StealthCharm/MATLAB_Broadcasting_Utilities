%[text] # Library Usage
%[text] This small library is meant to implement index maps for broadcasting enabling performance conscious broadcasting code to be written such that data duplication, and the use of the high overhead `cellfun()`/`arrayfun()`functions, can be avoided. While I have experimented with wrapping this into a class to provide a nice API, the implementations rely on redefining indexing methods which introduces overhead that is conceptually combative to the philosophy of this codebase.
%[text] Despite that inconvenience there are two main patterns of implementation using these primitive working patterns. As such I will cover them here. Note that matlab does have a snippet system for the IDE and you can add these patterns to the tab completion using:
%[text] - `matlab.snippets.createSnippets()`
%[text] - `matlab.snippets.editSnippets()`
%[text] - `matlab.snippets.viewSnippets()` \
%[text] In addition snippets have been provided in the `'resources'` folder for the binary and variadic cases, the keywords to use these are. These can be used with tab completion by typing `'Broadcast_{Binary | Variadic}'` if these are added to your path (IE you must remove the resource folder or the extensions.json file from the namespace folder.
%[text] ## Pattern 1: Known Input Count Broadcasting
%[text] While Pattern 2 is more general, and will working in place of pattern 1, its slightly more robust nature (robust in terms of handling variadic signatures) does incur more overhead. Often as a function author we know that sub-selections of the arguments our API expose will be broadcasted, or perhaps were simply broadcasting a function with known arguments, in this case, at the cost of slightly more boiler plate, we can reduce the overhead of Pattern 2. Note that while tedious it is technically possible to implement any known argument count with Pattern 1.
%[text] By knowing the argument count, output class, (which could be generated using the results of the first operation), and the function you would like to broadcast, a simple loop enables low-overhead broadcasting to be implemented.
% Example data
[A, B] = example_arguments();

% Know output type
output_class = "double";

% Function dependent on the function we're implementing
fcn = @plus;

% We use the broadcast.map for known argument count examples since its cheaper.
[map, sz, arg_sz] = broadcast.map(A, B);

% Preallocate the output
output = createArray(sz, output_class);

% Iterate through calls for each element of the output
for n = 1:width(map)
    output(n) = fcn(A(map(1, n)), B(map(2, n)));
end

% As expected this method of implementation works!
isequal(A + B, output) %[output:7db720c9]
%[text] ## Pattern 2: True Variadic Function Broadcasting
%[text] Although less common there are times where the function call that we are broadcasting is variadic. In this case it is necessary for us to repackage the arguments to maintain a generalized working pattern, broadcast.flatmap() does this by modifying the arguments such that they reside in a flat heterogeneous array and the map is offset to account for this; conceptually one could picture this as a virtual, jagged dimension representing the argument count.
% Example data
[A, B, C] = example_arguments();
args = {A, B, C};

% Know output type
output_class = "double";

% Function dependent on the function we're implementing
fcn = @add;

% We use the broadcast.flatmap for variadic functions
[args, map, sz, arg_sz] = broadcast.flatmap(args{:});

% Preallocate the output
output = createArray(sz, output_class);

% Iterate through calls for each element of the output
for n = 1:width(map)
    output(n) = fcn(args{map(:, n)});
end

% As expected this method of implementation works!
isequal(A + B + C, output) %[output:134050fd]
%%
%[text] # Additional Features
%[text] For convenience some other functions have been included:
%[text] - `isBroadcastCompatible():` An argument compatibility checker.
%[text] - `isequal() and isequaln():` Element wise broadcasting implementations which aid in complex object comparisons when the eq method is not implemented to signify equivalence.
%[text] - `package_arguments():` Acts to encapsulate the respective elements of each argument for every element of the resulting output; this is mostly meant for testing since its use acts to duplicate data thus defeating the gains that were meant to be had from this toolbox.
%[text] - `bcfun():` A generalized broadcaster that functions similarly to `arrayfun()` and `cellfun()`, with the benefit that you can mix cell and array inputs, enable parallelization, and avoid the data duplication either of those alternatives require. \
%%
%[text] # Broadcasting Background & Detailed Implementation Summaries
%[text] **Notes:** 
%[text] When discussing the implementation details of the functions, the conceptual implementation will be given focus; this is to say that the exact implementation details may differ from those shown here, care has been taken to document the actual implementation details within the functions themselves. If curious please reference the function definitions in their respective files.
%[text] This is also in no way extensive regarding broadcasting or cell semantics, and only serves as a bit of guidance in the event the function definitions do not make it clear what is happening. For those confident with broadcasting and cell-array semantics it is recommended that you inspect the function files. As some of the API details of those functions may be missing from the following conceptual walk through. The remaining documentation is to cover those conceptual details and touch on the reasoning behind some of the decisions made.
%[text] ## Broadcasting Definition & Rules
%[text] Before discussing each function a general overview of broadcasting is valuable. The rules for broadcasting state that the length of arguments for any given dimension is allowed to have, at most, two values; in the event two unique values are present, one of them must be 1. 
%[text] This gives use a convenient way to validate broadcast compatibility for arguments, and generating the output size of the result. To do this lets assume we have some arguments:
% Allow example switching
use_valid_arguments = false; %[control:checkbox:9ca5]{"position":[23,28]}
[A, B, output] = example_arguments(use_valid_arguments) %[output:590b7d7c] %[output:87fe0514] %[output:6095e61f]
%[text] ### `element_size()`
%[text] To gather the sizes and compare them we can align each arguments `size()` results in a row. This means that the size will be NxM where N is the number of operands and M is the dimension count of the highest dimension argument. This is difficult to do efficiently since we must find the size of each argument, but also ensure to pad the length of the size results to the highest dimension; in the example arguments this is an issue since `C` is three-dimensional. To normalize this pattern the private function `element_size()` was created, it takes in a cell array of the arguments and returns the flattened size matrix. Note that significant performance test was conducted on the various methods of retrieving the sizes, of those methods, that used in `element_size()` consistently out performed all other methods.
% Call the internal optimized size method to gather all argument sizes
arg_sizes = element_size({A, B, output}) %[output:0c2b27b3]
%[text] ### `broadcast.isValidSize()`
%[text] Now we will check the compatibility of the arguments for broadcasting. This is done in  `broadcast.isValidSize()` which expects a matrix in the previously mentioned format. The implementation of the check in that function has been optimized internally to account for the overhead of writes vs that of inline masking, but conceptually it is equivalent to the following:
%[text] - First we find the max length for each dimension (and each column is a dimension so we take the max along dim=1)
%[text] - This will be the output size of the broadcasted arguments if their compatible for broadcasting, we do not however know if they're compatible.
%[text] - To check compatibility we will do a broadcasted comparison of the `arg_sizes` array to both 1 and the output size we found.
%[text] - This gives use a logical map of valid dimensions for broadcasting, performing a all reduction along the columns gives us the results for each dimensions validity given the input arguments, if specificity about which dimensions are not needed a complete reduction can be produced. \
% Gives us the output size, which is also needed for check
output_size = max(arg_sizes, [], 1) %[output:16878b6d]

% Compare the length of every argument's dimensions 
is_valid = arg_sizes == output_size | arg_sizes == 1 %[output:1bd3239c]

% Reduce to check which dimensions conform to broadcasting semantics
is_valid_dimension = all(is_valid, 1) %[output:9b516cd9]

% If we only care for general compatibility check we use complete reduction
are_broadcast_compatible = all(is_valid, "all") %[output:2ba0e7ee]
%[text] Since the arguments are valid, this means broadcasting can be performed!
output = attempt(@() A + B + output) %[output:5376d31c]
%[text] If you would like to see this logic follow out with an invalid C argument, set the `use_valid_arguments` value to false, in live scripts this should be a check box, otherwise you can modify the value to false manually.
%[text] ### broadcast.size()
%[text] To encapsulate the workflow previously discussed, this namespace has `[sz, sizes] = broadcast.size().` This function returns the broadcasted output size along with the size matrix produced from `element_size()` (to avoid recalling it if the full size array is needed by `broadcast.size()`'s caller).
%[text] In addition it also has a name-value options called `Validate`. This options allows the function to act as a validator when incompatible arguments are used; when called from within a function it will throw an error, as the calling function, using the same error that would be thrown by MATLAB when broadcasting incompatible arguments are used. When the `Validate` option is set to false, instead of producing an error the outputs are returned but the incompatible dimensions in the `output_size` are set to NaN, this acts as the incompatibility sentinel, allowing easy detection with `ismissing()`/`isnan().`
% Using false we can gather the results and optionally perform more advanced handling/errors
[output_size, arg_sizes] = broadcast.size(A, B, output, Validate=false)  %[output:4dfd41c8] %[output:425a168d]

% Or when using as a compositional tool, we have it throw an error as its caller, when called from a function
[output_size, arg_sizes] = attempt(@() broadcast.size(A, B, output)) %[output:9c0da3b5] %[output:59e009d2]
%%
%[text] ## Enabling Broadcasting
%[text] Now that we understand how to check the compatibility of arguments for broadcasting, we can start to work towards an algorithm that enables us, as function authors, to implement broadcasting ourselves, in a consistent and low-overhead way. To do this we need to consider how code execution is working; MATLAB is a COW (copy on write) language this means that when you make a copy of a variable it behaves like a reference value until the copy or original are modified, once a modification occurs the modified version is copied and altered. MATLAB however does not employ a similar pattern for `repelem()` or `repmat()` which are used to replicate arrays. Another useful quirk about MATLAB is that, if an input argument to a function is used as its output, and that same pattern of A = foo(A) is used by the caller, MATLAB will overwrite the variable meaning we can avoid unnecessary allocations by modifying a variable instead of copying it.
%[text] As such there are instances where, even when a function supports *"partial"* broadcasting for arguments of exactly the same size (but not *"full"* broadcasting semantics) where it is beneficial for us to re-implement the function. This may involve sliced processing or referencing elements of the inputs in simple and fast for-loops rather than expanding the inputs which duplicates their elements (this is because allocations are expensive and there unnecessary since we are not modifying the data). 
%[text] ### `broadcast.map()`
%[text] This makes it beneficial for us to generate indexing maps. These maps will contain the index into a given argument, for each argument, for every element of the output. Again it is best to keep this in a standard, flat array for performance. As a convention we will mirror the previously discussed `element_size()` semantic, that is to say we well generate a NxM array where N is the number of arguments and M is the number of elements in the output. 
%[text] This is conceptually, and literally, compositional, and as you may notice the output count and function depth are related. This is because addition information is always passed up after that of the current functions call in the event it is needed:
%[text] - `[`**`arg_sizes`**`] = broadcast.element_size();`
%[text] - `[`**`output_size`**`, arg_sizes] = broadcast.size();`
%[text] - `[`**`map`**`, output_size, arg_sizes] = broadcast.map();` \
%[text] Regarding the map generator, the modulo math involved can get expensive to use writing code in MATLAB, but importantly, since we are using numeric values to index, and the base numeric classes implement highly-optimized vectorization using BLAS backed calls, we can use use MATLABs implicit broadcasting to build our maps.
%[text] If we know the output size, given by `broadcast.size()`, then we can just generate numeric arrays the same size as each argument, where the element value is equivalent to its linear index, add them to a zero array the same size of the output, and flatten the results. Since the implementation details and concept here are both simple we will avoid covering them, the explanation in the function file is available if desired. 
% These function require valid arguments so we'll regenerate them
[A, B, output] = example_arguments(true);

% A map is generated were each row is an input arguments indices
[map, output_size, arg_sizes] = broadcast.map(A, B, output) %[output:27dfbec3] %[output:203edc6b] %[output:610c21f0]
%[text] Note that we have a map of size 3x15. Our output size is 3x5 (for 15 total elements) and are argument count is 3. This enables a simple and consistent indexing pattern in for loops, the returned output size gives us the information we need to preallocate outputs when overwriting them is not desirable/possible:
% First we preallocate
output = zeros(output_size) %[output:6cc1e076]

% The width of our map corresponds to every element in the output
for n = 1:width(map)
    % Now we index using Argument(map(argN, n)) to gather the correct element
    output(n) = ...
        A(map(1, n)) + ... % First argument is argn = 1
        B(map(2, n)) + ... % Second argument is argn = 2
        output(map(3, n));      % Third argument is argN = 3
end

% Notice the equality
isequal(output, A+B+output) %[output:4fb9761b]
%[text] This pattern is convenient when, as a function author, we know the argument count we will broadcast, and don't want to pay the overhead for true variadic compatibility. Notice though how we do need to reference each argument by name, IE our code cannot adapt to repeating, or variadic arguments; in instances where we do need true variadic compatibility we can use `broadcast.flatmap()`.
%[text] ## Cell Semantics Review
%[text]  This function acts to allow repeated arguments by abstracting the separate arguments as offsets in a combined heterogeneous array. Consider the previous example but instead of named arguments we have a cell array (the structure returned from repeating arguments from a function perspective). We can mimic this without the complexity of functions by simple cell wrapping the previous arguments:
args = {A, B, output} %[output:8d051d14]
%[text] For those less familiar with MATLAB cell semantics, cell arrays allow storing heterogeneous data, when indexing normally (with parenthesis) we get out a sub-array that is itself a cell array. MATLAB however has a notion of comma separated lists (CSL) when you use curly braces to index you get out the unwrapped data in the respective cell.
% Using parenthesis to get a sub-array
ex = args(1:2) %[output:5a2b9911]

% Using braces to get separate outputs!
[ex1, ex2] = args{1:2} %[output:5fdcb08f] %[output:69e9f073]
%[text] These separate values also have implications for functions; when using brace indexing inside of a function call, the effect is that each output is a separate input to the function. This enables us to generalize variadic function calls. that means that we can call the plus operator with `A + B`, `plus(A, B)`, or `plus(args{1:2})` (since A and B are the first and second elements in `args`). Again notice the equality:
isequal(A + B, plus(args{1:2})) %[output:35f543c0]
%[text] ### broadcast.flatmap()
%[text] So with the MATLAB cell semantics covered, lets look at the capabilities this gives us. First we want to generate a broadcasting map, then we we conceptualize each argument as a jagged dimensional offset and modify the map, then we will condense all arguments into a single cell array, but in addition we will flatten each element of the arguments so that the total length of the flattened output is equivalent to the summation of each arguments element count:
% For later comparison
cmp_args = {A, B, output};
args = cmp_args %[output:993ff024]
%[text] Note that the repeating arguments of broadcast.map and broadcast.size were made with variadic arguments in mind. All we do is use {:} to output all arguments as separate inputs.
[map, output_size, arg_sizes] = broadcast.map(args{:}) %[output:1d167eab] %[output:6e567960] %[output:448a089c]
%[text] Since we have the `arg_sizes`, and since its oriented identically to the map, to generate the modified offsets all we do is take the product of the `arg_size` across the columns (in dimension 2), this gives us the element counts. Then we take the `cumsum()` to generate the offsets cumulatively; finally we add the offsets from `(1:end-1, :)` to `(2:end, :)` of the map (since the first argument doesn't require offsets).
argument_element_counts = prod(arg_sizes, 2) %[output:433af56c]
cumulative_offset = cumsum(argument_element_counts, 1) %[output:2f472a92]
map(2:end, :) = map(2:end, :) + cumulative_offset(1:2) %[output:7beb085e]
%[text] Finally the last requirement is that we flatten all elements into a single array, since we don't care about their shape we will row-ize them as we cell wrap each element, this is because vertical and horizontal concatenations are cheap and provide a performance conscious way to flatten arguments while respecting the original ordering relative to each arguments placement.
for n = 1:numel(args)
    % num2cell() just turns an array into a cell array with each
    % element of the input being a cell wrapped element of the output
    args{n} = row(num2cell(args{n}));
end

% Finally we flatten all arguments
args = [args{:}] %[output:7ffcc93a]
%[text] Now, instead of having to reference each argument specifically, the elements of all arguments are in a cell array and our map has be offset to account for this. This means that we can use each column of the map, and curly brace indexing, to generate repeating arguments for our the function we'd like to call; this enables a generalized processing pattern for truly variadic functions. This is the conceptual functionality of `broadcast.map().`
% We have some arguments from our repeating arguments block
args = {A, B, output};

% We prepare them for variadic broadcasting
[args, map, output_size] = broadcast.flatmap(args{:});

% We preallocate our output
output = zeros(output_size);

% Now our for loop is simple and generalized:
for n = 1:width(map)
    % Since we want all arguments map(:, n) gives us their indices
    % Since all arguments are condensed, we just use curly braces 
    output(n) = add(args{map(:, n)});
end

% Again notice the equality
isequal(A + B + output, output) %[output:905e249b]
%[text] It is worth noting that for both `broadcast.map()` and `broadcast.flatmap()` the input arguments ***must*** be broadcast compatible, IE their usage of Validate is true and is not capable of being modified in their respective APIs.
%[text] # Utility Functions
%[text] These are warning fix suppression codes, since the purpose is demonstration, certain patterns are used that would be atypical for normal code:
%#ok<*ASGLU>
%#ok<*UNRCH>
%#ok<*DEFNU>
%[text] This function returns example outputs that are either broadcast compatible depending on the input state.
function [A, B, C] = example_arguments(broadcast_compatible)
    arguments
        broadcast_compatible (1, 1) logical = true;
    end

    % These will remain the same in both examples
    A = reshape(1:15, 3, 5); B = (1:3)';
    
    % Alter C such that broadcasting is invalid
    if(broadcast_compatible)
        C = 1:5;
    else
        C = 1:3;
    end
end
%[text] Small utilities to encapsulate operations in the examples to reduce cognitive load for users less familiar with broadcast, or MATLAB semantics.
function out = attempt(fcn)
    arguments(Input)
        fcn function_handle
    end
    arguments(Output, Repeating)
        out
    end

    % Preallocate the output
    out = cell(1, max(1, nargout));

    % Attempt function call, if error assign output to error
    try [out{:}] = fcn(); catch ME; out{1} = ME; end
end
%[text] Simple macro to flatten the input to a row vector.
function A = row(A)
    A = reshape(A, 1, []);
end
%[text] Simple macro to flatten the input to a column vector.
function A = column(A)
    A = reshape(A, [], 1);
end
%[text] A repeating argument plus implementation so the semantics don't confuse readers less familiar with fold (or those that would recognize that for fold you can use cells so {} indexing isn't necessary; which while correct, destroys the useful ness of the example).
function out = add(args)
    arguments(Input, Repeating)
        args
    end

    out = fold(@plus, args);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
%[control:checkbox:9ca5]
%   data: {"defaultValue":true,"label":"Valid Arguments:","run":"Section"}
%---
%[output:7db720c9]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1"}}
%---
%[output:134050fd]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1"}}
%---
%[output:590b7d7c]
%   data: {"dataType":"matrix","outputData":{"columns":5,"name":"A","rows":3,"type":"double","value":[["1","4","7","10","13"],["2","5","8","11","14"],["3","6","9","12","15"]]}}
%---
%[output:87fe0514]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"B","rows":3,"type":"double","value":[["1"],["2"],["3"]]}}
%---
%[output:6095e61f]
%   data: {"dataType":"matrix","outputData":{"columns":3,"name":"C","rows":1,"type":"double","value":[["1","2","3"]]}}
%---
%[output:0c2b27b3]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"arg_sizes","rows":3,"type":"double","value":[["3","5"],["3","1"],["1","3"]]}}
%---
%[output:16878b6d]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"output_size","rows":1,"type":"double","value":[["3","5"]]}}
%---
%[output:1bd3239c]
%   data: {"dataType":"matrix","outputData":{"columns":2,"header":"3×2 logical array","name":"is_valid","rows":3,"type":"logical","value":[["1","1"],["1","1"],["1","0"]]}}
%---
%[output:9b516cd9]
%   data: {"dataType":"matrix","outputData":{"columns":2,"header":"1×2 logical array","name":"is_valid_dimension","rows":1,"type":"logical","value":[["1","0"]]}}
%---
%[output:2ba0e7ee]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"are_broadcast_compatible","value":"   0"}}
%---
%[output:5376d31c]
%   data: {"dataType":"textualVariable","outputData":{"name":"output","value":"  <a href=\"matlab:helpPopup('MException')\" style=\"font-weight:bold\">MException<\/a> with properties:\n\n    identifier: 'MATLAB:sizeDimensionsMustMatch'\n       message: 'Arrays have incompatible sizes for this operation.'\n         cause: {}\n         stack: [3×1 struct]\n    Correction: []"}}
%---
%[output:4dfd41c8]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"output_size","rows":1,"type":"double","value":[["3","5"]]}}
%---
%[output:425a168d]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"arg_sizes","rows":3,"type":"double","value":[["3","5"],["3","1"],["1","3"]]}}
%---
%[output:9c0da3b5]
%   data: {"dataType":"textualVariable","outputData":{"name":"output_size","value":"  <a href=\"matlab:helpPopup('MException')\" style=\"font-weight:bold\">MException<\/a> with properties:\n\n    identifier: 'MATLAB:sizeDimensionsMustMatch'\n       message: 'Arrays have incompatible sizes for this operation.'\n         cause: {}\n         stack: [3×1 struct]\n    Correction: []"}}
%---
%[output:59e009d2]
%   data: {"dataType":"text","outputData":{"text":"arg_sizes =\n     []\n","truncated":false}}
%---
%[output:27dfbec3]
%   data: {"dataType":"matrix","outputData":{"columns":15,"name":"map","rows":3,"type":"double","value":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"],["1","2","3","1","2","3","1","2","3","1","2","3","1","2","3"],["1","1","1","2","2","2","3","3","3","4","4","4","5","5","5"]]}}
%---
%[output:203edc6b]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"output_size","rows":1,"type":"double","value":[["3","5"]]}}
%---
%[output:610c21f0]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"arg_sizes","rows":3,"type":"double","value":[["3","5"],["3","1"],["1","5"]]}}
%---
%[output:6cc1e076]
%   data: {"dataType":"matrix","outputData":{"columns":5,"name":"output","rows":3,"type":"double","value":[["0","0","0","0","0"],["0","0","0","0","0"],["0","0","0","0","0"]]}}
%---
%[output:4fb9761b]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1"}}
%---
%[output:8d051d14]
%   data: {"dataType":"tabular","outputData":{"columns":3,"header":"1×3 cell array","name":"args","rows":1,"type":"cell","value":[["3×5 double","[1;2;3]","[1,2,3,4,5]"]]}}
%---
%[output:5a2b9911]
%   data: {"dataType":"tabular","outputData":{"columns":2,"header":"1×2 cell array","name":"ex","rows":1,"type":"cell","value":[["3×5 double","[1;2;3]"]]}}
%---
%[output:5fdcb08f]
%   data: {"dataType":"matrix","outputData":{"columns":5,"name":"ex1","rows":3,"type":"double","value":[["1","4","7","10","13"],["2","5","8","11","14"],["3","6","9","12","15"]]}}
%---
%[output:69e9f073]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"ex2","rows":3,"type":"double","value":[["1"],["2"],["3"]]}}
%---
%[output:35f543c0]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1"}}
%---
%[output:993ff024]
%   data: {"dataType":"tabular","outputData":{"columns":3,"header":"1×3 cell array","name":"args","rows":1,"type":"cell","value":[["3×5 double","[1;2;3]","[1,2,3,4,5]"]]}}
%---
%[output:1d167eab]
%   data: {"dataType":"matrix","outputData":{"columns":15,"name":"map","rows":3,"type":"double","value":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"],["1","2","3","1","2","3","1","2","3","1","2","3","1","2","3"],["1","1","1","2","2","2","3","3","3","4","4","4","5","5","5"]]}}
%---
%[output:6e567960]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"output_size","rows":1,"type":"double","value":[["3","5"]]}}
%---
%[output:448a089c]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"arg_sizes","rows":3,"type":"double","value":[["3","5"],["3","1"],["1","5"]]}}
%---
%[output:433af56c]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"argument_element_counts","rows":3,"type":"double","value":[["15"],["3"],["5"]]}}
%---
%[output:2f472a92]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"cumulative_offset","rows":3,"type":"double","value":[["15"],["18"],["23"]]}}
%---
%[output:7beb085e]
%   data: {"dataType":"matrix","outputData":{"columns":15,"name":"map","rows":3,"type":"double","value":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"],["16","17","18","16","17","18","16","17","18","16","17","18","16","17","18"],["19","19","19","20","20","20","21","21","21","22","22","22","23","23","23"]]}}
%---
%[output:7ffcc93a]
%   data: {"dataType":"tabular","outputData":{"columns":23,"header":"1×23 cell array","name":"args","rows":1,"type":"cell","value":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","1","2","3","1","2","3","4","5"]]}}
%---
%[output:905e249b]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1"}}
%---
