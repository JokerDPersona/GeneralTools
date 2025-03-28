using UnityEngine;

public static class ViewPortCullingManager
{
    /// <summary>
    /// 一个点和一个法向量确定一个平面
    /// </summary>
    /// <param name="normal">平面法线</param>
    /// <param name="point">平面任意一点</param>
    /// <returns>一个平面</returns>
    public static Vector4 GetPlane(Vector3 normal, Vector3 point)
    {
        return new Vector4(normal.x, normal.y, normal.z, -Vector3.Dot(normal, point));
    }

    /// <summary>
    /// 三点确定一个平面
    /// </summary>
    /// <param name="a"></param>
    /// <param name="b"></param>
    /// <param name="c"></param>
    /// <returns>一个平面</returns>
    public static Vector4 GetPlane(Vector3 a, Vector3 b, Vector3 c)
    {
        var normal = Vector3.Normalize(Vector3.Cross(b - a, c - a));
        return GetPlane(normal, a);
    }

    /// <summary>
    /// 获取视锥体远平面的四个点
    /// </summary>
    /// <param name="camera"></param>
    /// <returns></returns>
    public static Vector3[] GetCameraFarClipPlanePoint(Camera camera)
    {
        var points = new Vector3[4];
        var cameraTransform = camera.transform;
        var cameraDistance = camera.farClipPlane;
        var halfFovRad = Mathf.Deg2Rad * camera.farClipPlane * 0.5f;
        var upLen = cameraDistance * Mathf.Tan(halfFovRad);
        var rightLen = upLen * camera.aspect;
        var farCenterPoint = cameraTransform.position + cameraDistance * cameraTransform.forward;
        var up = upLen * cameraTransform.up;
        var right = rightLen * cameraTransform.right;
        points[0] = farCenterPoint - up - right; //left bottom
        points[1] = farCenterPoint - up + right; //right bottom
        points[2] = farCenterPoint + up - right; //left top
        points[3] = farCenterPoint + up + right; //right top
        return points;
    }

    /// <summary>
    /// 获取视锥体的六个面
    /// </summary>
    /// <param name="camera"></param>
    /// <returns></returns>
    public static Vector4[] GetFrustumPlane(Camera camera)
    {
        //摄像机六个面
        var plants = new Vector4[6];
        var cameraTransform = camera.transform;
        var cameraPosition = cameraTransform.position;
        var points = GetCameraFarClipPlanePoint(camera);
        //顺时针
        plants[0] = GetPlane(cameraPosition, points[0], points[2]); //left
        plants[1] = GetPlane(cameraPosition, points[3], points[1]); //right
        plants[2] = GetPlane(cameraPosition, points[1], points[0]); //bottom
        plants[3] = GetPlane(cameraPosition, points[2], points[3]); //top
        plants[4] = GetPlane(-cameraTransform.forward,
            cameraTransform.position + cameraTransform.forward * camera.nearClipPlane); //near
        plants[5] = GetPlane(cameraTransform.forward,
            cameraTransform.position + cameraTransform.forward * camera.farClipPlane); //far
        return plants;
    }
}