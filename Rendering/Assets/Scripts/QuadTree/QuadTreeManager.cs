using System.Collections.Generic;
using Unity.Collections;
using Unity.Jobs;
using UnityEngine;
using UnityEngine;
using System.Collections.Generic;

namespace QuadTree
{
    public struct FrustumCullingJob : IJobParallelFor
    {
        [ReadOnly] public NativeArray<Bounds> NodeBounds;
        [ReadOnly] public NativeArray<Plane> FrustumPlanes;
        public NativeArray<bool> VisibleResults;

        public void Execute(int index)
        {
            Bounds bounds = NodeBounds[index];
            for (int i = 0; i < FrustumPlanes.Length; i++)
            {
                Plane plane = FrustumPlanes[i];
                Vector3 positiveVertex = bounds.center;
                if (plane.normal.x >= 0)
                    positiveVertex.x += bounds.extents.x;
                else
                    positiveVertex.x -= bounds.extents.x;

                if (plane.normal.y >= 0)
                    positiveVertex.y += bounds.extents.y;
                else
                    positiveVertex.y -= bounds.extents.y;

                if (plane.normal.z >= 0)
                    positiveVertex.z += bounds.extents.z;
                else
                    positiveVertex.z -= bounds.extents.z;

                if (plane.GetDistanceToPoint(positiveVertex) < 0)
                {
                    VisibleResults[index] = false;
                    return;
                }
            }

            VisibleResults[index] = true;
        }
    }


    /// <summary>
    /// 四叉树管理系统
    /// </summary>
    public class QuadTreeManager : MonoBehaviour
    {
        [Header("Tree Settings")] [SerializeField]
        public Vector2 terrainSize = new Vector2(2000, 2000);

        public int maxDepth = 6;
        public float[] lodDistances = { 500f, 200f, 100f, 50f };

        [Header("AOI Settings")] [SerializeField]
        public Vector2 aoiSize = new Vector2(300f, 300f);

        public QuadTreeNode root;
        [SerializeField] public Transform cameraTransform;

        // 所有叶子节点列表
        [HideInInspector] public List<QuadTreeNode> leafNodes = new List<QuadTreeNode>();

        void Start()
        {
            InitializeTree();
        }

        void InitializeTree()
        {
            Bounds rootBounds = new Bounds(
                Vector3.zero,
                new Vector3(terrainSize.x, 0, terrainSize.y));

            root = new QuadTreeNode(rootBounds, 0, lodDistances, maxDepth);
        }

        void Update()
        {
            UpdateTree();
            CollectLeafNodes(root);
        }

        void UpdateTree()
        {
            Bounds aoi = new Bounds(
                cameraTransform.position,
                new Vector3(aoiSize.x, 100f, aoiSize.y));

            root.Update(cameraTransform.position, aoi);
        }

        void CollectLeafNodes(QuadTreeNode node)
        {
            if (node.hasChildren)
            {
                foreach (var child in node.children)
                    CollectLeafNodes(child);
            }
            else
            {
                if (!leafNodes.Contains(node))
                    leafNodes.Add(node);
            }
        }
    }
}