using UnityEngine;

namespace QuadTree
{
    public class QuadTreeNode
    {
        /// <summary>
        /// 边界
        /// </summary>
        public Bounds Bounds { get; private set; }

        /// <summary>
        /// 层级
        /// </summary>
        public int LODLevel { get; private set; }

        /// <summary>
        /// 子节点
        /// </summary>
        public QuadTreeNode[] Children { get; private set; }

        /// <summary>
        /// 是否有子节点
        /// </summary>
        public bool HasChildren { get; private set; }

        /// <summary>
        /// 层级阈值
        /// </summary>
        private float[] LODThresholds { get; set; }

        /// <summary>
        /// 最大深度
        /// </summary>
        private int MaxDepth { get; set; }

        public QuadTreeNode(Bounds bounds, int lodLevel, float[] lodThreshold, int maxDepth)
        {
            Bounds = bounds;
            LODLevel = lodLevel;
            LODThresholds = lodThreshold;
            MaxDepth = maxDepth;
            Children = new QuadTreeNode[4];
        }

        /// <summary>
        /// 判断节点是否在视锥内
        /// </summary>
        /// <param name="frustumPlanes"></param>
        /// <returns></returns>
        public bool IsInFrustum(Plane[] frustumPlanes)
        {
            return GeometryUtility.TestPlanesAABB(frustumPlanes, Bounds);
        }

        /// <summary>
        /// 更新节点
        /// </summary>
        /// <param name="cameraPos"></param>
        /// <param name="aoi"></param>
        public void Update(Vector3 cameraPos, Bounds aoi)
        {
            var distance = Vector3.Distance(cameraPos, Bounds.center);
            var needSplit = ShouldSplit(distance, aoi);
            if (needSplit && !HasChildren && LODLevel < MaxDepth)
            {
                Split();
                foreach (var child in Children)
                {
                    child.Update(cameraPos, aoi);
                }
            }
            else if (!needSplit && HasChildren)
            {
                Merge();
            }
        }

        /// <summary>
        /// 判断是否需要分割
        /// </summary>
        /// <param name="distance"></param>
        /// <param name="aoi"></param>
        /// <returns></returns>
        private bool ShouldSplit(float distance, Bounds aoi)
        {
            return distance > LODThresholds[LODLevel] && LODLevel < MaxDepth;
        }

        private void Split()
        {
            var size = Bounds.size / 2;
            var center = Bounds.center;
            Children[0] =
                new QuadTreeNode(new Bounds(center + new Vector3(-size.x / 2, 0, -size.z / 2), size),
                    LODLevel + 1, LODThresholds, MaxDepth);
            Children[1] =
                new QuadTreeNode(new Bounds(center + new Vector3(size.x / 2, 0, -size.z / 2), size),
                    LODLevel + 1, LODThresholds, MaxDepth);
            Children[2] =
                new QuadTreeNode(new Bounds(center + new Vector3(-size.x / 2, 0, size.z / 2), size),
                    LODLevel + 1, LODThresholds, MaxDepth);
            Children[3] =
                new QuadTreeNode(new Bounds(center + new Vector3(size.x / 2, 0, size.z / 2), size),
                    LODLevel + 1, LODThresholds, MaxDepth);
            HasChildren = true;
        }

        private void Merge()
        {
            HasChildren = false;
            Children = new QuadTreeNode[4];
        }
    }
}