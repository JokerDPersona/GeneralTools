using System;

namespace QuadTree
{
    using UnityEngine;
    using System.Runtime.InteropServices;

    /// <summary>
    /// GPU剔除系统
    /// </summary>
    public class GPUCullingSystem : MonoBehaviour
    {
        [Header("Rendering")] public Mesh terrainMesh;
        public Material terrainMaterial;
        [Header("Optimization")] public float updateInterval = 0.2f;

        public QuadTreeManager QuadTreeManager { get; private set; }

        private static readonly int ViewProjMatrix = Shader.PropertyToID("_ViewProjMatrix");
        private static readonly int Nodes = Shader.PropertyToID("_Nodes");
        private static readonly int VisibleIndices = Shader.PropertyToID("_VisibleIndices");
        private static readonly int NodeCount = Shader.PropertyToID("nodeCount");
        private static readonly int CameraPos = Shader.PropertyToID("_CameraPos");
        [Header("Compute Shaders")] public ComputeShader cullingShader;

        private int _cullingKernel;

        // 计算缓冲区
        private ComputeBuffer _nodeBuffer;
        private ComputeBuffer _visibleBuffer;
        private ComputeBuffer _argsBuffer;

        private float _lastUpdateTime;
        private bool _buffersInitialized;

        // 间接绘制参数
        private readonly uint[] _args = new uint[5] { 0, 0, 0, 0, 0 };

        // 节点数据结构
        struct NodeData
        {
            public Vector3 center;
            public Vector3 size;
            public int lodLevel;
        }

        void Start()
        {
            InitializeBuffers();
            _cullingKernel = cullingShader.FindKernel("FrustumCulling");
            QuadTreeManager = GetComponent<QuadTreeManager>();
            _buffersInitialized = true;
        }

        void InitializeBuffers()
        {
            // 节点缓冲区（可容纳100万个节点）
            _nodeBuffer = new ComputeBuffer(1000000,
                Marshal.SizeOf(typeof(NodeData)),
                ComputeBufferType.Structured);

            // 可见索引缓冲区
            _visibleBuffer = new ComputeBuffer(1000000, sizeof(int),
                ComputeBufferType.Append);

            // 间接参数缓冲区
            _argsBuffer = new ComputeBuffer(1, _args.Length * sizeof(uint),
                ComputeBufferType.IndirectArguments);

            // 初始化间接绘制参数
            _args[0] = terrainMesh != null ? terrainMesh.GetIndexCount(0) : 0;
            _args[1] = 0; // 实例数量
            _args[2] = terrainMesh != null ? terrainMesh.GetIndexStart(0) : 0;
            _args[3] = terrainMesh != null ? terrainMesh.GetBaseVertex(0) : 0;
            _argsBuffer.SetData(_args);
        }

        void Update()
        {
            if (!_buffersInitialized)
            {
                return;
            }

            // 按照时间间隔更新节点数据
            if (Time.time - _lastUpdateTime > updateInterval)
            {
                // 更新节点缓冲区
                UpdateNodeBuffer();
                _lastUpdateTime = Time.time;
            }

            DispatchGPUCulling();
            RenderTerrain();
        }

        void UpdateNodeBuffer()
        {
            QuadTreeManager treeManager = GetComponent<QuadTreeManager>();
            int nodeCount = treeManager.leafNodes.Count;
            // 动态调整缓冲区大小
            if (_nodeBuffer.count < nodeCount)
            {
                _nodeBuffer.Release();
                _nodeBuffer = new ComputeBuffer(Mathf.Max(nodeCount * 2, 1), Marshal.SizeOf(typeof(NodeData)),
                    ComputeBufferType.Structured);
            }

            NodeData[] nodeArray = new NodeData[treeManager.leafNodes.Count];

            for (int i = 0; i < treeManager.leafNodes.Count; i++)
            {
                nodeArray[i] = new NodeData
                {
                    center = treeManager.leafNodes[i].bounds.center,
                    size = treeManager.leafNodes[i].bounds.size,
                    lodLevel = treeManager.leafNodes[i].lodLevel
                };
            }

            _nodeBuffer.SetData(nodeArray);
            cullingShader.SetInt(NodeCount, treeManager.leafNodes.Count);
        }

        void DispatchGPUCulling()
        {
            var nodeCount = QuadTreeManager.leafNodes.Count;
            if (nodeCount == 0)
            {
                return;
            }

            // 重置可见性缓冲区计数
            _visibleBuffer.SetCounterValue(0);

            // 设置着色器参数
            if (Camera.main != null)
            {
                Matrix4x4 vpMatrix = Camera.main.projectionMatrix * Camera.main.worldToCameraMatrix;
                cullingShader.SetMatrix(ViewProjMatrix, vpMatrix);
                cullingShader.SetVector(CameraPos, Camera.main.transform.position);
            }

            cullingShader.SetBuffer(_cullingKernel, Nodes, _nodeBuffer);
            cullingShader.SetBuffer(_cullingKernel, VisibleIndices, _visibleBuffer);

            // 执行计算着色器
            int threadGroupsX = Mathf.CeilToInt(nodeCount / 64.0f);
            // 保证至少有一个线程组
            threadGroupsX = Mathf.Max(1, threadGroupsX);
            cullingShader.Dispatch(_cullingKernel, threadGroupsX, 1, 1);
        }

        void RenderTerrain()
        {
            var nodeCount = QuadTreeManager.leafNodes.Count;
            if (nodeCount == 0)
            {
                return;
            }

            // 设置材质参数
            terrainMaterial.SetBuffer("_NodesBuffer", _nodeBuffer);
            terrainMaterial.SetBuffer("_VisibleIndicesBuffer", _visibleBuffer);

            // 获取可见的实例数量
            ComputeBuffer.CopyCount(_visibleBuffer, _argsBuffer, 4); // 将计数复制到argsBuffer的第4个uint位置(实例数量)

            // 间接绘制
            Graphics.DrawMeshInstancedIndirect(
                terrainMesh,
                0,
                terrainMaterial,
                new Bounds(Vector3.zero, QuadTreeManager.terrainSize),
                _argsBuffer
            );
        }

        void OnDestroy()
        {
            if (_nodeBuffer != null) _nodeBuffer.Release();
            if (_visibleBuffer != null) _visibleBuffer.Release();
            if (_argsBuffer != null) _argsBuffer.Release();
        }

        // /// <summary>
        // /// 验证实例化数据是否正常传递
        // /// </summary>
        // private void OnDrawGizmos()
        // {
        //     if (!Application.isPlaying || _visibleBuffer == null) return;
        //
        //     // 创建临时缓冲区来获取可见索引
        //     uint[] visibleIndices = new uint[_visibleBuffer.count];
        //     _visibleBuffer.GetData(visibleIndices);
        //
        //     NodeData[] nodes = new NodeData[_nodeBuffer.count];
        //     _nodeBuffer.GetData(nodes);
        //
        //     foreach (uint idx in visibleIndices)
        //     {
        //         if (idx < nodes.Length)
        //         {
        //             Gizmos.color = Color.green;
        //             Gizmos.DrawWireCube(nodes[idx].center, nodes[idx].size);
        //         }
        //     }
        // }
    }
}