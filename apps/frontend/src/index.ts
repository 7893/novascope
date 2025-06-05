// ~/novascope/apps/frontend/src/index.ts

// 定义环境变量/Secrets的期望类型 (可选但推荐)
export interface Env {
  NASA_MEDIA_BUCKET: R2Bucket; // R2 存储桶绑定
  NS_GCP_API_URL: string;      // Secret
  NS_GCP_SHARED_SECRET: string; // Secret
  NS_R2_BUCKET_NAME: string;   // 环境变量
}

export default {
  async fetch(
    request: Request,
    env: Env, // 使用我们定义的 Env 类型
    ctx: ExecutionContext
  ): Promise<Response> {

    const gcpApiUrl = env.NS_GCP_API_URL;
    const gcpSharedSecret = env.NS_GCP_SHARED_SECRET;
    const r2BucketName = env.NS_R2_BUCKET_NAME;
    const r2BindingExists = env.NASA_MEDIA_BUCKET ? 'Bound (object present)' : 'Not bound or undefined';

    const responseBody = {
      message: "NovaScope Worker (TypeScript) Secrets/Variables Check:",
      NS_GCP_API_URL: gcpApiUrl || "NOT SET OR NOT ACCESSIBLE",
      NS_GCP_SHARED_SECRET: gcpSharedSecret ? "[SECRET SET - Value Hidden for Security Demo]" : "NOT SET OR NOT ACCESSIBLE",
      NS_R2_BUCKET_NAME: r2BucketName || "NOT SET OR NOT ACCESSIBLE",
      NASA_MEDIA_BUCKET_BINDING: r2BindingExists,
    };

    // 为了演示，我们只显示共享密钥是否存在，而不是它的值
    // 在真实应用中，绝不要直接在 HTTP 响应中返回敏感密钥值
    if (gcpSharedSecret) {
      console.log("NS_GCP_SHARED_SECRET is set.");
    } else {
      console.log("NS_GCP_SHARED_SECRET is NOT set.");
    }

    return new Response(JSON.stringify(responseBody, null, 2), {
      headers: { 'Content-Type': 'application/json' },
    });
  },
};