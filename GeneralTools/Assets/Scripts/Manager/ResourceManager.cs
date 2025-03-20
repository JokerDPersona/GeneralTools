using System;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;

public class ResourceManager : MonoSingleton<ResourceManager>
{
    private Dictionary<string, AsyncOperationHandle> loadedResources = new();

    /// <summary>
    /// 同步加载资源
    /// </summary>
    /// <param name="address"></param>
    /// <typeparam name="T"></typeparam>
    /// <returns></returns>
    public T LoadAssetSync<T>(string address)
    {
        if (loadedResources.TryGetValue(address, out var handle))
        {
            if (handle.IsDone)
            {
                return (T)handle.Result;
            }
        }

        try
        {
            handle = Addressables.LoadAssetAsync<T>(address);
            //会阻塞当前线程
            handle.WaitForCompletion();
            if (handle.Status == AsyncOperationStatus.Succeeded)
            {
                loadedResources[address] = handle;
                return (T)handle.Result;
            }
        }
        catch (Exception ex)
        {
            Debug.LogError($"Failed to load asset at address: {address},ex->{ex}");
            throw;
        }

        return default;
    }

    /// <summary>
    /// 异步加载资源
    /// </summary>
    /// <param name="address"></param>
    /// <typeparam name="T"></typeparam>
    /// <returns></returns>
    public async UniTask<T> LoadAssetAsync<T>(string address)
    {
        if (loadedResources.TryGetValue(address, out AsyncOperationHandle handle))
        {
            if (handle.IsDone)
            {
                return (T)handle.Result;
            }

            await handle.ToUniTask(); // 等待异步操作完成
            return (T)handle.Result;
        }

        try
        {
            handle = Addressables.LoadAssetAsync<T>(address);
            loadedResources[address] = handle;
            await handle.ToUniTask();
            if (handle.Status == AsyncOperationStatus.Succeeded)
            {
                return (T)handle.Result;
            }
        }
        catch (Exception ex)
        {
            Debug.LogError($"Failed to load asset at address: {address},ex->{ex}");
            throw;
        }

        return default;
    }

    /// <summary>
    /// 异步加载资源并设置超时时间
    /// </summary>
    /// <param name="address"></param>
    /// <param name="timeSpan"></param>
    /// <typeparam name="T"></typeparam>
    /// <returns></returns>
    public async UniTask<T> LoadAssetAsyncWithTimeout<T>(string address, TimeSpan timeSpan)
    {
        try
        {
            return await LoadAssetAsync<T>(address).Timeout(timeSpan);
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex);
            return default;
        }
    }

    /// <summary>
    /// 卸载指定地址的资源
    /// </summary>
    /// <param name="address"></param>
    /// <typeparam name="T"></typeparam>
    public void UnloadAsset<T>(string address)
    {
        if (loadedResources.TryGetValue(address, out AsyncOperationHandle handle))
        {
            if (handle.IsDone)
            {
                handle.Release();
                loadedResources.Remove(address);
            }
        }
    }

    /// <summary>
    /// 卸载指定地址的资源
    /// </summary>
    /// <param name="address"></param>
    public void UnloadAsset(string address)
    {
        if (loadedResources.TryGetValue(address, out AsyncOperationHandle handle))
        {
            if (handle.IsDone)
            {
                handle.Release();
                loadedResources.Remove(address);
            }
        }
    }

    /// <summary>
    /// 卸载所有已加载的资源
    /// </summary>
    public void UnloadAllAssets()
    {
        foreach (var kvp in loadedResources)
        {
            Addressables.Release(kvp.Value);
        }

        loadedResources.Clear();
        Debug.Log("All assets unloaded.");
    }
}