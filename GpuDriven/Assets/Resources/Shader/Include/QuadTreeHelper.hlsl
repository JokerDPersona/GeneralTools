#ifndef QUAD_TREE_HELPER
#define QUAD_TREE_HELPER

#define DEFAULT_QUAD_TREE_MAX_LEVEL 16   

float GetNodeSize(float4 quadTreeLodParams[DEFAULT_QUAD_TREE_MAX_LEVEL],int lod)
{
    return quadTreeLodParams[lod].x;
}

int GetNodeCount(float4 quadTreeLodParams[DEFAULT_QUAD_TREE_MAX_LEVEL],int lod)
{
    return round(quadTreeLodParams[lod].y);
}

int GetNodePerCount(float4 quadTreeLodParams[DEFAULT_QUAD_TREE_MAX_LEVEL],int lod)
{
    return round(quadTreeLodParams[lod].z);
}

int GetNodeIDOffsetOfLOD(float4 quadTreeLodParams[DEFAULT_QUAD_TREE_MAX_LEVEL],int lod)
{
    return round(quadTreeLodParams[lod].w);
}

int GetLocalNodeId(float4 quadTreeLodParams[DEFAULT_QUAD_TREE_MAX_LEVEL],int2 nodeLoc,int lod)
{
    return round(quadTreeLodParams[lod].w) + (nodeLoc.y * GetNodeCount(quadTreeLodParams, lod)) + nodeLoc.x;
}

float2 GetNodePosByRootNodeCenterPos(float2 rootNodeCenterPos,float4 quadTreeLodParams[DEFAULT_QUAD_TREE_MAX_LEVEL],int2 nodeLoc, int lod)
{
    float nodeMeterSize = GetNodeSize(quadTreeLodParams, lod);
    int nodeCount = GetNodeCount(quadTreeLodParams, lod);
    float2 nodePositionWS = ((float2)nodeLoc.xy - ((nodeCount - 1) * 0.5f)) * nodeMeterSize;
    nodePositionWS += rootNodeCenterPos;
    return nodePositionWS;
}

float2 GetNodePosByRootNodeLeftButtomPos(float2 rootNodeLeftButtomPos,float4 quadTreeLodParams[DEFAULT_QUAD_TREE_MAX_LEVEL],int2 nodeLoc, int lod)
{
    float nodeMeterSize = GetNodeSize(quadTreeLodParams, lod);
    float2 nodePositionWS = ((float2)nodeLoc.xy + 0.5f.xx) * nodeMeterSize;
    nodePositionWS += rootNodeLeftButtomPos;
    return nodePositionWS;
}



#endif