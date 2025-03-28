using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

public class ViewPortCulling : MonoBehaviour
{
    [SerializeField] public int instanceCount = 100000;
    [SerializeField] public Mesh instanceMesh;
    [SerializeField] public Material instanceMaterial;
    [SerializeField] public int subMeshIndex;
    [SerializeField] public ComputeShader compute;

    private int _cacheInstanceCount = -1;
    private int _cacheSubMeshIndex = -1;
    private ComputeBuffer _argsBuffer;
    private ComputeBuffer _localToWorldMatrixBuffer;
    private uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
    private ComputeBuffer _callResult;
    private readonly List<Matrix4x4> _localToWorldMatrices = new();
    private int _kernel;
    private Camera _mainCamera;

    void Start()
    {
        _kernel = compute.FindKernel("ViewPortCulling");
        _mainCamera = Camera.main;
        _callResult = new ComputeBuffer(instanceCount, sizeof(float) * 16, ComputeBufferType.Append);
        _argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        UpdateBuffers();
    }

    private void UpdateBuffers()
    {
        if (instanceMaterial != null)
            subMeshIndex = Mathf.Clamp(subMeshIndex, 0, instanceMesh.subMeshCount - 1);

        _localToWorldMatrixBuffer?.Release();

        _localToWorldMatrixBuffer = new ComputeBuffer(instanceCount, 16 * sizeof(float));
        for (var i = 0; i < instanceCount; i++)
        {
            var angle = Random.Range(0.0f, Mathf.PI * 2.0f);
            var distance = Random.Range(20f, 100f);
            var height = Random.Range(-2.0f, 2.0f);
            var size = Random.Range(0.05f, 0.25f);
            var position = new Vector4(Mathf.Sin(angle) * distance, height, Mathf.Cos(angle) * distance, size);
            _localToWorldMatrices.Add(Matrix4x4.TRS(position, Quaternion.identity, new Vector3(size, size, size)));
        }

        _localToWorldMatrixBuffer.SetData(_localToWorldMatrices);

        if (instanceMesh != null)
        {
            args[0] = instanceMesh.GetIndexCount(subMeshIndex);
            args[2] = instanceMesh.GetIndexStart(subMeshIndex);
            args[3] = instanceMesh.GetBaseVertex(subMeshIndex);
        }
        else
        {
            args[0] = args[1] = args[2] = args[3] = 0;
        }

        _argsBuffer.SetData(args);

        _cacheInstanceCount = instanceCount;
        _cacheSubMeshIndex = subMeshIndex;
    }

    void Update()
    {
        if (instanceCount != _cacheInstanceCount || subMeshIndex != _cacheSubMeshIndex)
        {
            UpdateBuffers();
        }

        var planes = ViewPortCullingManager.GetFrustumPlane(_mainCamera);
        compute.SetBuffer(_kernel, "input", _localToWorldMatrixBuffer);
        _callResult.SetCounterValue(0);
        compute.SetBuffer(_kernel, "cullResult", _callResult);
        compute.SetInt("instanceCount", instanceCount);
        compute.SetVectorArray("planes", planes);
        compute.Dispatch(_kernel, 1 + (instanceCount / 640), 1, 1);
        instanceMaterial.SetBuffer("positionBuffer", _callResult);

        ComputeBuffer.CopyCount(_callResult, _argsBuffer, sizeof(uint));

        Graphics.DrawMeshInstancedIndirect(instanceMesh, subMeshIndex, instanceMaterial,
            new Bounds(Vector3.zero, new Vector3(200.0f, 200.0f, 200.0f)), _argsBuffer);
    }

    private void OnDisable()
    {
        _localToWorldMatrixBuffer?.Release();
        _localToWorldMatrixBuffer = null;

        _callResult?.Release();
        _callResult = null;

        _argsBuffer?.Release();
        _argsBuffer = null;
    }
}