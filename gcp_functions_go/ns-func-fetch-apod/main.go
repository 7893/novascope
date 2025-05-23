// novascope/gcp_functions_go/ns-func-fetch-apod/main.go

package ns_func_fetch_apod

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"cloud.google.com/go/firestore" // Firestore 客户端
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// PubSubMessage 结构体
type PubSubMessage struct {
	Data []byte `json:"data"`
}

// ApodResponse 结构体
type ApodResponse struct {
	Date        string `json:"date"`
	Explanation string `json:"explanation"`
	Hdurl       string `json:"hdurl"`
	MediaType   string `json:"media_type"`
	Title       string `json:"title"`
	Url         string `json:"url"`
	Copyright   string `json:"copyright,omitempty"` // 有些 APOD 有版权信息
}

// FirestoreApodEntry 是我们将存储到 Firestore 的结构
type FirestoreApodEntry struct {
	Date        string    `firestore:"date"`         // YYYY-MM-DD
	Title       string    `firestore:"title"`
	Explanation string    `firestore:"explanation"`
	MediaType   string    `firestore:"mediaType"`
	ImageURL    string    `firestore:"imageUrl"`     // 指向 R2 中图片的 URL (或仅路径)
	Hdurl       string    `firestore:"hdurl"`        // 原始高清图 URL
	Url         string    `firestore:"url"`          // 原始普通图 URL
	Copyright   string    `firestore:"copyright,omitempty"`
	FetchedAt   time.Time `firestore:"fetchedAt"`    // 获取此数据的时间戳
}

var (
	gcpProjectID            string
	nasaApiKeySecretID      string
	r2AccessKeyIDSecretID   string
	r2SecretKeySecretID     string
	r2BucketName            string
	r2Endpoint              string
	cloudflareAccountID     string
	firestoreCollectionID   string // Firestore 集合 ID
)

func init() {
	gcpProjectID = os.Getenv("GCP_PROJECT_ID")
	if gcpProjectID == "" {
		gcpProjectID = "sigma-outcome"
		log.Printf("Warning: GCP_PROJECT_ID environment variable not set, using default: %s.", gcpProjectID)
	}

	nasaApiKeySecretID = os.Getenv("NASA_API_KEY_SECRET_ID")
	if nasaApiKeySecretID == "" {
		nasaApiKeySecretID = "ns-sm-nasa-api-key"
		log.Printf("Warning: NASA_API_KEY_SECRET_ID environment variable not set, using default: %s.", nasaApiKeySecretID)
	}

	r2AccessKeyIDSecretID = os.Getenv("R2_ACCESS_KEY_ID_SECRET_ID")
	if r2AccessKeyIDSecretID == "" {
		r2AccessKeyIDSecretID = "ns-sm-r2-access-key-id"
		log.Printf("Warning: R2_ACCESS_KEY_ID_SECRET_ID environment variable not set, using default: %s.", r2AccessKeyIDSecretID)
	}

	r2SecretKeySecretID = os.Getenv("R2_SECRET_KEY_SECRET_ID")
	if r2SecretKeySecretID == "" {
		r2SecretKeySecretID = "ns-sm-r2-secret-access-key"
		log.Printf("Warning: R2_SECRET_KEY_SECRET_ID environment variable not set, using default: %s.", r2SecretKeySecretID)
	}

	r2BucketName = os.Getenv("R2_BUCKET_NAME")
	if r2BucketName == "" {
		r2BucketName = "ns-r2-apod-images"
		log.Printf("Warning: R2_BUCKET_NAME environment variable not set, using default: %s.", r2BucketName)
	}

	cloudflareAccountID = os.Getenv("CLOUDFLARE_ACCOUNT_ID")
	if cloudflareAccountID == "" {
		cloudflareAccountID = "ed3e4f0448b71302675f2b436e5e8dd3"
		log.Printf("Warning: CLOUDFLARE_ACCOUNT_ID environment variable not set, using default: %s.", cloudflareAccountID)
	}
	r2Endpoint = fmt.Sprintf("https://%s.r2.cloudflarestorage.com", cloudflareAccountID)

	firestoreCollectionID = os.Getenv("FIRESTORE_COLLECTION_ID")
	if firestoreCollectionID == "" {
		firestoreCollectionID = "ns-fs-apod-metadata" // 我们在 Terraform 中计划的集合名
		log.Printf("Warning: FIRESTORE_COLLECTION_ID environment variable not set, using default: %s.", firestoreCollectionID)
	}

	log.Println("Function ns-func-fetch-apod initialized with R2 and Firestore configurations.")
}

// accessSecretVersion 函数 (保持不变)
func accessSecretVersion(ctx context.Context, name string) (string, error) {
	// ... (代码同前) ...
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		return "", fmt.Errorf("secretmanager.NewClient: %w", err)
	}
	defer client.Close()
	req := &secretmanagerpb.AccessSecretVersionRequest{Name: name}
	result, err := client.AccessSecretVersion(ctx, req)
	if err != nil {
		return "", fmt.Errorf("client.AccessSecretVersion for %s: %w", name, err)
	}
	return string(result.Payload.Data), nil
}


// FetchAndStoreAPOD 函数
func FetchAndStoreAPOD(ctx context.Context, m PubSubMessage) error {
	log.Println("NovaScope FetchAndStoreAPOD function triggered.")

	// 1. 获取 NASA API Key
	nasaApiKey, err := accessSecretVersion(ctx, fmt.Sprintf("projects/%s/secrets/%s/versions/latest", gcpProjectID, nasaApiKeySecretID))
	if err != nil {
		log.Printf("Failed to access NASA API key: %v", err)
		return fmt.Errorf("accessSecretVersion (NASA API Key): %w", err)
	}
	log.Printf("Successfully retrieved NASA API Key (first 5 chars): %s...", nasaApiKey[:5])

	// 2. 调用 NASA APOD API
	apodData, err := callNasaApodAPI(ctx, nasaApiKey)
	if err != nil {
		log.Printf("Failed to call NASA APOD API: %v", err)
		return err
	}
	if apodData.MediaType != "image" {
		log.Printf("Today's APOD is not an image (media_type: %s), skipping. Title: %s", apodData.MediaType, apodData.Title)
		return nil
	}
	log.Printf("NASA APOD Data received for date: %s, Title: %s, Image URL: %s", apodData.Date, apodData.Title, apodData.Hdurl)

	// 3. 下载图片
	imageData, imageName, contentType, err := downloadImage(ctx, apodData.Hdurl, apodData.Date)
	if err != nil {
		log.Printf("Failed to download image: %v", err)
		return err
	}
	log.Printf("Image downloaded: %s, Content-Type: %s, Size: %d bytes", imageName, contentType, len(imageData))

	// 4. 从 Secret Manager 获取 R2 凭证
	r2AccessKeyID, err := accessSecretVersion(ctx, fmt.Sprintf("projects/%s/secrets/%s/versions/latest", gcpProjectID, r2AccessKeyIDSecretID))
	if err != nil {
		log.Printf("Failed to access R2 Access Key ID: %v", err)
		return fmt.Errorf("accessSecretVersion (R2 Access Key ID): %w", err)
	}
	r2SecretKey, err := accessSecretVersion(ctx, fmt.Sprintf("projects/%s/secrets/%s/versions/latest", gcpProjectID, r2SecretKeySecretID))
	if err != nil {
		log.Printf("Failed to access R2 Secret Access Key: %v", err)
		return fmt.Errorf("accessSecretVersion (R2 Secret Key): %w", err)
	}
	log.Println("Successfully retrieved R2 credentials.")

	// 5. 将图片上传到 Cloudflare R2
	err = uploadToR2(ctx, r2AccessKeyID, r2SecretKey, r2Endpoint, r2BucketName, imageName, imageData, contentType)
	if err != nil {
		log.Printf("Failed to upload image to R2: %v", err)
		return err
	}
	log.Printf("Successfully uploaded image %s to R2 bucket %s", imageName, r2BucketName)

	// 6. 将元数据写入 Firestore
	// 构建 R2 中图片的公共访问 URL (或路径，取决于您前端如何访问)
	// Cloudflare R2 对象的公共 URL 通常是 https://<your-r2-public-bucket-url>/<objectKey>
	// 或者通过自定义域名。这里我们先存对象键（文件名）。
	r2ObjectPath := imageName // 或者 "images/" + imageName 如果您想在桶内有子目录

	firestoreEntry := FirestoreApodEntry{
		Date:        apodData.Date,
		Title:       apodData.Title,
		Explanation: apodData.Explanation,
		MediaType:   apodData.MediaType,
		ImageURL:    r2ObjectPath, // 存储 R2 中的相对路径或完整可访问 URL
		Hdurl:       apodData.Hdurl,
		Url:         apodData.Url,
		Copyright:   apodData.Copyright,
		FetchedAt:   time.Now().UTC(),
	}

	err = writeToFirestore(ctx, firestoreEntry)
	if err != nil {
		log.Printf("Failed to write metadata to Firestore: %v", err)
		return err
	}
	log.Printf("Successfully wrote metadata for date %s to Firestore.", apodData.Date)

	log.Println("FetchAndStoreAPOD function execution completed successfully.")
	return nil
}

// callNasaApodAPI 函数 (保持不变)
func callNasaApodAPI(ctx context.Context, apiKey string) (*ApodResponse, error) {
	// ... (代码同前) ...
	url := fmt.Sprintf("https://api.nasa.gov/planetary/apod?api_key=%s", apiKey)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("http.NewRequestWithContext: %w", err)
	}
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("client.Do: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("NASA API request failed with status %s: %s", resp.Status, string(bodyBytes))
	}
	var apodData ApodResponse
	if err := json.NewDecoder(resp.Body).Decode(&apodData); err != nil {
		return nil, fmt.Errorf("json.NewDecoder.Decode: %w", err)
	}
	if apodData.Hdurl == "" {
		apodData.Hdurl = apodData.Url
	}
	return &apodData, nil
}

// downloadImage 函数 (保持不变)
func downloadImage(ctx context.Context, imageURL string, date string) (imageData []byte, imageName string, contentType string, err error) {
	// ... (代码同前) ...
	if imageURL == "" {
		return nil, "", "", fmt.Errorf("imageURL is empty")
	}
	req, err := http.NewRequestWithContext(ctx, "GET", imageURL, nil)
	if err != nil {
		return nil, "", "", fmt.Errorf("downloadImage http.NewRequestWithContext: %w", err)
	}
	client := &http.Client{Timeout: 60 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, "", "", fmt.Errorf("downloadImage client.Do: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, "", "", fmt.Errorf("downloadImage request failed with status %s for URL %s", resp.Status, imageURL)
	}
	imageData, err = io.ReadAll(resp.Body)
	if err != nil {
		return nil, "", "", fmt.Errorf("downloadImage io.ReadAll: %w", err)
	}
	contentType = resp.Header.Get("Content-Type")
	urlParts := strings.Split(imageURL, "/")
	fileNameFromURL := urlParts[len(urlParts)-1]
	if queryParamIndex := strings.Index(fileNameFromURL, "?"); queryParamIndex != -1 {
		fileNameFromURL = fileNameFromURL[:queryParamIndex]
	}
	if fileNameFromURL == "" || strings.Contains(fileNameFromURL, "=") || len(fileNameFromURL) > 100 {
		ext := ".jpg"
		if strings.Contains(contentType, "jpeg") {ext = ".jpg"} else 
		if strings.Contains(contentType, "png") {ext = ".png"} else 
		if strings.Contains(contentType, "gif") {ext = ".gif"}
		imageName = fmt.Sprintf("apod-%s%s", date, ext)
	} else {
		imageName = fileNameFromURL
	}
	return imageData, imageName, contentType, nil
}

// uploadToR2 函数 (保持不变)
func uploadToR2(ctx context.Context, accessKeyID, secretKey, endpoint, bucketName, objectKey string, data []byte, contentType string) error {
	// ... (代码同前) ...
	resolver := aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
		return aws.Endpoint{
			URL:               endpoint, 
			HostnameImmutable: true,     
			Source:            aws.EndpointSourceCustom,
		}, nil
	})
	cfg, err := awsconfig.LoadDefaultConfig(ctx,
		awsconfig.WithRegion("auto"), 
		awsconfig.WithEndpointResolverWithOptions(resolver),
		awsconfig.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKeyID, secretKey, "")),
	)
	if err != nil {
		return fmt.Errorf("failed to load AWS SDK config: %w", err)
	}
	client := s3.NewFromConfig(cfg)
	_, err = client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucketName),
		Key:         aws.String(objectKey),
		Body:        bytes.NewReader(data),
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return fmt.Errorf("failed to upload object %s to bucket %s: %w", objectKey, bucketName, err)
	}
	return nil
}

// writeToFirestore 将 APOD 元数据写入 Firestore
func writeToFirestore(ctx context.Context, entry FirestoreApodEntry) error {
	client, err := firestore.NewClient(ctx, gcpProjectID)
	if err != nil {
		return fmt.Errorf("firestore.NewClient: %w", err)
	}
	defer client.Close()

	// 使用 APOD 的日期作为 Firestore 文档的 ID，可以确保幂等性
	// 如果当天的数据已存在，Set 操作会覆盖它
	docID := entry.Date
	_, err = client.Collection(firestoreCollectionID).Doc(docID).Set(ctx, entry)
	if err != nil {
		return fmt.Errorf("failed to set document %s in collection %s: %w", docID, firestoreCollectionID, err)
	}

	log.Printf("Metadata for date %s successfully written to Firestore document %s", entry.Date, docID)
	return nil
}