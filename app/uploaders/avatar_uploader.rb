# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
     %w(jpg jpeg png gif)
  end

  def rotate_according_to_exif
    manipulate! do |img|
      img.tap(&:auto_orient)
    end
  end

  process :rotate_according_to_exif
  process :resize_to_limit => [250, 250]

  version :mini do
    process :rotate_according_to_exif
    process :resize_to_fill => [75, 75]
  end

  #convert the base64
  #class FilelessIO < StringIO
  #  attr_accessor :original_filename
  #  attr_accessor :content_type
  #end

  #before :cache, :convert_base64

  #def convert_base64(file)
  #  if file.respond_to?(:original_filename) &&
  #      file.original_filename.match(/^base64:/)
  #    fname = file.original_filename.gsub(/^base64:/, '')
  #    ctype = file.content_type
  #    decoded = Base64.decode64(file.read)
  #    file.file.tempfile.close!
  #    decoded = FilelessIO.new(decoded)
  #    decoded.original_filename = fname
  #    decoded.content_type = ctype
  #    file.__send__ :file=, decoded
  #  end
  #  file
  #end
  #end of convert base64

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [1200, 1200]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
