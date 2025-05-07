using System;
using UnityEngine;
using Object = UnityEngine.Object;

public class MonoSingleton<T> : MonoBehaviour where T : MonoBehaviour
{
    // 使用 volatile 关键字确保多线程环境下 instance 的可见性
    private static volatile T instance;
    private static readonly object lockObject = new object();

    // 公共静态属性，用于获取单例实例
    public static T Instance
    {
        get
        {
            if (instance == null)
            {
                lock (lockObject)
                {
                    if (instance != null) return instance;
                    // 在场景中查找是否已经存在该类型的实例
                    instance = FindAnyObjectByType<T>();

                    // 如果场景中不存在，则创建一个新的 GameObject 并附加该组件
                    if (instance != null) return instance;
                    var singletonObject = new GameObject(typeof(T).Name);
                    instance = singletonObject.AddComponent<T>();
                }
            }

            return instance;
        }
    }

    // 可选的 Awake 方法，用于初始化
    protected virtual void Awake()
    {
        if (instance == null)
        {
            instance = this as T;
            DontDestroyOnLoad(gameObject); // 使单例在场景切换时不被销毁
        }
        else
        {
            // 如果已经存在实例，则销毁当前对象
            Destroy(gameObject);
        }
    }
}