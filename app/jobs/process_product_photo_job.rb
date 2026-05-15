class ProcessProductPhotoJob < ApplicationJob
  queue_as :default
  self.log_arguments = false

  def perform(product_id, file_content, filename, content_type)
    product = Product.find_by(id: product_id)
    return unless product && R2_CLIENT

    ext = File.extname(filename)
    key = "#{product.company_id}/products/#{product_id}/#{SecureRandom.uuid}#{ext}"

    R2_CLIENT.put_object(
      bucket:       R2_BUCKET,
      key:          key,
      body:         file_content,
      content_type: content_type
    )

    product.update_column(:photo_url, "#{R2_PUBLIC_URL}/#{key}")
    Rails.cache.delete_matched("products:#{product.company_id}*")
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "[R2] Error subiendo foto del producto #{product_id}: #{e.message}"
    raise
  end
end
