%[text] # Library Usage
%[text] This small package was made with the goal of creating a working pattern for ND-compatible reduction, expansion, scan, and cumulation operations. Many base MATLAB functions have behaviors that act along arbitrarily specified dimensions. When making functions that behave similarly it can be difficult to do the permutation book-keeping in the function body. As such a working pattern has been identified that makes implementing dimensional operations trivial for ND inputs and arbitrary numbered/valued working dimensions.
%[text] For those unfamiliar, a permutation acts to reorient an array, walking along dimensions in the specified order of the dimOrder argument. To simplify the mental model, conform with MATLAB for-loop semantics for convenience, and generalize algorithms, we can permute arrays and utilize static indexing patterns in place of using dynamic indexing. 
%%
%[text] ## Dynamic Indexing and Slicing vs Static Indexing
%[text] As a note, I'm unsure that static and dynamic indexing is are technical terms, nor in wide use, but they've has become a technical term in my personal vocabulary as I have develop as a MATLAB author. As such its worth noting what I mean when I say static and dynamic indexing. To define these it is first beneficial to look at an example problem; lets start simple and say that we would like to write a version of `sum(A, dim)` that has the same behavior as the built-in implementation, obviously we will avoid using `sum()` and any other implemented dimensional functions:
% These will represent out inputs
A = matrix(3, 5, 2, 2) %[output:00a89cf1]
dim = [2, 4] %[output:10fb40c5]

% The expected result
E = sum(A, dim) %[output:8d3e93ce]
%[text] We have a few different methods of solving this problem lets look at each:
%[text] - Slice using `num2cell()`, then use `cellfun()`, or iterate through results adding manually.
%[text] - Implement an iteration wise method and use dynamic indexing to call results. \
%[text] Since the point is showing how to group the elements of each operation, and the operation details are irrelevant we'll allow sum() calls on each internal group once we separated them.
%[text] ### Slicing
%[text] Note that in this method we have to slice and store the output in cells, while cellfun() is being used here as an example its overhead is non-trivial and even if we used a loop we would have to preallocate 
% This acts to split the elements
B = num2cell(A, dim) %[output:6a6f28b9]

% Though a for-loop would be better for most generic implementations
B = cellfun(@(x) sum(x, "all"), B) %[output:9efe7a8f]
%[text] ### Dynamic Indexing
%[text] Dynamic indexing refers to a pattern of using repeating arguments as inputs to an indexing call. It uses `idx = repmat({':'}, 1, ndims(A))` style initializations then mutates the indices according to the loop variable value which acts to walk dimensions, the problems with this method is two-fold, it is less able to be generalized and branch-less, and is still quite heavy in terms of overhead. As such I will not be producing an example, as to do so completely would be tedious, This is not a non-existent pattern however; I have seen in in quite a few code bases, and use to use it myself before wrestling with higher dimension inputs, when your dimensionality is at most 3, this pattern can be far less tedious/brittle but even then the overhead an truly ND incompatibility makes this un-advisable.
%[text] ### Static Indexing
%[text] Whenever a for loop refers to indices statically, IE only mutating a single argument that corresponds to the loop iterator, this is static indexing. Typically these patterns are far faster than slicing and dynamic indexing. As an aside while static indexing could be ND so long as the dimensions are known, I typically consider it bad practice to use subscripts, with the exception of 2D arrays that we have mutated specifically to collapse higher dimensions or conceptually alter the view of an array.
%%
%[text] ## Permutations
%[text] So then since slicing and iteration or `cellfun()` calls are off the table that leaves us with permutations. The issue is their effect on the shape of an input. As a rule the shape of a permuted array given a `dimOrder` is `size(A, dimOrder)` while this is sensible it doesnt necessarily help us unless we want to then index using ranges based on the combined stride length, What we need is a way to collapse the result of the permutation. A nice pattern for doing so is to collapse the input, making it 2D where the height is equal to the product of the dims specified and the width is auto-calculated which simply makes the width as long as is needed to include the remaining elements.
% Our hypothetically given input and specified dimensions
A = matrix(3, 5, 2, 2) %[output:93b961a8]
dim = [2, 4] %[output:5fc2c260]

% We will record out original input size and the full permutation order
Asz = size(A);
dimOrder = [2, 4, 1, 3];

% So we first we permute, then we reshape
A = permute(A, dimOrder) %[output:136130e1]
A = reshape(A, prod(Asz(dim), "all"), []) %[output:9d0e0d64]
%[text] Now you'll notice that all arguments of each element in the output are aligned in columns that is to say the the output will have a number of elements equal to the width of A and each element of the output will be the result of an operation using a number of operand equivalent to the height of the permuted and reshaped input... Said even more simply: In the example of implementing summation, all we now need to do is add each column.
% Remember we care about the organization, its done so we'll just use sum
A = sum(A, 1), E %[output:4dc2339d] %[output:9516ccc8]
%[text] Notice that if we flatten our expected result our answer would align, but to maintain consistent APIs we need to find the pattern that re-conforms our calculated output to the expect; how might we do this? Well reduction operations act to set the size of Asz(dim) = 1. After realizing that, all we need to do is ipermute and reshape... but in what order? Well since originally we permuted the input then reshaped to invert this change we must first reshape and the ipermute the input to get it back in its original orientation. For the reshape and inverse permutation to map properly however we must reshape the input according to `reshape(A, Asz(dimOrder))`. This may seem un-intuitive at first but arises from the previously mentioned property of permutations where the size of a permuted array is `size(A, dimOrder)` the inverse is also true, meaning that we must align the modified original size according to the original permutation prior to using the size for reshape. Then we can act to ipermute the input with the original dimOrder. Below is an example:
% First we account for any changes, in this case reduction
Asz(dim) = 1;
A = reshape(A, Asz(dimOrder)) %[output:44ac3221]
A = ipermute(A, dimOrder) %[output:32034551]

% Now A and E no longer vary in size or orientation!
isequal(A, E) %[output:1bb8072a]
%%
%[text] ## Developing a Primitive Processing Algorithm
%[text] While ND operations and permutations can be unintuitive, especially as the dimensionality of inputs and dim lengths increase, its also worth noting that the dimOrder in the example above was given. From an API perspective we want users to specified the operational dimensions (note I avoid using reduction since algorithmically this pattern is identical for reductions, expansions, scans, and cumulations). As a result it makes sense we would want to generalize this pattern. 
%[text] ### permuteDims()
%[text] The first thing to do is create a utility that generates a dimOrder from our input data and dim argument. It turns out this is easy, the algorithm for doing so is just: union(dim, 1:ndims(A), "stable"), meaning we just append the excluded dimensions of A in ascending order after those specified. This is done using `permuteDims()`.
%[text] ### permuteND()
%[text] Next, it would be nice to reduce the cognitive load on function authors, ideally we would have a means of recording the original input size, gather the dimOrder, and making and changes to the expected output size we may need. This is where `permuteND()` comes in. It has a signature of:
%[text]{"align":"center"} `[A, dimOrder, Asz] = permuteND(A, dim, sz{:}, Dim=[], NDim=[])`
%[text] **Outputs:**
%[text] - `A` is the permuted and reshaped input according to the algorithm discussed above.
%[text] - The `dimOrder` is the full order produced by `permuteDims()`, often this is nice to keep in addition to, not in place of, the `dim` input.
%[text] - The `Asz` output is the size of the input ***pre-permutation/reshape***. This is used in conjunction with the name value arguments to modify the recorded size in known modification patterns.  \
%[text] **Inputs:**
%[text] - The `A` argument is the input data to be transformed for processing.
%[text] - The `dim` argument is that specifying the dimensions to operate over, ***not*** the full dimOrder.
%[text] - The `sz` argument is a repeating, optional argument that replaces the flattening reshape pattern post permutation if specified, the default behavior when no `sz` is provided is to flatten the input to a 2D matrix where each column is an iteration of all specified dimensions.
%[text] - The name value arguments `Dim` and `NDim` allow the pre-permuted size of `A` to be modified, when left empty (their default values) no changes are made, when set to a positive number all dimensions are set to that value, when set to a negative number the dimensions are reduced relative to their initial value. The `Dim` argument affects all dimensions in the `dim` input argument and the `NDim` argument affects all dimensions not in the `dim` argument, IE those added by `permuteDims()`. \
%[text] ### ipermuteND()
%[text] This results in far less book keeping but extending this idea even further we can define an `ipermuteND()` that acts as the inverse of our custom `permuteND()` function. It will take the excess outputs of our permuteND() and ensure to make the reshape size modifications we mentioned. As such its signature is:
%[text]{"align":"center"} `A = ipermuteND(A, dimOrder, Asz)`
%[text] This enables us to ignore all the complexity of permutations and instead follow a simple pattern for all dimensional operations.
%[text] ### The Permutation Workflow
%[text] Now any dimensional operation comes down to a single pattern:
% Normally I have these on my path; ie: not within the package, but for the sake of sharing we'll bundle them since
% they're both useful in eliminating overhead and writing generalized coded that follows the dimensional operations and
% broadcasting behavior found in most built-in functions. If you'd like you can remove these from the package, leave them in the package but remove
% the ND suffix, or whatever else you may want... I'm not your dad.
import broadcast.permuteND;
import broadcast.ipermuteND;
import broadcast.permuteDims;

% Example of our interface as a function author
[A, dim] = example_inputs() %[output:78b14a51] %[output:3f60c1bd]

% Gather expected output
E = sum(A, dim);

% Permute the input, use NV to apply reduction
[A, dimOrder, Bsz] = permuteND(A, dim, Dim=1) %[output:4c5c63f8] %[output:3a6d83a8] %[output:32d22fab]

% Preallocate the output
B = zeros(1, width(A));

% Operate on each working set (overwriting output to first elemtn
for n = 1:width(A)
    B(n) = sum(A(:, n), "all");
end

% Reorient the output 
B = ipermuteND(B, dimOrder, Bsz);

% Note the equality
isequal(B, E) %[output:2720b3f1]
%[text] With this pattern we avoid the overhead of `cellfun()` slicing methods, remove the dynamic nature and overhead of dynamic indexing, get a universal algorithm for this type of operations, and optimize cache hits by aligning data into columns due to MATLABs column major storage pattern. 
%%
%[text] # Examples of Utility
%[text] To highlight the value of this abstraction lets look at some data processing workflows. Take not that often the problems we are solving can be abstracted to dimensional operations themselves, even in surprisingly complex object processing pipelines, we can often abstract the problem to cheap logical masking, or small magnitude integer problems.
%[text] ## `quot()`
%[text] Perhaps we would like a compliment to the prod() function; luckily prod() uses BLAS calls and is incredibly fast, so long as we can access the elements we want this can be implemented by simply inverting all elements in the specified dimensions after the first:
%[text] This function is the compliment to `prod()`. Instead of computing the product along the specified dimensions it calculates the quotient.
function A = quot(A, dim, options)
    arguments(Input)
        A double
        dim (1, :) DimensionArgument = DimensionArgument(A, true);
    end
    arguments(Input, Repeating)
        options (1, 1) string {mustBeMember(options, ["default", "double", "native", "includemissing", "omitmissing"])};
    end

    % Unwrap the dimension
    dim = dim.dims(A);

    % Make the permutation
    [A, dimOrder, Asz] = permuteND(A, dim, Dim=1);

    % Invert all folded elements 
    A(2:end, :) = A(2:end, :).^-1;

    % Take the product of first element and inverse of all further to compute the quotient 
    A = prod(A, 1, options{:});

    % Conform the output shape accordingly
    A = ipermuteND(A, dimOrder, Asz);
end
%[text] ### `numuniqueND()`
%[text] Perhaps we would like to check the number of unique elements in an array, but would like the unique-ness of the elements to only considered the dims specified; note that so long as the unique-ness of elements can be gathered (MATLAB does this using sorting, though hash based implementations would work all the same), we are using index math to do the unique-ness mapping, regardless of object complexity this is a universal pattern so long as unique-ness is able to be gathered:
%[text] This function performs the same computation as numunique but relative to the specified dimensions.
function n = numuniqueND(A, dim, options)
    arguments(Input)
        A
        dim (1, :) DimensionArgument = DimensionArgument(A, true);
        options.TreatMissingAsDistinct (1, 1) logical = false;
    end

    % Normalize the input argument
    dim = dims(dim, A);

    % Record the input size
    [A, dimOrder, sz] = permuteND(A, dim, Dim=1);
    Asz = size(A);

    % Get the results of the unique call and format the index map to match the input shape
    [~, ~, ic] = mw_unique(A, options);
    An = reshape(ic, Asz);

    % Sort the indices & generate the map for reverting indices
    U = sort(An, 1);
    n = sum([logical(diff(U, 1, 1)); true(1, Asz(2))], 1);

    % Remap the correct orientation to the array
    n = ipermute(reshape(n, sz(dimOrder)), dimOrder);
end
%[text] This function normalizes behavior to allow older versions of MATLAB to call the function. The validation of arguments is handled by the main function so the order is changed to avoid re-validation. Since 2026a the TreatMissingAsDistinct Name-value option was added, this ensures that even older versions can use this function.
function [U, ia, ic] = mw_unique(A, options)
    arguments(Input)
        A
        options
    end

    % Dispatch the function that is supported depending on the version of MATLAB install
    if(isMATLABReleaseOlderThan("R2026a"))
        % Make original call
        [U, ia, ic] = unique(A);

        % Modify the output so behavior matches TreatMissingAsDistinct
        if(options.TreatMissingAsDistinct)
            % Check for missing elements
            missing_elements = row(find(ismissing(A)));

            % Set the remap values for the missing entries
            uidx = missing_elements(1);
            missing_elements(1) = [];

            % Modify the results to match the newer function behavior
            ic(any(ic == missing_elements, 2)) = uidx;
        end
    else
        % Make updated function call
        [~, ~, ic] = unique(A, TreatMissingAsDistinct=options.TreatMissingAsDistinct);
    end
end
%%
%[text] # Utility Functions
%[text] Generate a test input for use in walk throughs.
function [A, dim] = example_inputs(max_dim_length, max_dim_count)
    arguments(Input)
        max_dim_length = 5;
        max_dim_count = 10;
    end

    % Randomly generate a test input size and dim dimensions
    Asz = randi([1, max_dim_length], 1, randi([1, max_dim_count], 1, 1));
    dim = [];

    % Ensure non-empty outputs
    while(isempty(dim))
        dim = find(~randi([0, 1], 1, numel(Asz)));
    end

    % Generate the test input
    A = matrix(Asz);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"code":{"fontSize":"10"},"heading1":{"color":"#1171be","fontSize":"14"},"heading2":{"color":"#1171be","fontSize":"12"},"heading3":{"color":"#1171be","fontSize":"10"},"normal":{"fontSize":"10"},"referenceBackgroundColor":"#ffffff","title":{"color":"#0072bd","fontSize":"16"}}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
%[output:00a89cf1]
%   data: {"dataType":"textualVariable","outputData":{"name":"A","value":"A(:,:,1,1) =\n     1     4     7    10    13\n     2     5     8    11    14\n     3     6     9    12    15\nA(:,:,2,1) =\n    16    19    22    25    28\n    17    20    23    26    29\n    18    21    24    27    30\nA(:,:,1,2) =\n    31    34    37    40    43\n    32    35    38    41    44\n    33    36    39    42    45\nA(:,:,2,2) =\n    46    49    52    55    58\n    47    50    53    56    59\n    48    51    54    57    60"}}
%---
%[output:10fb40c5]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"dim","rows":1,"type":"double","value":[["2","4"]]}}
%---
%[output:8d3e93ce]
%   data: {"dataType":"textualVariable","outputData":{"name":"E","value":"E(:,:,1) =\n   220\n   230\n   240\nE(:,:,2) =\n   370\n   380\n   390"}}
%---
%[output:6a6f28b9]
%   data: {"dataType":"textualVariable","outputData":{"header":"3×1×2 cell array","name":"B","value":"B(:,:,1) = \n    {1×5×1×2 double}\n    {1×5×1×2 double}\n    {1×5×1×2 double}\nB(:,:,2) = \n    {1×5×1×2 double}\n    {1×5×1×2 double}\n    {1×5×1×2 double}"}}
%---
%[output:9efe7a8f]
%   data: {"dataType":"textualVariable","outputData":{"name":"B","value":"B(:,:,1) =\n   220\n   230\n   240\nB(:,:,2) =\n   370\n   380\n   390"}}
%---
%[output:93b961a8]
%   data: {"dataType":"textualVariable","outputData":{"name":"A","value":"A(:,:,1,1) =\n     1     4     7    10    13\n     2     5     8    11    14\n     3     6     9    12    15\nA(:,:,2,1) =\n    16    19    22    25    28\n    17    20    23    26    29\n    18    21    24    27    30\nA(:,:,1,2) =\n    31    34    37    40    43\n    32    35    38    41    44\n    33    36    39    42    45\nA(:,:,2,2) =\n    46    49    52    55    58\n    47    50    53    56    59\n    48    51    54    57    60"}}
%---
%[output:5fc2c260]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"dim","rows":1,"type":"double","value":[["2","4"]]}}
%---
%[output:136130e1]
%   data: {"dataType":"textualVariable","outputData":{"name":"A","value":"A(:,:,1,1) =\n     1    31\n     4    34\n     7    37\n    10    40\n    13    43\nA(:,:,2,1) =\n     2    32\n     5    35\n     8    38\n    11    41\n    14    44\nA(:,:,3,1) =\n     3    33\n     6    36\n     9    39\n    12    42\n    15    45\nA(:,:,1,2) =\n    16    46\n    19    49\n    22    52\n    25    55\n    28    58\nA(:,:,2,2) =\n    17    47\n    20    50\n    23    53\n    26    56\n    29    59\nA(:,:,3,2) =\n    18    48\n    21    51\n    24    54\n    27    57\n    30    60"}}
%---
%[output:9d0e0d64]
%   data: {"dataType":"matrix","outputData":{"columns":6,"name":"A","rows":10,"type":"double","value":[["1","2","3","16","17","18"],["4","5","6","19","20","21"],["7","8","9","22","23","24"],["10","11","12","25","26","27"],["13","14","15","28","29","30"],["31","32","33","46","47","48"],["34","35","36","49","50","51"],["37","38","39","52","53","54"],["40","41","42","55","56","57"],["43","44","45","58","59","60"]]}}
%---
%[output:4dc2339d]
%   data: {"dataType":"matrix","outputData":{"columns":6,"name":"A","rows":1,"type":"double","value":[["220","230","240","370","380","390"]]}}
%---
%[output:9516ccc8]
%   data: {"dataType":"textualVariable","outputData":{"name":"E","value":"E(:,:,1) =\n   220\n   230\n   240\nE(:,:,2) =\n   370\n   380\n   390"}}
%---
%[output:44ac3221]
%   data: {"dataType":"textualVariable","outputData":{"name":"A","value":"A(:,:,1,1) =\n   220\nA(:,:,2,1) =\n   230\nA(:,:,3,1) =\n   240\nA(:,:,1,2) =\n   370\nA(:,:,2,2) =\n   380\nA(:,:,3,2) =\n   390"}}
%---
%[output:32034551]
%   data: {"dataType":"textualVariable","outputData":{"name":"A","value":"A(:,:,1) =\n   220\n   230\n   240\nA(:,:,2) =\n   370\n   380\n   390"}}
%---
%[output:1bb8072a]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1"}}
%---
%[output:78b14a51]
%   data: {"dataType":"textualVariable","outputData":{"name":"A","value":"A(:,:,1,1,1) =\n     1     6\n     2     7\n     3     8\n     4     9\n     5    10\nA(:,:,2,1,1) =\n    11    16\n    12    17\n    13    18\n    14    19\n    15    20\nA(:,:,3,1,1) =\n    21    26\n    22    27\n    23    28\n    24    29\n    25    30\nA(:,:,4,1,1) =\n    31    36\n    32    37\n    33    38\n    34    39\n    35    40\nA(:,:,1,2,1) =\n    41    46\n    42    47\n    43    48\n    44    49\n    45    50\nA(:,:,2,2,1) =\n    51    56\n    52    57\n    53    58\n    54    59\n    55    60\nA(:,:,3,2,1) =\n    61    66\n    62    67\n    63    68\n    64    69\n    65    70\nA(:,:,4,2,1) =\n    71    76\n    72    77\n    73    78\n    74    79\n    75    80\nA(:,:,1,3,1) =\n    81    86\n    82    87\n    83    88\n    84    89\n    85    90\nA(:,:,2,3,1) =\n    91    96\n    92    97\n    93    98\n    94    99\n    95   100\nA(:,:,3,3,1) =\n   101   106\n   102   107\n   103   108\n   104   109\n   105   110\nA(:,:,4,3,1) =\n   111   116\n   112   117\n   113   118\n   114   119\n   115   120\nA(:,:,1,4,1) =\n   121   126\n   122   127\n   123   128\n   124   129\n   125   130\nA(:,:,2,4,1) =\n   131   136\n   132   137\n   133   138\n   134   139\n   135   140\nA(:,:,3,4,1) =\n   141   146\n   142   147\n   143   148\n   144   149\n   145   150\nA(:,:,4,4,1) =\n   151   156\n   152   157\n   153   158\n   154   159\n   155   160\nA(:,:,1,1,2) =\n   161   166\n   162   167\n   163   168\n   164   169\n   165   170\nA(:,:,2,1,2) =\n   171   176\n   172   177\n   173   178\n   174   179\n   175   180\nA(:,:,3,1,2) =\n   181   186\n   182   187\n   183   188\n   184   189\n   185   190\nA(:,:,4,1,2) =\n   191   196\n   192   197\n   193   198\n   194   199\n   195   200\nA(:,:,1,2,2) =\n   201   206\n   202   207\n   203   208\n   204   209\n   205   210\nA(:,:,2,2,2) =\n   211   216\n   212   217\n   213   218\n   214   219\n   215   220\nA(:,:,3,2,2) =\n   221   226\n   222   227\n   223   228\n   224   229\n   225   230\nA(:,:,4,2,2) =\n   231   236\n   232   237\n   233   238\n   234   239\n   235   240\nA(:,:,1,3,2) =\n   241   246\n   242   247\n   243   248\n   244   249\n   245   250\nA(:,:,2,3,2) =\n   251   256\n   252   257\n   253   258\n   254   259\n   255   260\nA(:,:,3,3,2) =\n   261   266\n   262   267\n   263   268\n   264   269\n   265   270\nA(:,:,4,3,2) =\n   271   276\n   272   277\n   273   278\n   274   279\n   275   280\nA(:,:,1,4,2) =\n   281   286\n   282   287\n   283   288\n   284   289\n   285   290\nA(:,:,2,4,2) =\n   291   296\n   292   297\n   293   298\n   294   299\n   295   300\nA(:,:,3,4,2) =\n   301   306\n   302   307\n   303   308\n   304   309\n   305   310\nA(:,:,4,4,2) =\n   311   316\n   312   317\n   313   318\n   314   319\n   315   320\nA(:,:,1,1,3) =\n   321   326\n   322   327\n   323   328\n   324   329\n   325   330\nA(:,:,2,1,3) =\n   331   336\n   332   337\n   333   338\n   334   339\n   335   340\nA(:,:,3,1,3) =\n   341   346\n   342   347\n   343   348\n   344   349\n   345   350\nA(:,:,4,1,3) =\n   351   356\n   352   357\n   353   358\n   354   359\n   355   360\nA(:,:,1,2,3) =\n   361   366\n   362   367\n   363   368\n   364   369\n   365   370\nA(:,:,2,2,3) =\n   371   376\n   372   377\n   373   378\n   374   379\n   375   380\nA(:,:,3,2,3) =\n   381   386\n   382   387\n   383   388\n   384   389\n   385   390\nA(:,:,4,2,3) =\n   391   396\n   392   397\n   393   398\n   394   399\n   395   400\nA(:,:,1,3,3) =\n   401   406\n   402   407\n   403   408\n   404   409\n   405   410\nA(:,:,2,3,3) =\n   411   416\n   412   417\n   413   418\n   414   419\n   415   420\nA(:,:,3,3,3) =\n   421   426\n   422   427\n   423   428\n   424   429\n   425   430\nA(:,:,4,3,3) =\n   431   436\n   432   437\n   433   438\n   434   439\n   435   440\nA(:,:,1,4,3) =\n   441   446\n   442   447\n   443   448\n   444   449\n   445   450\nA(:,:,2,4,3) =\n   451   456\n   452   457\n   453   458\n   454   459\n   455   460\nA(:,:,3,4,3) =\n   461   466\n   462   467\n   463   468\n   464   469\n   465   470\nA(:,:,4,4,3) =\n   471   476\n   472   477\n   473   478\n   474   479\n   475   480"}}
%---
%[output:3f60c1bd]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"dim","rows":1,"type":"double","value":[["3","4"]]}}
%---
%[output:4c5c63f8]
%   data: {"dataType":"matrix","outputData":{"columns":30,"name":"A","rows":16,"type":"double","value":[["1","2","3","4","5","6","7","8","9","10","161","162","163","164","165","166","167","168","169","170","321","322","323","324","325","326","327","328","329","330"],["11","12","13","14","15","16","17","18","19","20","171","172","173","174","175","176","177","178","179","180","331","332","333","334","335","336","337","338","339","340"],["21","22","23","24","25","26","27","28","29","30","181","182","183","184","185","186","187","188","189","190","341","342","343","344","345","346","347","348","349","350"],["31","32","33","34","35","36","37","38","39","40","191","192","193","194","195","196","197","198","199","200","351","352","353","354","355","356","357","358","359","360"],["41","42","43","44","45","46","47","48","49","50","201","202","203","204","205","206","207","208","209","210","361","362","363","364","365","366","367","368","369","370"],["51","52","53","54","55","56","57","58","59","60","211","212","213","214","215","216","217","218","219","220","371","372","373","374","375","376","377","378","379","380"],["61","62","63","64","65","66","67","68","69","70","221","222","223","224","225","226","227","228","229","230","381","382","383","384","385","386","387","388","389","390"],["71","72","73","74","75","76","77","78","79","80","231","232","233","234","235","236","237","238","239","240","391","392","393","394","395","396","397","398","399","400"],["81","82","83","84","85","86","87","88","89","90","241","242","243","244","245","246","247","248","249","250","401","402","403","404","405","406","407","408","409","410"],["91","92","93","94","95","96","97","98","99","100","251","252","253","254","255","256","257","258","259","260","411","412","413","414","415","416","417","418","419","420"],["101","102","103","104","105","106","107","108","109","110","261","262","263","264","265","266","267","268","269","270","421","422","423","424","425","426","427","428","429","430"],["111","112","113","114","115","116","117","118","119","120","271","272","273","274","275","276","277","278","279","280","431","432","433","434","435","436","437","438","439","440"],["121","122","123","124","125","126","127","128","129","130","281","282","283","284","285","286","287","288","289","290","441","442","443","444","445","446","447","448","449","450"],["131","132","133","134","135","136","137","138","139","140","291","292","293","294","295","296","297","298","299","300","451","452","453","454","455","456","457","458","459","460"],["141","142","143","144","145","146","147","148","149","150","301","302","303","304","305","306","307","308","309","310","461","462","463","464","465","466","467","468","469","470"]]}}
%---
%[output:3a6d83a8]
%   data: {"dataType":"matrix","outputData":{"columns":5,"name":"dimOrder","rows":1,"type":"double","value":[["3","4","1","2","5"]]}}
%---
%[output:32d22fab]
%   data: {"dataType":"matrix","outputData":{"columns":5,"name":"Bsz","rows":1,"type":"double","value":[["5","2","1","1","3"]]}}
%---
%[output:2720b3f1]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1"}}
%---
