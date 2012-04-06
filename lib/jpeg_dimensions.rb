require 'net/http'

class JpegDimensions
	attr_reader :width, :height
	attr_reader :local

	def initialize(image_path)
		begin
			@uri_split = URI.split(image_path)
			raise :bad_url unless @uri_split[2]
		rescue => ex
			@local = image_path
		end

		find_jpeg_size
	end

	def get_data(&checker)
		if @local
			dat = IO.read(@local, 1024*4)
			yield dat
		else
			# Remote resource
			http = Net::HTTP.new(@uri_split[2], @uri_split[3])
			http.get(@uri_split[5], &checker)
		end
	end

	def find_jpeg_size
		get_data do |str| # this yields strings as each packet arrives
			state = 0
			str.each_byte do |b|
				state = case state
					when 0
						b == 0xFF ? 1 : 0
					when 1
						b >= 0xC0 && b <= 0xC3 ? 2 : 0
					when 2
						3
					when 3
						4
					when 4
						5
					when 5
						@height = b * 256
						6
					when 6
						@height += b
						7
					when 7
						@width = b * 256
						8
					when 8
						@width += b
						break
				end
			end
			break if state == 8 # don't need to fetch any more of the image
		end

		#TODO Method.to_proc

#		checker = lambda do |str| # this yields strings as each packet arrives
#		#checker = ->(str) do # this yields strings as each packet arrives
#			state = 0
#			str.each_byte do |b|
#				state = case state
#					when 0
#						b == 0xFF ? 1 : 0
#					when 1
#						b >= 0xC0 && b <= 0xC3 ? 2 : 0
#					when 2
#						3
#					when 3
#						4
#					when 4
#						5
#					when 5
#						@height = b * 256
#						6
#					when 6
#						@height += b
#						7
#					when 7
#						@width = b * 256
#						8
#					when 8
#						@width += b
#						break
#				end
#			end
#			return if state == 8 # don't need to fetch any more of the image
#		end

#		if @local
#			dat = IO.binread(@local, 1024*4)
#			checker[dat]
#		else
#			# Remote resource
#			http = Net::HTTP.new(@uri_split[2], @uri_split[3])
#			http.get(@uri_split[5], &checker)
#		end
	rescue Exception => ex
		@height = @width = nil
	end
end
