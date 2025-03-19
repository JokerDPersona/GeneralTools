using System;
using UnityEngine;

public class ParticleEffect : MonoBehaviour
{
    public ComputeShader computeShader;
    public Material material;
    private int kernelIndex { get; set; }
    private int kernelId { get; set; }
    private const int particleCount = 20000;
    private ComputeBuffer particleBuffer;

    public struct ParticleData
    {
        public Vector3 pos;
        public Color color;
    }

    private void Awake()
    {
        RenderTexture renderTexture = new(256, 256, 0);
        kernelIndex = computeShader.FindKernel("CSMain");
        renderTexture.enableRandomWrite = true;
        renderTexture.Create();
        material.mainTexture = renderTexture;
        computeShader.SetTexture(kernelIndex, "Result", renderTexture);
    }

    private void Start()
    {
        particleBuffer = new(particleCount, 28);
        ParticleData[] particleDatas = new ParticleData[particleCount];
        particleBuffer.SetData(particleDatas);
        kernelId = computeShader.FindKernel("UpdateParticle");
        computeShader.Dispatch(kernelIndex, 256 / 8, 256 / 8, 1);
    }

    private void Update()
    {
        computeShader.SetBuffer(kernelId, "ParticleBuffer", particleBuffer);
        computeShader.SetFloat("Time", Time.time);
        computeShader.Dispatch(kernelId, particleCount / 1000, 1, 1);
        material.SetBuffer("particleBuffer", particleBuffer);
    }

    private void OnRenderObject()
    {
        material.SetPass(0);
        Graphics.DrawProceduralNow(MeshTopology.Points, particleCount);
    }

    private void OnDestroy()
    {
        particleBuffer.Release();
        particleBuffer = null;
    }
}