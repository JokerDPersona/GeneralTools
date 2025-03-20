using System.ComponentModel;
using UnityEngine;

public sealed class Singleton<T> where T : class, new()
{
    private static volatile T instance;
    private static readonly object lockObject = new();

    private Singleton()
    {
    }

    public static T Instance
    {
        get
        {
            if (instance != null) return instance;
            lock (lockObject)
            {
                if (instance == null)
                {
                    instance = new T();
                }
            }

            return instance;
        }
    }
}