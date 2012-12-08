require 'find'
require 'fileutils'
require 'RMagick'
require 'jpeg_dimensions.rb'

class Wallpaper
  attr_reader :all_pics    # Все картинки
  attr_reader :all_pics_by_folder  # Все картинки по каталогам
  attr_accessor :format_selection # Формат картинки :all, :narrow, :wide
  attr_accessor :folder_selection # Выбор по каталогу :all, :same
  attr_accessor :size_selection # Выбор по размеру
  attr_accessor :history # Список показанных
  attr_accessor :pic_align # Выравнивание картинки
  attr_accessor :work_dir # Рабочий каталог

  def initialize(work_dir)
    @screen_res = OpenStruct.new :width => 1920, :height => 1080

    @work_dir = work_dir
    @all_pics = []
    @all_pics_by_folder = {}
    @history = []
    @format_selection = :all
    @folder_selection = :all
    @pic_align = :right
  end

  def clear
    @all_pics.clear
    @all_pics_by_folder.clear
    @history.clear
  end

  # Найти все картинки в подкаталогах
  def find(pics_path)
    count = 0
    pics_path = File.expand_path pics_path
    Find.find(pics_path) do |path|
      if FileTest.file?(path) && File.extname(path).downcase == '.jpg'
        #di = JpegDimensions.new path
        #di.find_jpeg_size
        #puts "#{path}\n\t#{di.width} x #{di.height}"

        if File.size(path) > 100000
          @all_pics << path
          @all_pics_by_folder[File.dirname(path)] << path

          count += 1
        end
      elsif FileTest.directory? path
        @all_pics_by_folder[path] = []
        yield path if block_given?
      end
    end
    count
  end

  # Запустить сервис
  def run(step, current_file = nil)
    pic = nil
    case step
      when :next
        pic = select_pic
      when :prev
        pic = select_pic_prev
      when :next_in_folder, :prev_in_folder
        if current_file
          current_index = @all_pics.index(current_file)
          if current_index
            if step == :next_in_folder
              current_index += 1
            else
              current_index -= 1
            end
            pic = Magick::ImageList.new @all_pics[current_index]
          end
        end
      when :random_in_folder
        if current_file
          all = @all_pics_by_folder[current_file]
          unless !all || all.empty?
            pic = Magick::ImageList.new(all.sample)
          end
        end
    end

    if pic
      yield pic
      pic_path = process_pic pic

      #FileUtils.copy pic_path, './choice.jpg'
      #wallpaper_set_gnome(pic_path)
      wallpaper_set_xfce(pic_path)

      @history << pic.filename
    end

    GC.start
  end

  # Установка обои в Gnome
  def wallpaper_set_gnome(pic_path)
    `gconftool-2 -t str  -s /desktop/gnome/background/picture_filename "#{pic_path}"`
  end

  # Установка обои в Xfce
  def wallpaper_set_xfce(pic_path)
    prop = "/backdrop/screen0/monitor0/image-show"
    `xfconf-query -c xfce4-desktop -p #{prop} -s true`

    prop = "/backdrop/screen0/monitor0/image-path"
    `xfconf-query -c xfce4-desktop -p #{prop} -s ""`
    `xfconf-query -c xfce4-desktop -p #{prop} -s "#{pic_path}"`
  end

  # Выбрать подходящую картинку
  def select_pic
    return nil if @all_pics.empty?

    100.times do
      GC.start
      pic = Magick::ImageList.new get_random_pic
      is_good = case format_selection
        when :all
          true
        when :narrow
          pic.columns < pic.rows
        when :wide
          pic.columns >= pic.rows
      end
      return pic if is_good
    end

    Magick::ImageList.new get_random_pic
  end

  # Предыдущая картинка
  def select_pic_prev
    return nil if @history.size < 2

    @history.pop # Текущая
    Magick::ImageList.new @history.pop # Предыдущая
  end

  # Следующая случайная картинка
  def get_random_pic
    all = nil
    if folder_selection == :same && !@history.empty?
      all = @all_pics_by_folder[File.dirname(@history.last)]
    else
      all = @all_pics
    end
    all.respond_to?(:sample) ? all.sample : all.choice
  end

  # Обработать картинку
  def process_pic(pic)
    pic = pic.resize_to_fit(@screen_res.width, @screen_res.height)
    wall = Magick::Image.new(@screen_res.width, @screen_res.height) { self.background_color = "black" }

    x_align = case @pic_align
      when :right
        wall.columns - pic.columns
      when :left
        0
      when :center
        (wall.columns - pic.columns) / 2
    end

    wall.composite!(pic, x_align, 0, Magick::CopyCompositeOp)

    wall_path = @work_dir + 'wallpaper.jpg'
    wall.write(wall_path) { self.quality = 100 }
    pic_path = File.expand_path wall_path

    pic_path
  end
end
