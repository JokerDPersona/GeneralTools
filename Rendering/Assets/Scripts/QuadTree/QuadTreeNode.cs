using UnityEngine;

namespace QuadTree
{
    using UnityEngine;

    /// <summary>
    /// 四叉树节点类
    /// </summary>
    public class QuadTreeNode
    {
        // 节点边界
        public Bounds bounds;

        // 当前LOD层级
        public int lodLevel;

        // 子节点数组
        public QuadTreeNode[] children;

        // 是否包含子节点
        public bool hasChildren;

        // LOD距离阈值
        private float[] lodDistances;

        // 最大细分深度
        private int maxDepth;

        // 分裂安全系数
        private const float SplitMargin = 1.25f;

        public QuadTreeNode(Bounds bounds, int lodLevel, float[] distances, int maxDepth)
        {
            this.bounds = bounds;
            this.lodLevel = lodLevel;
            this.lodDistances = distances;
            this.maxDepth = maxDepth;
            children = new QuadTreeNode[4];
        }

        /// <summary>
        /// 更新节点状态
        /// </summary>
        public void Update(Vector3 cameraPos, Bounds aoi)
        {
            // 计算到摄像机的距离
            float distance = Vector3.Distance(cameraPos, bounds.center);

            // 判断是否需要分裂
            if (ShouldSplit(distance, aoi) && !hasChildren && lodLevel < maxDepth)
            {
                Split();
                foreach (var child in children)
                    child.Update(cameraPos, aoi);
            }
            // 判断是否需要合并
            else if (ShouldMerge(distance, aoi) && hasChildren)
            {
                Merge();
            }
        }

        private bool ShouldSplit(float distance, Bounds aoi)
        {
            // 分裂条件：在AOI内且距离小于阈值
            return aoi.Intersects(bounds) &&
                   distance < lodDistances[lodLevel] * SplitMargin;
        }

        private bool ShouldMerge(float distance, Bounds aoi)
        {
            // 合并条件：在AOI外或距离超过阈值
            return !aoi.Intersects(bounds) ||
                   distance > lodDistances[lodLevel] * 1.5f;
        }

        private void Split()
        {
            Vector3 halfSize = bounds.size * 0.5f;
            Vector3 center = bounds.center;

            // 创建四个子节点
            for (var i = 0; i < 4; i++)
            {
                children[i] = new QuadTreeNode(
                    new Bounds(new Vector3(center.x - halfSize.x / 2, 0, center.z - halfSize.z / 2), halfSize),
                    lodLevel + 1, lodDistances, maxDepth);
            }

            hasChildren = true;
        }

        private void Merge()
        {
            hasChildren = false;
            children = new QuadTreeNode[4];
        }
    }
}