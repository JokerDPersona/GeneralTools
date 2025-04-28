using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

namespace QuadTree
{
    public class GPUCullingSystem : MonoBehaviour
    {
        private static readonly int ViewProjMatrix = Shader.PropertyToID("_ViewProjMatrix");
        private static readonly int Nodes = Shader.PropertyToID("Nodes");
        private static readonly int VisibleInstances = Shader.PropertyToID("VisibleInstances");
        private static readonly int NodeBuffer = Shader.PropertyToID("_NodeBuffer");
        private static readonly int VisibleBuffer = Shader.PropertyToID("_VisibleBuffer");
        private static readonly int NodeCount = Shader.PropertyToID("_NodeCount");
        public ComputeShader CullingShader { get; private set; }
        public Camera MainCamera { get; private set; }

        /// <summary>
        /// 节点数据
        /// </summary>
        private ComputeBuffer _nodeBuffer;

        /// <summary>
        /// 可见结果
        /// </summary>
        private ComputeBuffer _visibleBuffer;

        /// <summary>
        /// 间接绘制参数
        /// </summary>
        private ComputeBuffer _argsBuffer;

        private QuadTreeManager _quadTreeManager;
        private List<QuadTreeNode> _allNodes = new();
        [SerializeField] private Mesh terrainMesh;
        [SerializeField] private Material terrainMaterial;

        [StructLayout(LayoutKind.Sequential, Pack = 1)]
        struct NodeData
        {
            public Vector3 Center { get; set; }
            public float LodLevel { get; set; }
            public Vector3 Size { get; set; }
        }

        private void Start()
        {
            _quadTreeManager = GetComponent<QuadTreeManager>();
            InitializeBuffers();
        }

        void InitializeBuffers()
        {
            var nodeSize = System.Runtime.InteropServices.Marshal.SizeOf(typeof(NodeData));
            _nodeBuffer = new ComputeBuffer(1024 * 1024, nodeSize);
            _visibleBuffer = new ComputeBuffer(1024 * 1024, sizeof(uint), ComputeBufferType.Append);
            _argsBuffer = new ComputeBuffer(1024 * 1024, sizeof(uint), ComputeBufferType.IndirectArguments);
        }

        private void Update()
        {
            // 1.更新四叉树结构
            _quadTreeManager.UpdateQuadTree();
            // 2.收集所有需要检测的节点
            _allNodes.Clear();
            CollectRenderAbleNodes(_quadTreeManager.Root);
            // 3.准备GPU数据
            UpdateNodeBuffer();
            // 4.执行GPU剔除
            ExecuteGPUCulling();
            // 5.执行间接绘制
            RenderInstances();
        }

        private void RenderInstances()
        {
            // 获取可见实例数量
            ComputeBuffer.CopyCount(_visibleBuffer, _argsBuffer, 0);

            // 准备实例数据
            MaterialPropertyBlock props = new MaterialPropertyBlock();
            props.SetBuffer(NodeBuffer, _nodeBuffer);
            props.SetBuffer(VisibleBuffer, _visibleBuffer);

            // 间接绘制
            Graphics.DrawMeshInstancedIndirect(terrainMesh,
                0,
                terrainMaterial,
                new Bounds(Vector3.zero, Vector3.one * 10000),
                _argsBuffer,
                0,
                props);
        }

        private void ExecuteGPUCulling()
        {
            // 重制可见缓冲区
            _visibleBuffer.SetCounterValue(0);

            // 设置Shader参数
            Matrix4x4 viewProj = MainCamera.projectionMatrix * MainCamera.worldToCameraMatrix;
            CullingShader.SetMatrix(ViewProjMatrix, viewProj);
            CullingShader.SetBuffer(0, Nodes, _nodeBuffer);
            CullingShader.SetBuffer(0, VisibleInstances, _visibleBuffer);
            CullingShader.SetFloat(NodeCount, _nodeBuffer.count);

            // 分配线程
            var threadGroups = Mathf.CeilToInt(_allNodes.Count / 64f);
            CullingShader.Dispatch(0, threadGroups, 1, 1);
        }

        private void UpdateNodeBuffer()
        {
            NodeData[] nodeArray = new NodeData[_allNodes.Count];
            for (int i = 0; i < _allNodes.Count; i++)
            {
                var node = nodeArray[i] = new NodeData();
                node.Center = _allNodes[i].Bounds.center;
                node.Size = _allNodes[i].Bounds.size;
                node.LodLevel = node.LodLevel;
            }

            _nodeBuffer.SetData(nodeArray);
        }

        private void CollectRenderAbleNodes(QuadTreeNode node)
        {
            if (node.HasChildren)
            {
                foreach (var child in node.Children)
                {
                    CollectRenderAbleNodes(child);
                }
            }
            else
            {
                _allNodes.Add(node);
            }
        }
    }
}