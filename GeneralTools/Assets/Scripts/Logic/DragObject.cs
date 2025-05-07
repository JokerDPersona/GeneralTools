using System;
using Manager;
using UnityEngine;
using UnityEngine.InputSystem;

public class DragObject : MonoBehaviour
{
    private Camera mainCamera;
    private bool isDragging;
    private GameObject selectedObject;
    private Vector3 offset;

    private InputAction clickDownAction;
    private InputAction pointAction;
    private InputAction clickUpAction;

    private void Awake()
    {
        mainCamera = Camera.main;
        var inputActionAsset = ResourceManager.Instance.LoadAssetSync<InputActionAsset>("InputSystem_Actions");
        clickDownAction = inputActionAsset.FindAction("ClickDown");
        pointAction = inputActionAsset.FindAction("Point");
        clickUpAction = inputActionAsset.FindAction("ClickUp");
    }

    private void OnEnable()
    {
        clickDownAction.Enable();
        pointAction.Enable();

        clickDownAction.performed += OnClickDownPreformed;
        clickUpAction.performed += OnClickCanceled;
    }

    private void OnDisable()
    {
        clickDownAction.Disable();
        pointAction.Disable();
        
        clickDownAction.performed -= OnClickDownPreformed;
        pointAction.performed -= OnClickCanceled;
    }

    private void OnClickDownPreformed(InputAction.CallbackContext context)
    {
        // 获取鼠标位置
        var mousePos = pointAction.ReadValue<Vector2>();

        // 从摄像机发射射线
        var ray = mainCamera.ScreenPointToRay(mousePos);
        if (Physics.Raycast(ray, out RaycastHit hit))
        {
            // 选中物体
            selectedObject = hit.collider.gameObject;
            isDragging = true;

            // 计算物体与鼠标点击点的偏移量
            var screenPoint = mainCamera.WorldToScreenPoint(selectedObject.transform.position);
            var mouseWorldPos = mainCamera.ScreenToWorldPoint(new Vector3(mousePos.x, mousePos.y, screenPoint.z));
            offset = selectedObject.transform.position - mouseWorldPos;
        }
    }

    private void OnClickCanceled(InputAction.CallbackContext context)
    {
        if (isDragging)
        {
            isDragging = false;
            selectedObject = null;
        }
    }

    private void Update()
    {
        if (isDragging)
        {
            // 获取当前鼠标位置
            var mousePos = pointAction.ReadValue<Vector2>();

            // 将鼠标位置转换为世界坐标
            var screenPoint = mainCamera.WorldToScreenPoint(selectedObject.transform.position);
            var mouseWorldPos = mainCamera.ScreenToWorldPoint(new Vector3(mousePos.x, mousePos.y, screenPoint.z));

            // 更新选中物体的位置
            selectedObject.transform.position = mouseWorldPos;
        }
    }
}