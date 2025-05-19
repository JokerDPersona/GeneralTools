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

        private int cullingKernel;

        // 计算缓冲区
        private ComputeBuffer nodeBuffer;
        private ComputeBuffer visibleBuffer;
        private ComputeBuffer argsBuffer;

        private float lastUpdateTime;
        private bool buffersInitialized;

        // 间接绘制参数
        private uint[] args = new uint[5] { 0, 0, 0, 0, 0 };

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
            cullingKernel = cullingShader.FindKernel("FrustumCulling");
            QuadTreeManager = GetComponent<QuadTreeManager>();
            buffersInitialized = true;
        }

        void InitializeBuffers()
        {
            // 节点缓冲区（可容纳100万个节点）
            nodeBuffer = new ComputeBuffer(1000000,
                Marshal.SizeOf(typeof(NodeData)),
                ComputeBufferType.Structured);

            // 可见索引缓冲区
            visibleBuffer = new ComputeBuffer(1000000, sizeof(int),
                ComputeBufferType.Append);

            // 间接参数缓冲区
            argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint),
                ComputeBufferType.IndirectArguments);
        }

        void Update()
        {
            if (!buffersInitialized)
            {
                return;
            }

            // 按照时间间隔更新节点数据
            if (Time.time - lastUpdateTime > updateInterval)
            {
                // 更新节点缓冲区
                UpdateNodeBuffer();
                lastUpdateTime = Time.time;
            }


            DispatchGPUCulling();
            RenderTerrain();
        }

        void UpdateNodeBuffer()
        {
            QuadTreeManager treeManager = GetComponent<QuadTreeManager>();
            int nodeCount = treeManager.leafNodes.Count;
            // 动态调整缓冲区大小
            if (nodeBuffer.count < nodeCount)
            {
                nodeBuffer.Release();
                nodeBuffer = new ComputeBuffer(Mathf.Max(nodeCount * 2, 1), Marshal.SizeOf(typeof(NodeData)),
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

            nodeBuffer.SetData(nodeArray);
            cullingShader.SetInt(NodeCount, treeManager.leafNodes.Count);
        }

        void DispatchGPUCulling()
        {
            var nodeCount = QuadTreeManager.leafNodes.Count;
            if (nodeCount == 0)
            {
                return;
            }

            // 设置着色器参数
            if (Camera.main != null)
            {
                Matrix4x4 vpMatrix = Camera.main.projectionMatrix * Camera.main.worldToCameraMatrix;
                cullingShader.SetMatrix(ViewProjMatrix, vpMatrix);
                cullingShader.SetVector(CameraPos, Camera.main.transform.position);
            }

            cullingShader.SetBuffer(cullingKernel, Nodes, nodeBuffer);
            cullingShader.SetBuffer(cullingKernel, VisibleIndices, visibleBuffer);

            // 执行计算着色器
            int threadGroupsX = Mathf.CeilToInt(nodeCount / 64.0f);
            // 保证至少有一个线程组
            threadGroupsX = Mathf.Max(1, threadGroupsX);
            cullingShader.Dispatch(cullingKernel, threadGroupsX, 1, 1);
        }

        void RenderTerrain()
        {
            // 获取可见的实例数量
            argsBuffer.GetData(args);
            if (args[1] == 0)
            {
                // 没有可见实例，不绘制
                return;
            }

            // 准备绘制参数
            args[0] = terrainMesh.GetIndexCount(0);
            args[1] = (uint)visibleBuffer.count;
            argsBuffer.SetData(args);

            // 设置材质参数
            terrainMaterial.SetBuffer(Nodes, nodeBuffer);
            terrainMaterial.SetBuffer(VisibleIndices, visibleBuffer);

            // 间接绘制
            Graphics.DrawMeshInstancedIndirect(
                terrainMesh,
                0,
                terrainMaterial,
                new Bounds(Vector3.zero, QuadTreeManager.terrainSize),
                argsBuffer
            );
        }

        void OnDestroy()
        {
            nodeBuffer.Release();
            visibleBuffer.Release();
            argsBuffer.Release();
        }
    }
}