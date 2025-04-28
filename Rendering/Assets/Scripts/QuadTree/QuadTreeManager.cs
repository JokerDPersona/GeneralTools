using System.Collections.Generic;
using Unity.Collections;
using Unity.Jobs;
using UnityEngine;

namespace QuadTree
{
    public struct FrustumCullingJob : IJobParallelFor
    {
        [ReadOnly] public NativeArray<Bounds> NodeBounds;
        [ReadOnly] public NativeArray<Plane> FrustumPlanes;
        public NativeArray<bool> VisibleResults;

        public void Execute(int index)
        {
            VisibleResults[index] = GeometryUtility.TestPlanesAABB(FrustumPlanes.ToArray(), NodeBounds[index]);
        }
    }

    public class QuadTreeManager : MonoBehaviour
    {
        /// <summary>
        /// 四叉树根结点
        /// </summary>
        public QuadTreeNode Root { get; private set; }

        // 四叉树更新控制参数
        public float SplitMargin { get; private set; } = 1.2f;
        public float MergeThreshold { get; private set; } = 0.8f;
        public float UpdateInterval { get; private set; } = 0.1f;
        private float _lastUpdateTIme;

        private List<Matrix4x4>[] _lodInstances;
        private Camera _mainCamera;
        private readonly Plane[] _frustumPlanes = new Plane[6];

        private NativeArray<Plane> _nativeFrustumPlanes;
        private NativeArray<Bounds> _nodeBounds;
        private NativeArray<bool> _visibleResults;
        private JobHandle _cullingJobHandle;

        private const int MaxNodeCount = 1000;


        void Start()
        {
            // 初始化NativeArray
            _nativeFrustumPlanes = new NativeArray<Plane>(6, Allocator.Persistent);
            _nodeBounds = new NativeArray<Bounds>(MaxNodeCount, Allocator.Persistent);
            _visibleResults = new NativeArray<bool>(MaxNodeCount, Allocator.Persistent);
        }

        void Update()
        {
            // 准备数据
            _nativeFrustumPlanes.CopyFrom(_frustumPlanes);

            // 调度job
            var job = new FrustumCullingJob();
            job.NodeBounds = _nodeBounds;
            job.FrustumPlanes = _nativeFrustumPlanes;
            job.VisibleResults = _visibleResults;

            _cullingJobHandle = job.Schedule(_nodeBounds.Length, 64);
        }

        void LateUpdate()
        {
            _cullingJobHandle.Complete();

            // 处理可见性结果
            var length = _visibleResults.Length;
            for (var i = 0; i < length; i++)
            {
                if (_visibleResults[i])
                {
                    // 添加到渲染列表
                    Debug.Log("Add Instance");
                }
            }
        }

        private void OnDestroy()
        {
            _nativeFrustumPlanes.Dispose();
            _nodeBounds.Dispose();
            _visibleResults.Dispose();
        }

        public void UpdateQuadTree()
        {
            if (Time.time - _lastUpdateTIme < UpdateInterval)
            {
                return;
            }
        }
    }
}