function trip = shortestTrip(x,y)
    arguments
        x (:,1) double
        y (:,1) double
    end
    nStops = numel(x);
    % Indices
    idxs = nchoosek(1:nStops,2);
    % Calculate all the trip distances, assuming that the earth is flat in order to use the Pythagorean rule.
    dist = hypot(y(idxs(:,1)) - y(idxs(:,2)), ...
                 x(idxs(:,1)) - x(idxs(:,2)));
    lendist = length(dist);
    
    % Create graph
    G = graph(idxs(:,1),idxs(:,2));
    
    % Create problem
    tsp = optimproblem;
    trips = optimvar('trips',lendist,1,'Type','integer','LowerBound',0,'UpperBound',1);
    % Include the objective function in the problem.
    tsp.Objective = dist'*trips;
    
    % Add constraints
    constr2trips = optimconstr(nStops,1);
    for stop = 1:nStops
        whichIdxs = outedges(G,stop); % Identify trips associated with the stop
        constr2trips(stop) = sum(trips(whichIdxs)) == 2;
    end
    tsp.Constraints.constr2trips = constr2trips;
    
    % Solve
    opts = optimoptions('intlinprog','Display','off');
    tspsol = solve(tsp,'options',opts);
    
    % Visualize
    tspsol.trips = logical(round(tspsol.trips));
    Gsol = graph(idxs(tspsol.trips,1),idxs(tspsol.trips,2),[],numnodes(G));
    
    % Eliminate subtours
    tourIdxs = conncomp(Gsol);
    numtours = max(tourIdxs); % Number of subtours
    %
    % Index of added constraints for subtours
    k = 1;
    while numtours > 1 % Repeat until there is just one subtour
        % Add the subtour constraints
        for ii = 1:numtours
            inSubTour = (tourIdxs == ii); % Edges in current subtour
            a = all(inSubTour(idxs),2); % Complete graph indices with both ends in subtour
            constrname = "subtourconstr" + num2str(k);
            tsp.Constraints.(constrname) = sum(trips(a)) <= (nnz(inSubTour) - 1);
            k = k + 1;        
        end
        
        % Try to optimize again
        tspsol = solve(tsp,'options',opts);
        tspsol.trips = logical(round(tspsol.trips));
        Gsol = graph(idxs(tspsol.trips,1),idxs(tspsol.trips,2),[],numnodes(G));
     
        % How many subtours this time?
        tourIdxs = conncomp(Gsol);
        numtours = max(tourIdxs); % Number of subtours
        fprintf('# of subtours: %d\n',numtours)    
    end
    cycles = allcycles(Gsol);
    trip = cycles{1}';
end

