require '../spec_helper'
require 'jpeg_dimensions.rb'

describe JpegDimensions do
  it "should work with URL" do
    j = JpegDimensions.new('http://www.google.fi/intl/en_com/images/srpr/logo1w.png')
    j.height.should be > 0
    j.width.should be > 0
  end

  it "should work with file" do
    Dir[TEST_DIR+'/*.jpg'].each do |file|
      #pp file
      j = JpegDimensions.new(file)
      pp j
      j.height.should be > 0
      j.width.should be > 0
    end
  end
end
