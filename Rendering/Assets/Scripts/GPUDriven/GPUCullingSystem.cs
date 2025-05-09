namespace QuadTree
{
    using UnityEngine;
    using System.Runtime.InteropServices;

    /// <summary>
    /// GPU剔除系统
    /// </summary>
    public class GPUCullingSystem : MonoBehaviour
    {
        private static readonly int ViewProjMatrix = Shader.PropertyToID("_ViewProjMatrix");
        private static readonly int Nodes = Shader.PropertyToID("_Nodes");
        private static readonly int VisibleIndices = Shader.PropertyToID("_VisibleIndices");
        private static readonly int NodeCount = Shader.PropertyToID("nodeCount");
        [Header("Compute Shaders")] public ComputeShader cullingShader;
        private int cullingKernel;

        [Header("Rendering")] public Mesh terrainMesh;
        public Material terrainMaterial;

        public QuadTreeManager QuadTreeManager { get; private set; }

        // 计算缓冲区
        private ComputeBuffer nodeBuffer;
        private ComputeBuffer visibleBuffer;
        private ComputeBuffer argsBuffer;

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
            UpdateNodeBuffer();
            DispatchGPUCulling();
            RenderTerrain();
        }

        void UpdateNodeBuffer()
        {
            QuadTreeManager treeManager = GetComponent<QuadTreeManager>();
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
            // 设置着色器参数
            Matrix4x4 vpMatrix = Camera.main.projectionMatrix * Camera.main.worldToCameraMatrix;
            cullingShader.SetMatrix(ViewProjMatrix, vpMatrix);
            cullingShader.SetBuffer(cullingKernel, Nodes, nodeBuffer);
            cullingShader.SetBuffer(cullingKernel, VisibleIndices, visibleBuffer);

            // 执行计算着色器
            int threadGroups = Mathf.CeilToInt(QuadTreeManager.leafNodes.Count / 64.0f);
                cullingShader.Dispatch(cullingKernel, threadGroups, 1, 1);
        }

        void RenderTerrain()
        {
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