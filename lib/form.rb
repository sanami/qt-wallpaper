Qt::require ROOT('resources/form.ui'), ROOT('tmp')
Qt::require ROOT('resources/resources.qrc'), ROOT('tmp')

class Form < Qt::MainWindow
  slots 'on_action_quit_triggered()'
  slots 'on_action_new_triggered()'
  slots 'on_change_wallpaper()'
  slots 'on_toolButton_clicked()'
  slots 'on_toolButton_2_clicked()'
  slots 'on_toolButton_3_clicked()'
  slots 'on_toolButton_4_clicked()'
  slots 'on_comboBox_currentIndexChanged(const QString &)'
  slots 'on_comboBox_2_currentIndexChanged(const QString &)'
  slots 'on_comboBox_3_currentIndexChanged(const QString &)'
  slots 'on_comboBox_4_currentIndexChanged(const QString &)'
  slots 'on_checkBox_clicked()'

  slots 'on_action_open_triggered()'
  slots 'on_action_save_triggered()'
  slots 'on_action_save_as_triggered()'

  def initialize(wall, settings)
    super()
    init_ui

    @wall = wall

    # Загрузить настройки
    @settings = settings
    load_settings

    if @settings.current_dir
      add_folder @settings.current_dir
    end
  end

protected
  # Не должен быть private
  def closeEvent(e)
    unless $debug
      if Qt::MessageBox::question(self, "Confirm Exit", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) != Qt::MessageBox::Ok
        e.ignore
        return
      end
    end

    # Сохранить настройки
    save_settings

    super
    puts "closeEvent"
    $qApp.quit
  end

private
  # Инициализация GUI
  def init_ui
    @ui = Ui::Form.new
    @ui.setupUi(self)
    Qt::optimize_layouts self

    resize(1000, 600)
    move(0, 0)
    setWindowIcon(Qt::Icon.new(':/resources/app.ico'))
    setWindowTitle 'Wallpaper'

    # Скрыть меню
    @ui.menubar.hide

    # Настроить тулбар
    @ui.groupBox.children.each do |c|
      #p c.class
      unless c.inherits "QLayoutItem"
        @ui.toolBar.addWidget c
      end

    end
    @ui.groupBox.dispose

    #connect(@action_search, SIGNAL('triggered()'), self, SLOT('on_action_search_triggered()') )
    @timer = Qt::Timer.new
    connect(@timer, SIGNAL('timeout()'), self, SLOT('on_change_wallpaper()') )
    @timer.setInterval 1000*60*5
    @timer.start
  end


  def log(str)
    @ui.textEdit.append str
  end

  def show_message(str)
    statusBar.showMessage str
  end

  def inform_pic_change(pic)
    @settings.current_file = pic.filename
    t = Time.now.strftime('%H:%M:%S')
    log "#{t} #{pic.columns} x #{pic.rows} #{pic.filesize} #{pic.filename}"
    show_message "#{t} #{pic.filename}"
  end

  # Выйти из программы
  def on_action_quit_triggered
    $qApp.quit
  end

  # Очистить список картинок
  def on_action_new_triggered
    if Qt::MessageBox::question(self, "Confirm Clear", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) == Qt::MessageBox::Ok
      @wall.clear
      @ui.treeWidget.clear
    end
  end

  # Открыть диалог добавление каталога
  def on_action_open_triggered
    @settings.current_dir ||= '.'
    dir_name = Qt::FileDialog::getExistingDirectory(self, 'Add Directory', @settings.current_dir, Qt::FileDialog::ShowDirsOnly)
    if dir_name
      add_folder dir_name
      @settings.current_dir = dir_name
    end
  end

  # Добавить картинки из нового каталога
  def add_folder(dir_name)
    pics_count = @wall.find(dir_name) do |dir|
      Qt::TreeWidgetItem.new @ui.treeWidget, [dir]
    end
    show_message "Found #{pics_count} pics"
  end

  # Запустить смену картинку
  def on_change_wallpaper
    @wall.run :next do |pic|
      inform_pic_change pic
    end
  end

  # Сменить и перезапустить таймер
  def on_toolButton_clicked
    @timer.stop # Остановить, иначе может сработать во время работы и рестарт не поможет
    on_change_wallpaper
    @timer.start
  end

  # Сменить и перезапустить таймер
  def on_toolButton_2_clicked
    @timer.stop # Остановить, иначе может сработать во время работы и рестарт не поможет
    @wall.run :prev do |pic|
      inform_pic_change pic
    end
    @timer.start
  end

  # Остановить таймер
  def on_toolButton_3_clicked
    @timer.stop
  end

  # Открыть файл
  def on_toolButton_4_clicked
    if @settings.current_file
      Qt::DesktopServices::openUrl(Qt::Url.new("file://#{@settings.current_file}"));
    end
  end

  # Изменить время обновления
  def on_comboBox_currentIndexChanged(text)
    time = text.to_i*1000*60
    @timer.setInterval time
  end

  # Изменить параметр выбора картинки
  def on_comboBox_2_currentIndexChanged(text)
    @wall.folder_selection = text.to_sym
  end

  # Изменить параметр выбора картинки
  def on_comboBox_3_currentIndexChanged(text)
    @wall.format_selection = text.to_sym
  end

  # Изменить параметр выравнивания картинки
  def on_comboBox_4_currentIndexChanged(text)
    @wall.pic_align = text.to_sym
  end

  # Минимизировать
  def on_checkBox_clicked
    if @ui.checkBox.checked?
      @ui.toolBar.setParent nil
      @ui.toolBar.setWindowFlags Qt::Window
      @ui.toolBar.show
      hide
    else
      addToolBar @ui.toolBar
      show
    end
  end

  # Загрузка и применение настроек
  def load_settings
    if @settings.form_geometry
      self.restoreGeometry Qt::ByteArray.new(@settings.form_geometry.to_s)
    end

    if @settings.timer_interval
      @ui.comboBox.setCurrentIndex @settings.timer_interval
    end
  end

  # Сохранение настроек
  def save_settings
    @settings.form_geometry = self.saveGeometry.to_s
    @settings.timer_interval = @ui.comboBox.currentIndex
  end

end
