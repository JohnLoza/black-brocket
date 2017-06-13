class WebVideo < ActiveRecord::Base
  validates :video, presence: true

  mount_uploader :video, VideoUploader

  # Get the user image if there is one, else return default image #
  def getVideo()
    video = ""
    if !self.video.blank?
      video = self.photo.url
    else
      video = "video.mp4"
    end # if !self.photo.blank? #
  end # def getImage(type = nil) #
end
