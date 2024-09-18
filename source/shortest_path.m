function pathLength = shortest_path(adjMatrix, startIdx, endIdx) %#codegen
% SHORTEST_PATH - Finds length of shortest path between nodes in a graph
% 
%   OUT = SHORTEST_PATH(ADJMTX, STARTIDX, ENDIDX) Takes a graph represented by
%   its adjacency matrix ADJMTX along with two node STARTIDX, ENDIDX as
%   inputs and returns a integer containing the length of the shortest path
%   from STARTIDX to ENDIDX in the graph.

% Copyright 2021 The MathWorks, Inc.


    %% Validy testing on the inputs 
    % This code should never throw an error and instead should return
    % error codes for invlid inputs.
    ErrorCode = 0;
    pathLength = -1;

    % comment

    % Check the validity of the adjacency matrix
    if (~isAdjMatrixValid(adjMatrix))
        ErrorCode = -9;
    end

    % Check the validity of the startIdx
    if ~isNodeValid(startIdx)
        ErrorCode = -19;
    end

    % Check the validity of the endIdx
    if ~isNodeValid(endIdx)
        ErrorCode = -29;
    end

    [nodeCnt, n] = size(adjMatrix);

    % Start or end node is too large
    if startIdx > nodeCnt || endIdx > nodeCnt
        ErrorCode = -99;
    end

    % Start or end node is too small
    if startIdx < 1 || endIdx < 1
        ErrorCode = -199;
    end

    if (ErrorCode<0)
        pathLength = ErrorCode;
        return;
    end

    %% Self-loop path is always 0
    if startIdx  == endIdx
        pathLength = 0;
        return;
    end
    
    %% Dijkstra's Algorithm 
    % Dijkstra's Algorithm is used to iteratively explore the graph breadth
    % first and update the shortest path until we reach the end node.

    % Initialization
    max = realmax;
    visited = false(1, nodeCnt);

    % The distance vector maintains the current known shortest path from 
    % the start node to every node.  As nodes are processed one by one 
    % the distance vestor is updated
    distance = repmat(max, 1, nodeCnt);
    distance(startIdx) = 0;

    for iterStep = 1:nodeCnt
        % At each iteration identify the current node to process that 
        % is not yet visited and has the smallest distance from the start.
        % This breadth first search ensures that we will always reach nodes
        % by the shortest possible path.
        min = max;
        nodeIdx = -1;
        for v = 1:n
            if ~visited(v) && distance(v) <= min
                min = distance(v);
                nodeIdx = v;
            end
        end

        % Stop iterating when the current distance is maximum because
        % this indicates no remaining nodes are reachable
        if (min==max)
            return;
        end
        
        % Mark the current node visited and check if this is end index
        visited(nodeIdx) = true;
        if nodeIdx == endIdx
            pathLength = distance(nodeIdx);

            if (pathLength==realmax)
                % No path exists so set distance to -1;
                pathLength = -1;
            end
            return;
        end
                
        % Update distances of unvisited nodes adjacent to the current node 
        for v = 1:nodeCnt
            if(~visited(v) && adjMatrix(nodeIdx, v) ~= 0 && distance(nodeIdx) ~= max)
                distVal = distance(nodeIdx) + adjMatrix(nodeIdx, v);
                if distVal < distance(v)
                    distance(v) = distVal;
                end
            end
        end
    end
end

function out = isNodeValid(node)
    % For full coverage we need to create negative tests that make each
    % successively make each validity condition false
    if(isscalar(node) && isnumeric(node) && ~isinf(node) && floor(node) == node)
        out = true;
    else
        out = false;
    end
end

function out = isAdjMatrixValid(adjMatrix)
    % need to be a square matrix with only 0, 1, or realmax entries. 
    [m, n] = size(adjMatrix);

    % For full coverage we need to create negative tests that make each
    % successively make each validity condition false
    if (m==n) && isempty(find((adjMatrix ~= 0) & (adjMatrix ~= 1), 1))
        out = true;
    else
        out = false;
    end
end