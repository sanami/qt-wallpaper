require '../spec_helper'
require 'wallpaper.rb'

describe Wallpaper do
	subject do
		Wallpaper.new(ROOT('/tmp'))
	end

	describe 'with test' do
		before(:each) do
			subject.find TEST_DIR
		end

		it 'should find' do
			subject.all_pics.should_not be_empty
		end

		it 'should clear' do
			subject.clear
			subject.all_pics.should be_empty
		end

		it 'should select pic' do
			subject.select_pic.should_not be_nil
		end

		it 'should return random' do
			subject.get_random_pic.should_not be_nil
		end
	end
end
