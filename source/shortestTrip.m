function trip = shortestTrip(x,y)
    % SHORTESTTRIP Finds the shortest trip between cities defined by the 
    % x and y coordinates and returns the array of indices of cities to visit. 
    % The array is ordered such that the first city (x(1),y(1)) is always
    % visited first, and the index of the second visited city is the lower 
    % of the two possible indices.
    % based on https://www.mathworks.com/help/gads/custom-data-type-optimization-using-ga.html
    arguments
        x (:,1) double
        y (:,1) double
    end
    nStops = numel(x);
    % Indices
    distances = zeros(nStops);
    for count1=1:nStops
        for count2=1:count1
            x1 = x(count1);
            y1 = y(count1);
            x2 = x(count2);
            y2 = y(count2);
            distances(count1,count2)=sqrt((x1-x2)^2+(y1-y2)^2);
            distances(count2,count1)=distances(count1,count2);
        end
    end
       
    % |ga| will call our fitness function with just one argument |x|, but our
    % fitness function has two arguments: |x|, |distances|. We can use an
    % anonymous function to capture the values of the additional argument, the
    % distances matrix. We create a function handle |FitnessFcn| to an
    % anonymous function that takes one input |x|, but calls
    % |traveling_salesman_fitness| with |x|, and distances. The variable,
    % distances has a value when the function handle |FitnessFcn| is created,
    % so these values are captured by the anonymous function.
    %distances defined earlier
    FitnessFcn = @(x) traveling_salesman_fitness(x,distances);
    
    % Genetic Algorithm Options Setup
    % First, we will create an options container to indicate a custom data type
    % and the population range.
    options = optimoptions(@ga, 'PopulationType', 'custom','InitialPopulationRange', ...
                                [1;nStops]);

    % We choose the custom creation, crossover, and mutation functions
    % that we have created, as well as setting some stopping conditions.
    options = optimoptions(options,'CreationFcn',@create_permutations, ...
                            'CrossoverFcn',@crossover_permutation, ...
                            'MutationFcn',@mutate_permutation, ...
                            'MaxGenerations',10000,'PopulationSize',nStops, ...
                            'FunctionTolerance',1e-9,'MaxStallGenerations',200, ...
                            'UseVectorized',true,'UseParallel',false);

    numberOfVariables = nStops;
    res = ga(FitnessFcn,numberOfVariables,[],[],[],[],[],[],[],options);
    trip = res{1};
    trip = orderIndices(trip);
end

function trip=orderIndices(trip)
    nCities = length(trip);
    if (nCities>1)
        city1 = find(trip==1);
        trip = circshift(trip,1-city1);
        nextCity = trip(2);
        lastCity = trip(nCities);
        if (lastCity<nextCity)
            trip = trip(nCities:-1:1);
            trip = circshift(trip,1);
        end
    end
end

function pop = create_permutations(NVARS,FitnessFcn,options)
    %CREATE_PERMUTATIONS Creates a population of permutations.
    %   POP = CREATE_PERMUTATION(NVARS,FITNESSFCN,OPTIONS) creates a population
    %  of permutations POP each with a length of NVARS. 
    %
    %   The arguments to the function are 
    %     NVARS: Number of variables 
    %     FITNESSFCN: Fitness function 
    %     OPTIONS: Options structure used by the GA

    %   Copyright 2004-2007 The MathWorks, Inc.

    totalPopulationSize = sum(options.PopulationSize);
    n = NVARS;
    pop = cell(totalPopulationSize,1);
    for i = 1:totalPopulationSize
        pop{i} = randperm(n); 
    end
end

function xoverKids  = crossover_permutation(parents,options,NVARS, ...
    FitnessFcn,thisScore,thisPopulation)
    %   CROSSOVER_PERMUTATION Custom crossover function for traveling salesman.
    %   XOVERKIDS = CROSSOVER_PERMUTATION(PARENTS,OPTIONS,NVARS, ...
    %   FITNESSFCN,THISSCORE,THISPOPULATION) crossovers PARENTS to produce
    %   the children XOVERKIDS.
    %
    %   The arguments to the function are 
    %     PARENTS: Parents chosen by the selection function
    %     OPTIONS: Options created from OPTIMOPTIONS
    %     NVARS: Number of variables 
    %     FITNESSFCN: Fitness function 
    %     STATE: State structure used by the GA solver 
    %     THISSCORE: Vector of scores of the current population 
    %     THISPOPULATION: Matrix of individuals in the current population

    %   Copyright 2004-2015 The MathWorks, Inc. 

    nKids = length(parents)/2;
    xoverKids = cell(nKids,1); % Normally zeros(nKids,NVARS);
    index = 1;

    for i=1:nKids
        % here is where the special knowledge that the population is a cell
        % array is used. Normally, this would be thisPopulation(parents(index),:);
        parent = thisPopulation{parents(index)};
        index = index + 2;

        % Flip a section of parent1.
        p1 = ceil((length(parent) -1) * rand);
        p2 = p1 + ceil((length(parent) - p1- 1) * rand);
        child = parent;
        child(p1:p2) = fliplr(child(p1:p2));
        xoverKids{i} = child; % Normally, xoverKids(i,:);
    end
end

function mutationChildren = mutate_permutation(parents ,options,NVARS, ...
    FitnessFcn, state, thisScore,thisPopulation,mutationRate)
    %   MUTATE_PERMUTATION Custom mutation function for traveling salesman.
    %   MUTATIONCHILDREN = MUTATE_PERMUTATION(PARENTS,OPTIONS,NVARS, ...
    %   FITNESSFCN,STATE,THISSCORE,THISPOPULATION,MUTATIONRATE) mutate the
    %   PARENTS to produce mutated children MUTATIONCHILDREN.
    %
    %   The arguments to the function are 
    %     PARENTS: Parents chosen by the selection function
    %     OPTIONS: Options created from OPTIMOPTIONS
    %     NVARS: Number of variables 
    %     FITNESSFCN: Fitness function 
    %     STATE: State structure used by the GA solver 
    %     THISSCORE: Vector of scores of the current population 
    %     THISPOPULATION: Matrix of individuals in the current population
    %     MUTATIONRATE: Rate of mutation

    %   Copyright 2004-2015 The MathWorks, Inc.

    % Here we swap two elements of the permutation
    mutationChildren = cell(length(parents),1);% Normally zeros(length(parents),NVARS);
    for i=1:length(parents)
        parent = thisPopulation{parents(i)}; % Normally thisPopulation(parents(i),:)
        p = ceil(length(parent) * rand(1,2));
        child = parent;
        child(p(1)) = parent(p(2));
        child(p(2)) = parent(p(1));
        mutationChildren{i} = child; % Normally mutationChildren(i,:)
    end
end

function scores = traveling_salesman_fitness(x,distances)
    %TRAVELING_SALESMAN_FITNESS  Custom fitness function for TSP. 
    %   SCORES = TRAVELING_SALESMAN_FITNESS(X,DISTANCES) Calculate the fitness 
    %   of an individual. The fitness is the total distance traveled for an
    %   ordered set of cities in X. DISTANCE(A,B) is the distance from the city
    %   A to the city B.

    %   Copyright 2004-2007 The MathWorks, Inc.

    scores = zeros(size(x,1),1);
    for j = 1:size(x,1)
        % here is where the special knowledge that the population is a cell
        % array is used. Normally, this would be pop(j,:);
        p = x{j}; 
        f = distances(p(end),p(1));
        for i = 2:length(p)
            f = f + distances(p(i-1),p(i));
        end
        scores(j) = f;
    end
end