using UnityEngine;

public class GpuDriven : MonoBehaviour
{
    public ComputeShader computeShader;
    public Material material;
    private int kernelIndex { get; set; }

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
        computeShader.Dispatch(kernelIndex, 256 / 8, 256 / 8, 1);
    }
}