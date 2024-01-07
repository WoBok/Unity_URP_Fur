using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Experimental.Rendering.Universal;

//--------------------------------------------------RendererFeature----------------------------------------//
public class FurRenderer : ScriptableRendererFeature
{
    public RenderPassEvent renderPassEvent;
    public RenderQueueType renderQueueType;
    public LayerMask layerMask;
    public Material furBaseMaterial;
    public Material furRenderMaterial;
    public int furLayers;
    public float step = 0.05f;

    FurRenderPass m_FurRenderPass;
    public override void Create()
    {
        m_FurRenderPass = new FurRenderPass(renderQueueType, layerMask, furBaseMaterial, furRenderMaterial, furLayers, step);
        m_FurRenderPass.renderPassEvent = renderPassEvent;
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_FurRenderPass);
    }
}
//--------------------------------------------------RendererFeature----------------------------------------//

//--------------------------------------------------Pass----------------------------------------//
public class FurRenderPass : ScriptableRenderPass
{
    RenderQueueType m_RenderQueueType;
    Material m_FurRenderMaterial;
    Material m_FurBaseMaterial;
    int m_FurLayers;
    float m_Step;

    SortingCriteria m_SortingCriteria;
    DrawingSettings m_DrawingSettings;
    FilteringSettings m_FilteringSettings;

    public FurRenderPass(RenderQueueType renderQueueType, int layerMask, Material furBaseMaterial, Material furRenderMaterial, int furLayers, float step)
    {
        m_RenderQueueType = renderQueueType;
        m_FurBaseMaterial = furBaseMaterial;
        m_FurRenderMaterial = furRenderMaterial;
        m_FurLayers = furLayers;
        m_Step = step;

        RenderQueueRange renderQueueRange = (renderQueueType == RenderQueueType.Transparent)
        ? RenderQueueRange.transparent
        : RenderQueueRange.opaque;
        m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);
    }
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        m_SortingCriteria = (m_RenderQueueType == RenderQueueType.Transparent)
                ? SortingCriteria.CommonTransparent
                : renderingData.cameraData.defaultOpaqueSortFlags;
        m_DrawingSettings = CreateDrawingSettings(new ShaderTagId("UniversalForward"), ref renderingData, m_SortingCriteria);

        m_DrawingSettings.overrideMaterial = m_FurBaseMaterial;
        context.DrawRenderers(renderingData.cullResults, ref m_DrawingSettings, ref m_FilteringSettings);

        CommandBuffer cmd = CommandBufferPool.Get("Fur Renderer");
        cmd.Clear();
        m_DrawingSettings.overrideMaterial = m_FurRenderMaterial;
        for (int i = 0; i <= m_FurLayers; i++)
        {
            cmd.Clear();
            cmd.SetGlobalFloat("_FURSTEP", i * m_Step);
            context.ExecuteCommandBuffer(cmd);
            context.DrawRenderers(renderingData.cullResults, ref m_DrawingSettings, ref m_FilteringSettings);
        }
        CommandBufferPool.Release(cmd);
    }
}
//--------------------------------------------------Pass----------------------------------------//